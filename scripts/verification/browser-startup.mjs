import { chromium } from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';

// Run against flutter run or a server hosting the complete build/web directory.
// No backend or test accounts are required to verify the first screen.
const url = process.argv[2] ?? 'http://localhost:8085';
const out = path.resolve(import.meta.dirname, '../../.verification');
await fs.mkdir(out, { recursive: true });
const browser = await chromium.launch({ channel: 'chrome', headless: true });
try {
  const context = await browser.newContext({ viewport: { width: 400, height: 858 } });
  const cdnRequests = [];
  const localWasm = [];
  const errors = [];
  await context.route('https://www.gstatic.com/flutter-canvaskit/**', route => {
    cdnRequests.push(route.request().url());
    return route.abort('failed');
  });
  const page = await context.newPage();
  page.on('pageerror', error => errors.push(error.message));
  page.on('response', response => {
    const address = new URL(response.url());
    if (address.origin === new URL(url).origin &&
        address.pathname.includes('/canvaskit/') && address.pathname.endsWith('.wasm')) {
      localWasm.push({ url: response.url(), status: response.status() });
    }
  });
  await page.goto(url);
  await page.locator('flt-semantics-placeholder').waitFor({ state: 'attached', timeout: 90000 });
  await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
  await page.getByRole('button', { name: 'Start', exact: true }).waitFor({ timeout: 30000 });
  // Semantics can be ready before Flutter paints its fonts and first animation.
  await page.waitForTimeout(3000);
  await page.screenshot({ path: path.join(out, 'chrome-local-canvaskit.png') });
  await page.getByRole('button', { name: 'Start', exact: true }).click();
  await page.getByRole('button', { name: 'Sign in', exact: true }).waitFor({ timeout: 15000 });
  assert.equal(cdnRequests.length, 0, 'Startup must not request CanvasKit from Google');
  assert.ok(localWasm.some(response => response.status === 200), 'Local CanvasKit must load');
  assert.deepEqual(errors, [], 'Startup must have no uncaught browser errors');
  console.log(JSON.stringify({ result: 'PASS', url, localWasm, cdnRequests,
    screens: ['Start', 'Sign in'], errors }, null, 2));
} finally {
  await browser.close();
}
