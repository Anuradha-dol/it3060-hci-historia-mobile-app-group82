# Run and demonstrate HISTORIA Component 4

Use PowerShell from the project root. Read `MANUAL_SETUP.md` first for observed setup and exact configuration steps.

## Quick disposable demo — no permanent PostgreSQL configuration

This runs a real temporary PostgreSQL database using test dependencies, creates clearly labeled fixtures, and binds the backend to 127.0.0.1:8081. It does not configure `historia`, SMTP, Google or your permanent JWT secret. Data is discarded on shutdown. Avoid using real personal data in this mode.

Terminal 1, project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-Component4Demo.ps1
```

Wait for “Disposable demo ready”. The script may download test dependencies on first use. The process stops after 30 minutes; to stop sooner use a second terminal:

```powershell
New-Item -ItemType File -Force backend/target/stop-demo
```

Read the generated **temporary demo** password locally in Terminal 2 (do not post it in chat):

```powershell
(Get-Content backend/target/demo-session.json -Raw | ConvertFrom-Json).password
```

Demo usernames are `demo_traveler`, `demo_kamal`, `demo_sunil`. All use that temporary password. No admin or real phone number is seeded. For admin/OTP smoke tests, use the persistent setup and your own credentials.

Terminal 2, project root, launch Chrome:

```powershell
# If H: is not already mapped and is unused:
subst H: 'G:\@Basic Soft'
cd frontend
H:\flutter\bin\flutter.bat pub get
H:\flutter\bin\flutter.bat run -d chrome --web-port=8085 --dart-define=API_BASE_URL=http://localhost:8081
```

If your Flutter SDK is later moved to a path without spaces, normal `flutter` commands work instead. Do not run `flutter create` over this app. The temporary drive alias is a workaround for this machine's native build-hook quoting error.

### Blank Chrome page / CanvasKit download error

If the Console reports `ERR_QUIC_PROTOCOL_ERROR` for `www.gstatic.com/flutter-canvaskit/.../canvaskit.wasm`, the graphics engine download failed before Flutter could draw the screen. `frontend/web/flutter_bootstrap.js` now loads CanvasKit from the local Flutter server (and from bundled files in a web build).

Stop the frontend command with `q` or Ctrl+C, then run the same Chrome command above again. Use Ctrl+Shift+R in Chrome to reload without the cached bootstrap. Keep the backend terminal running for sign-in and bookings. If using the static Python server, rebuild with `flutter build web --dart-define=API_BASE_URL=http://localhost:8081` first; serve the complete `frontend/build/web` folder, including `canvaskit/`.

## Persistent database demo

Complete PostgreSQL/database/local YAML/JWT setup in `MANUAL_SETUP.md`. In a terminal in `backend`, choose your own 12+ character demo password locally:

```powershell
$demoSecure = Read-Host 'Choose a local demo password (12+ characters)' -AsSecureString
$env:HISTORIA_DEMO_PASSWORD = [System.Net.NetworkCredential]::new('', $demoSecure).Password
.\mvnw.cmd spring-boot:run '-Dspring-boot.run.profiles=demo' '-Dspring-boot.run.arguments=--historia.booking.seed=true --historia.booking.demo-payments=true'
```

An existing fixture account's password is not reset on restart. Keep the original password or use the ordinary configured recovery flow. Re-run seed to extend future schedules as days pass. Outside this explicit mode, start normally:

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

Normal mode does not seed accounts or permit demo payment. Live payment remains dependent on member 3's gateway integration.

## Two-role walkthrough

1. Use a regular Chrome window for `demo_traveler` and an Incognito window (or separate Chrome profile) for `demo_kamal`. Two tabs in the same profile share authentication storage and are **not** separate sessions. Use the same host/port in both windows.
2. Traveler: Start → Sign in → Profile → Find guides. Try English/Tamil, specialty, certification, rating, service-area and date filters. Clear filters to see demo guides. Demo labels are intentional.
3. Select Kamal → Full Heritage Walk → a future available time → increase visitors to 3. The subtotal is LKR 7,500. If today is late, choose tomorrow. For immediate tracking, choose a start within the next 2 hours; guide management can add a suitable future window.
4. Continue → select Clock Tower Gate / Sun Bastion / Moon Bastion → test zoom and meeting text → Confirm Meeting Point. Server creates a 10-minute hold. Back edits release the hold while preserving valid selections.
5. Review checks package, assigned guide, time, visitors, map and server total. Pay Now → Development checkout. FAILURE leaves the hold retryable; CANCEL releases it; SUCCESS marks DEMO_PAID/CONFIRMED. No real payment is collected.
6. Guide: Home → Guide bookings & availability → Open the matching reference. Supporting package/rate/capacity and availability controls are available from the bookings page.
7. Within the service window, guide selects Set en route, sets ETA minutes, and enables foreground sharing. Approve Chrome location if you want actual browser/device coordinates. Traveler updates within 10 seconds; updates older than 30 seconds show stale. Do not treat desktop/browser geolocation as verified field accuracy.
8. Guide sets Arrived. Both participants compare the booking-specific PIN. Guide enters it → Confirm meeting code. Wrong attempts are limited to five; successful online verification is single-use. Start visit → Complete visit. Publishing stops and active location/PIN are hidden on terminal state.
9. Offline test while tracker is loaded: Chrome DevTools → Network → Offline. Cached meeting map/details/PIN remain visible, polling reports offline and does not invent fixes. Guide can compare the cached code provisionally; restore Online to reconcile it. A provisional match cannot start the visit until server confirmation.
10. Restart/reload while online, sign in if required, then Profile → Find guides → booking icon → My guide bookings. Open the same reference. Native cold offline startup and physical GPS remain device checks.
11. Calling/SMS: supply authorized phone numbers in both profiles first. Call opens `tel:`; Message opens `sms:` with the booking context. Desktop without a handler copies the number and explains the fallback. This is not in-app buddy messaging.

## Verification commands

```powershell
cd backend
.\mvnw.cmd -B -ntp test
cd ../frontend
H:\flutter\bin\flutter.bat analyze
H:\flutter\bin\flutter.bat test --reporter expanded
H:\flutter\bin\flutter.bat build web --dart-define=API_BASE_URL=http://localhost:8081
```

Browser evidence uses Playwright with **installed Chrome**, not a downloaded emulator/browser. To run the checked-in verification script, start the disposable backend, build Flutter web, serve it on 127.0.0.1:8085, then:

```powershell
# Root terminal serving the built app:
python -m http.server 8085 --bind 127.0.0.1 --directory frontend/build/web
# Separate root terminal:
cd scripts/verification
npm ci --ignore-scripts
cd ../..
node scripts/verification/browser-demo.mjs
```

This script intentionally operates only with credentials from the disposable `backend/target/demo-session.json`. It may cancel earlier demonstration holds/bookings for its seeded guide to reset its test flow. It injects a browser geolocation fixture for transport testing; it does not test physical GPS accuracy. Screenshots are written to `docs/component4/screenshots/`.
