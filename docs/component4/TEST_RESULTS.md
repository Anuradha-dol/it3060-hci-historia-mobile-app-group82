# Executed verification — 8 October 2026

## Environment

Windows 11; Java 17.0.16; Flutter 3.47.6 / Dart 3.13.5; installed Chrome 154. Maven wrapper resolved Spring Boot 4.1.1 without changing framework versions. No configured permanent PostgreSQL database or application-local.yml was available. Tests use isolated real PostgreSQL 14.22 through `io.zonky.test:embedded-postgres:2.2.2`, not an in-memory substitute.

## Commands and results

| Actual command | Result |
|---|---|
| `flutter --version`, `flutter doctor -v`, `flutter devices` | Flutter/Dart satisfy declared SDK. Chrome, Edge and Windows detected. Android SDK path contains spaces; no Android device. |
| `flutter pub get` | Passed. Added geolocator and resolved compatible transitive packages. |
| `.\mvnw.cmd -B -ntp test` in backend | **13 tests passed, zero failures/errors/skips**. Includes app startup against PostgreSQL, HTTP/JWT access checks and transactional concurrency. |
| `H:\flutter\bin\flutter.bat analyze` in frontend | **No issues found.** |
| `H:\flutter\bin\flutter.bat test --reporter expanded` | **7 tests passed.** Includes two widget flows at 360 and 430 logical pixels. |
| `H:\flutter\bin\flutter.bat build web --dart-define=API_BASE_URL=http://localhost:8081 --no-wasm-dry-run` | Passed. Real Flutter web output in `frontend/build/web`. |
| `node scripts/verification/browser-demo.mjs` | **Passed** in installed Chrome against the disposable backend: traveler booking/demo checkout, separate guide session, location fixture, offline PIN reconciliation, completion and reload recovery. See `screenshots/browser-results.json` and limitations below. |

Evidence: `backend/target/surefire-reports/com.historia.backend.booking.BookingIntegrationTest.txt`, backend `target/booking-test-run.log`, checked-in test sources and `docs/component4/screenshots/`. Target/build directories are local generated artifacts, not source deliverables.

## Backend behaviors tested

1. Server pricing (3 × 2,500 = 7,500), count limits, past slots, consistent start/end and checkout amount.
2. Duplicate request-key idempotency and rejection of a changed retry payload.
3. Two genuinely concurrent PostgreSQL transactions requesting different overlapping start times; exactly one reservation succeeds.
4. Expired hold becomes unavailable for payment and frees the interval for another traveler.
5. Unrelated reads/PIN requests and traveler location publishing rejected; only traveler may pay, only guide may advance service state.
6. Demo failure, cancellation, success, retry and explicit production-mode disablement.
7. Guide status/location/ETA update, mandatory handshake before IN_PROGRESS, single-use PIN, completion and rejected terminal publishing.
8. Five-attempt PIN lockout and expiry.
9. Combined discovery filters, unknown rating/certification behavior, disabled-guide eligibility.
10. HTTP requires JWT, outsider receives 404 without PIN exposure, participant receives own reservation.
11. Internal trusted-payment boundary rejects wrong amount/currency and handles repeated verified callbacks.
12. Management role restrictions and immutable price/package/duration snapshots after rate edits.
13. Existing profile, approved-guide, historical-place, tour-list and buddy-conversation read routes remain usable; GUIDE still receives 403 on tourist-only buddy route.

## Flutter behaviors tested

- Package/capacity/subtotal state, retained selections and schedule payload.
- Double-tap guard, stable idempotency key across a failed request/retry.
- Out-of-order availability responses cannot replace the latest selected date's slots.
- Per-user secure cache separation, restoration, pending offline-code removal and clear operation.
- Stale location suppresses countdown; local PIN expiry; Sri Lanka time formatting.
- Customize → meeting → review → back at 360px and 430px; no layout exceptions, retained values, correct total.

Tests exposed and fixed step-to-step scroll position reuse. The tests now wait for actual scrolling before tapping; this is different from bypassing the UI handlers.

## Browser and visual evidence

Screenshots were captured from real Flutter widgets with real backend guide/package/booking data at 390 × 844 pixels:

- `01-find-guide.png`
- `02-customize-visit.png`
- `03-meeting-location.png`
- `04-review-pay.png`
- `05-guide-tracker.png`
- `06-offline-tracker.png`

All five supplied design images were visually reviewed against implementation screenshots. Layout/palette/card hierarchy/map/countdown/PIN composition are retained. Differences: readable larger text/touch targets, an added date selector/filter controls, explicit per-visitor prices and demo labels, simplified schematic, real random references/PINs, and more vertical scrolling. At 390px the meeting confirmation or tracker Message action can require scrolling; controls remain reachable. The directory's second guide is partly below the initial fold. The map is explicitly labeled schematic. No phone-frame/status-bar decorations or reference screenshots are used as app UI.

Browser setup uses two isolated contexts for traveler/guide login. Geolocation is an explicitly injected browser fixture, so the check verifies permission/transport/UI updates rather than physical GPS accuracy. Offline means both browser contexts are switched offline; no live location is fabricated. The server is a disposable local real PostgreSQL/Spring application; checkout is explicitly demo-only and collects no money.

## Encountered tooling failures and resolution

- Initial sandboxed Maven wrapper: `Cannot index into a null array. Cannot start maven from wrapper`. System Maven also returned `Permission denied: getsockopt` while resolving the parent. Running the wrapper with normal cache/network access succeeded. No version downgrade.
- Initial Maven baseline reported “No tests to run”; this is not counted as a behavioral pass. Tests were added afterward.
- Initial application test startup exposed missing `${spring.mail.username}`. Email now produces an explicit feature-specific configuration error; startup with blank SMTP/Google configuration passes.
- PostgreSQL microsecond timestamp storage exposed a nanosecond equality mismatch in a test. The ETA fixture was changed to millisecond precision; persistence was not bypassed.
- Native Flutter test hook initially failed with `'G:\@Basic' is not recognized` because of the SDK path space. Temporary `subst H: 'G:\@Basic Soft'` enabled native tests without moving/reinstalling the SDK.
- First web SDK download failed with a locked downloaded ZIP; a subsequent `flutter precache --web` completed.
- `flutter test --platform chrome` stalled while loading; it is **not counted as passed**. The specific stalled runner was stopped. Native Flutter tests and direct Playwright Chrome app tests provide the stated evidence.
- Browser automation needed keyboard events for Flutter text fields, explicit scrolling for offscreen controls, and waits for async server completion/list loading. Intermediate script failures are not treated as successful full runs.

## Checks not performed / remaining limits

### Follow-up: Chrome blank-screen fix

The user's debug session failed to download Google's CanvasKit WASM with `ERR_QUIC_PROTOCOL_ERROR`. Added `frontend/web/flutter_bootstrap.js` to resolve CanvasKit from the app's own base URL. Ran `node scripts/verification/browser-startup.mjs` against the running Flutter debug server at `http://localhost:8085`: **passed**, Start and Sign in screens visible, local `/canvaskit/chromium/canvaskit.wasm` returned 200, zero CanvasKit CDN requests and zero uncaught browser errors. The verification explicitly blocks Google's CanvasKit URL. Screenshot: local generated `.verification/chrome-local-canvaskit.png`. This follow-up check covers the debug server; the earlier release-build results above predate this bootstrap change.

### Remaining limits

- No Android debug build or Android/iOS/Windows device run; Android prerequisites are incomplete and disk space was checked before deciding against downloads.
- No physical GPS field accuracy, real phone call, real SMS sending, or real gateway settlement/refund.
- No authorized SMTP/Google credentials: ordinary registration OTP, password recovery delivery, Google login, and a real guide-registration/admin-approval workflow remain unverified. Their source paths were preserved; demo accounts do not prove these external integrations.
- Existing historical **read** routes and buddy role isolation were smoke-tested. Full multi-place itinerary creation, guide profile-edit/approval UI, and two-traveler STOMP chat were not exercised end to end. Do not interpret read-route smoke checks as full regression coverage.
- No guarantee of a cold web launch with all network connectivity absent; browser asset/service-worker availability depends on prior caching. Secure booking-cache recovery and an already-open offline tracker were tested. Native cold-offline launch awaits device testing.
- Real rating/certification supply and payment gateway/refund adapters remain teammate/admin integrations, documented in `API_AND_PAYMENT_CONTRACT.md`.
