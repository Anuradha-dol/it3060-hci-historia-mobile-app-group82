import {chromium} from '../scripts/verification/node_modules/playwright/index.mjs';
const b=await chromium.launch({channel:'chrome',headless:true});
try {
const p=await b.newPage({viewport:{width:400,height:858}});
p.on('request',r=>{if(!r.url().startsWith('http://localhost:8085')) console.log('EXTERNAL',r.url())});
p.on('requestfailed',r=>console.log('FAILED',r.url(),r.failure()));
p.on('response',r=>{if(/font|ttf|woff/.test(r.url())) console.log(r.status(),r.url())});
await p.goto('http://localhost:8085');
await p.waitForTimeout(20000);
await p.screenshot({path:'.verification/startup-font-check.png'});
} finally { await b.close(); }
