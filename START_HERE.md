# HISTORIA — component 4 setup and implementation pack

Prepared for IT23667778 — Siriwardhana H L from the supplied develop ZIP and Milestone 02 proposal. This is a reviewed setup/reference/prompt pack, not an already implemented application.

## What you are building

HISTORIA helps travelers discover historical places, plan walking tours, interact with community posts, find travel buddies, and book local guides. Your component is **Tour Guider Booking, Scheduling, Meeting Logistics & Live Guide Tracking**.

| Requirement | Your responsibility |
|---|---|
| FR13 | Discover approved guides; filter by specialty, language, certification and availability; select a guide. |
| FR14 | Choose package, date/time and party size; calculate a consistent total and create a booking. |
| FR15 | Choose a landmark meeting point, provide offline walking information, hand off to checkout, show guide arrival updates, and support a cached meeting PIN. |

Your five principal traveler screens are Find a guide → Customize visit → Meeting Location → Review & pay → Guide is on the way. The payment step belongs between review and confirmed tracking. Payment processing and review/rating submission belong to member IT23687646. Your work must integrate with them without taking over their component. Guide-side scheduling and status/location controls are necessary supporting additions to make the traveler screens functional.

## What the supplied code actually contains

| Area | Observed state |
|---|---|
| Mobile app | Flutter/Dart; Provider; Dio; secure storage; shared green HISTORIA theme and assets. |
| Backend | Spring Boot 4.1.1 declared in pom.xml; Java 17; JPA; PostgreSQL; JWT. |
| Authentication and profiles | Existing source for registration, email OTP, login/recovery, roles, guide profiles and admin approval. |
| Discovery/community/tours | Existing historical places, community posts and multi-place tour-planning source. |
| Buddy chat | Existing STOMP/SockJS functionality; authorization currently accepts TOURIST only. |
| Guide discovery | Existing service-area search for approved guides; not the proposal's full booking directory. |
| Guide navigation | TouristHomeScreen passes an empty onTouristGuides callback, preventing the profile's fallback navigation. |
| Component 4 | No booking/package/availability/meeting/tracking implementation found in the supplied snapshot. |
| Payment | No payment implementation found in the supplied snapshot. A clear integration boundary and local demo adapter are needed unless a teammate has since added it. |
| Tests | No frontend/test or backend/src/test directories in this snapshot. |

These are source-review findings. The app was not built or launched in this review environment: Flutter, Android tooling and PostgreSQL were unavailable. Dependency resolution and runtime behavior remain to be verified on your laptop. Do not treat the existing source as proven working merely because it is present.

## 1. Open the correct folder

Extract the original code ZIP. In VS Code, open the directory containing both backend and frontend (not the parent Downloads folder). The extracted name is usually it3060-hci-historia-mobile-app-group82-develop.

Extract this pack separately, then copy its **docs** folder into that project root. This adds only reference material. It does not replace the backend or frontend.

The resulting paths must include:
- backend/pom.xml
- frontend/pubspec.yaml
- docs/component4/proposal.pdf
- docs/component4/CODEX_PROMPT.md
- docs/component4/reference/01-find-guide.png through 05-guide-tracker.png

The root README mentions an older feature/user-management checkout. Do not follow that checkout instruction for this task; preserve the supplied develop snapshot. If using the team's live Git checkout instead, start from their agreed integration branch and create feature/component-4-guide-booking. A downloaded ZIP usually has no Git history; keep a backup and coordinate with the team before pushing changes.

## 2. Install the prerequisites on Windows

- VS Code and Git for Windows.
- Flutter SDK with a bundled Dart version satisfying **>=3.12.2 and <4.0.0**, as required by pubspec.yaml. Installing the VS Code extension alone does not install every build prerequisite.
- VS Code Flutter and Dart extensions.
- JDK 17 for the backend; set JAVA_HOME accordingly and verify the terminal sees it.
- PostgreSQL, optionally with pgAdmin.
- Android Studio with Android SDK, platform/build tools, command-line tools and an emulator. You can still write code in VS Code.
- Optional: VS Code Extension Pack for Java for backend navigation/debugging.

Use the official setup guides:
- https://docs.flutter.dev/install/with-vs-code
- https://docs.flutter.dev/platform-integration/android/setup

Check in a fresh PowerShell terminal:

```powershell
git --version
java -version
flutter --version
dart --version
flutter doctor -v
flutter doctor --android-licenses
flutter devices
```

Review and accept the Android SDK licenses as appropriate. Resolve Android toolchain errors reported by flutter doctor. You do not need the Visual Studio C++ desktop workload merely to target Android.

The frontend declares Android Gradle Plugin 9.0.1, Gradle 9.1.0 and Kotlin 2.3.20. Do not randomly downgrade them. If the local toolchain reports a compatibility error, let Codex inspect that exact error against the installed Flutter/Android tooling. Android Studio may use its own bundled JDK for Android builds; the backend Java target and Android build runtime are separate concerns.

## 3. Create the local database

In pgAdmin, connect to your local PostgreSQL server and create a database named historia. Alternatively, if psql is on PATH:

```powershell
psql -U postgres
```

Then run inside psql:

```sql
CREATE DATABASE historia;
\q
```

Do not recreate it if it already exists. Keep PostgreSQL running. The configured default port is 5432.

## 4. Add the backend's private configuration

Create backend/src/main/resources/application-local.yml. It is already ignored by Git and imported by application.yml. A generic root .env is not the documented configuration mechanism for this project.

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/historia
    username: postgres
    password: "YOUR_LOCAL_POSTGRES_PASSWORD"
  mail:
    username: "YOUR_CONFIGURED_GMAIL_ADDRESS"
    password: "YOUR_GMAIL_APP_PASSWORD"

google:
  oauth:
    client-id: "YOUR_TEAM_GOOGLE_WEB_CLIENT_ID"

jwt:
  secret: "YOUR_GENERATED_BASE64_SECRET"

admin:
  username: admin
  email: "admin@historia.com"
  phone: "0700000000"
  password: "YOUR_CHOSEN_LOCAL_ADMIN_PASSWORD"
```

Replace placeholders; do not commit this file. Generate a JWT secret in PowerShell:

```powershell
$historiaBytes = New-Object byte[] 64
$historiaRng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$historiaRng.GetBytes($historiaBytes)
[Convert]::ToBase64String($historiaBytes)
$historiaRng.Dispose()
```

Copy the generated output into jwt.secret.

The current GoogleTokenService rejects an empty OAuth client ID during startup even when you intend to use email/password login. The team's Web client ID already appears as the default in frontend/lib/config/google_auth_config.dart; confirm it with the team and use the matching value in this backend configuration. An OAuth client ID is not the client secret. Google sign-in on a new Android laptop/emulator may also require registering its debug SHA-1 with the team; email/password login does not require you to finish that Google sign-in setup.

The current EmailServiceImpl requires spring.mail.username, and functioning OTP registration/recovery needs working SMTP credentials. Use the team's authorized development configuration or your own test sender. Do not replace normal authentication with an invisible bypass. The Codex brief permits a separately enabled development seed path for evaluation.

AdminInitializer creates an initial admin when none exists and the admin configuration is supplied. It does not reset the password of an existing admin whenever you edit this file.

## 5. Start the backend

Open terminal 1 in the project root:

```powershell
cd backend
.\mvnw.cmd -v
.\mvnw.cmd clean compile
.\mvnw.cmd spring-boot:run
```

Maven is included through the wrapper; no separate Maven installation is required. The first run needs internet to retrieve Maven/dependencies. Leave this terminal running. Look for successful Spring startup on port **8081**. Hibernate's existing ddl-auto: update creates/updates tables in the configured database.

Check this existing public endpoint from another terminal:

```powershell
Invoke-RestMethod "http://localhost:8081/api/guides/approved?area=Galle%20Fort"
```

An empty array is valid on a fresh database. There is no advertised /api/health endpoint in this snapshot; do not use a made-up health URL as the success test. A 401 at an unrelated protected URL also does not mean the server failed to start.

## 6. Start the mobile frontend

Start an Android emulator through Android Studio's Device Manager. Open terminal 2 in the project root:

```powershell
cd frontend
flutter pub get
flutter devices
flutter run -d YOUR_ANDROID_DEVICE_ID
```

Replace YOUR_ANDROID_DEVICE_ID with the ID printed by flutter devices; if only the intended device is connected, flutter run is sufficient. Keep both backend and Flutter terminals open. `r` in Flutter's terminal hot reloads supported changes; changes to platform configuration can need a restart/rebuild.

Current ApiConfig behavior:

| Target | API base URL | Action |
|---|---|---|
| Android emulator | http://10.0.2.2:8081 | Already the default for non-web. |
| Browser on the laptop | http://localhost:8081 | Already selected for web; web compatibility/CORS still need verification. |
| Real Android phone | http://YOUR_LAPTOP_LAN_IP:8081 | Requires a configuration change; same Wi-Fi and a narrowly scoped firewall allowance. |

Android documents 10.0.2.2 as the emulator's route to the host loopback interface: https://developer.android.com/studio/run/emulator-networking-address

Use the Android emulator for the initial mobile evaluation. If using a physical phone before Codex changes the configuration, update only the appropriate return value inside frontend/lib/config/api_config.dart, preserving resolveImageUrl. The full prompt asks Codex to add an API_BASE_URL dart-define override. **That override does not exist yet** in the supplied code. After it is implemented, use:

```powershell
flutter run -d YOUR_PHONE_ID --dart-define=API_BASE_URL=http://YOUR_LAPTOP_LAN_IP:8081
```

If a debug run specifically reports Android cleartext HTTP denial, configure local HTTP access narrowly for development; do not globally weaken the production network policy.

## 7. Get test accounts and baseline evidence

Use an existing authorized test account, or register a traveler and verify the email OTP. Register a guide, then use the initial admin account to approve the guide application. A new database will not automatically contain Kamal Perera, Sunil Fernando or available booking slots. Their sample records and component 4 data are part of the requested explicit demo seed mode.

Before implementation, check login and basic home/profile navigation. Expect the existing profile Find guides action to be broken until its empty callback is fixed. Component 4's full flow does not exist yet; running the original ZIP does not create it.

## 8. Give Codex the implementation task

Open the existing repository in VS Code's Codex extension and paste this launcher prompt:

```text
Read docs/component4/CODEX_PROMPT.md completely and execute it in this repository. First inspect docs/component4/proposal.pdf and visually inspect all five images under docs/component4/reference/. Implement IT23667778 Siriwardhana H L's complete component 4 using the existing Flutter + Spring Boot + PostgreSQL architecture. Preserve the proposal's UI and the other members' features. Continue through backend/frontend implementation, integration, tests and a two-role demo; do not stop after planning. Clearly report any external dependency you cannot verify.
```

Alternatively, paste the entire contents of docs/component4/CODEX_PROMPT.md. This file contains the full requirements and acceptance criteria; the short launcher is not a substitute if the file is missing.

## 9. Evaluate the result

Use two sessions/accounts and verify:
1. Find/filter an approved guide, including language and availability.
2. Choose a future date, available slot and package; three visitors at the demo LKR 2,500 per-person rate total LKR 7,500.
3. Select a landmark; map marker, directions, guide and time stay consistent.
4. Review the same details; double-click/retry does not duplicate reservations.
5. Test checkout success, failure and cancellation; demo checkout is visibly identified.
6. A second traveler cannot reserve an overlapping interval with the same guide.
7. Guide changes to en route and supplies location/status; traveler sees an authorized update with freshness information.
8. Turn off connectivity after caching: map, meeting instructions and booking PIN remain accessible; tracker visibly indicates stale/offline data.
9. Reconnect and reconcile the handshake; restart the app and reopen the active booking.
10. Call/Message have functioning platform-appropriate actions, unrelated users cannot access the booking, and existing buddy chat and tour planning still work.

Ask Codex to show actual test results and screenshot comparisons. A matching screen with hardcoded data is not completion of this component.

## Prototype decisions to be aware of

The proposal uses conflicting prices (`/hr` in directory versus a per-visitor subtotal), inconsistent sample times (10:30 AM versus 09:45 AM), and “Self guided” on a guide-assistance package. The prompt preserves layout while documenting consistent implementation assumptions. Live ETA, distance, ratings, passcode and references must come from data, not copied screenshot constants. The four-digit cached meeting code is a practical offline handshake; it is not by itself strong identity verification.

The five reference PNGs retain their original embedded resolution. They are useful for matching layout and style, but they do not provide editable Figma tokens or source vector artwork. Final visual fidelity needs an actual device/screenshot comparison.
