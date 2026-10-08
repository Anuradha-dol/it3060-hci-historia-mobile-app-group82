# Manual setup — Component 4

Checked on 8 October 2026. This is an extracted project, not a project-level Git checkout. Do not run Git cleanup commands: Git currently finds an unrelated repository in the Windows user directory.

Project root:

```text
C:\Users\ASUS TUF\Desktop\it3060-hci-historia-mobile-app-group82-develop\it3060-hci-historia-mobile-app-group82-develop
```

Open a **PowerShell** terminal in this folder. Paths below are relative to this root unless shown otherwise.

## Observed status

- Installed: Flutter 3.47.6 / Dart 3.13.5, Java 17.0.16, Maven 3.9.13, Chrome, Edge, Windows development tools.
- Maven wrapper 3.9.16 resolves the declared Spring Boot 4.1.1 online. No framework downgrade was necessary.
- No PostgreSQL service, `psql` on PATH, server on port 5432, or `application-local.yml` found. Docker CLI exists, but Docker's engine is not running.
- No permanent application database, JWT secret, SMTP sender, Google configuration or demo accounts have been configured by this work.
- The verification database is temporary PostgreSQL 14.22 created by a **test-only** dependency. It is independent of `historia` and is deleted when stopped.
- Free disk space at inspection: C: approximately 7.6 GB, G: 88.6 GB, F: 82.3 GB. No Android toolchain/emulator was downloaded.
- Android doctor reports an SDK path containing spaces; no Android device is connected.

## Required for a persistent local backend

| Manual task | Why | Exact location | Command / setting | Blocks | Verify |
|---|---|---|---|---|---|
| Install PostgreSQL if still absent | Persistent database | Official Windows installer: https://www.postgresql.org/download/windows/ | Install Server and Command Line Tools; pgAdmin is optional. Select port **5432**, locale default, username **postgres**, and choose your own password. Prefer a data directory on a drive with space. Skip Stack Builder extras. | Normal backend startup | Start menu → Services → PostgreSQL service is Running; use the psql command below. |
| Create `historia` | App needs a database | Start menu → SQL Shell (psql), or PostgreSQL installation `bin` directory | Connect to localhost, database `postgres`, port 5432, user postgres. Enter your chosen password. Run `CREATE DATABASE historia;` **only if absent**. | Normal backend startup | `\l historia` shows the database. |
| Configure local DB credentials | Password is unknown to the app | `backend/src/main/resources/application-local.yml` | Copy the provided example only if the local file is absent; set `spring.datasource.password` to your chosen password. Preserve an existing file. | Database connection | Backend starts without authentication/connection errors. |
| Generate a JWT signing secret | Signed access/refresh tokens | Same local YAML, `jwt.secret` | Generate 64 random bytes with the PowerShell commands below, then paste the resulting Base64 value locally. Never send it in chat. | Login/token creation | Login returns a session and an authenticated booking request succeeds. |
| Create local test accounts | Booking requires both roles | Backend demo profile + environment variable in the terminal running it | Set a password of your own, then explicitly enable `demo`, seed and demo-payments using RUN_AND_DEMO.md. | Two-role persistent demo | Log in as `demo_traveler` and `demo_kamal` in separate browser profiles. |

Create the local configuration safely:

```powershell
if (!(Test-Path -LiteralPath 'backend/src/main/resources/application-local.yml')) {
  Copy-Item -LiteralPath 'backend/src/main/resources/application-local.example.yml' -Destination 'backend/src/main/resources/application-local.yml'
}
notepad backend/src/main/resources/application-local.yml
```

Generate your JWT secret locally:

```powershell
$jwtBytes = New-Object byte[] 64
$jwtGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$jwtGenerator.GetBytes($jwtBytes)
$jwtGenerator.Dispose()
[Convert]::ToBase64String($jwtBytes)
```

Replace `REPLACE_WITH_RANDOM_BASE64_SECRET` with that output. Keep quotes around YAML passwords containing punctuation. Do not put real secrets in the example file.

If using PostgreSQL 18 in its default installation directory, the shell command is:

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -h localhost -p 5432 -U postgres -d postgres
```

Use the installed version number if different. In psql:

```sql
SELECT datname FROM pg_database WHERE datname = 'historia';
-- Run the next line only if the query returned no rows.
CREATE DATABASE historia;
\l historia
\q
```

## Feature-specific and optional setup

| Manual task | Why | Exact location | Command / setting | Blocks | Verify |
|---|---|---|---|---|---|
| Authorized SMTP credentials | Real signup, email verification and password recovery send OTPs | `application-local.yml` → `spring.mail.username/password`; sender account security settings | Use your authorized SMTP account. Existing defaults are smtp.gmail.com:587 with STARTTLS. For Gmail, enable 2-Step Verification and create an app password if the account allows it; set sender address and app password locally. Other providers also need host/port settings. | OTP delivery, ordinary signup/recovery verification; **not startup** | Register with an email you control and receive the OTP; do not use the demo seed as proof of SMTP working. |
| First admin credentials | Normal guide-approval workflow | Same YAML → `admin.username/email/password` and optional phone | Choose your own credentials. Initializer creates an admin only if none exists; it does not reset an existing admin password. | Manual approval smoke test | Admin can sign in and review a newly registered guide. |
| Google Web OAuth | Google sign-in | Google Cloud Console → APIs & Services → Credentials; local YAML `google.oauth.client-id`; Flutter `GOOGLE_WEB_CLIENT_ID` | Create/use an authorized Web OAuth client; add the exact local origin, e.g. `http://localhost:8085`. Use the same client ID in backend and Flutter. Existing frontend default client ID belongs to the supplied source; it is **not proof of your setup**. | Google sign-in only | Use a permitted Google test user. Email/password remains available without this. |
| Guide/traveler contact numbers | Call and SMS handoff need real authorized contacts | App → Profile → Edit profile | Enter a number you control; use only authorized numbers for tests. Demo seed intentionally has no fake dialable numbers. | Successful call/SMS launch | On supported device, Call/SMS opens the correct participant; desktop provides a copy-number fallback. |
| Location permission | Foreground arrival sharing / optional straight-line distance | Chrome site settings → Location; app tracker controls | Guide first sets En route, then explicitly enables sharing. Allow location. Browser requires localhost or HTTPS. | Live GPS only | Traveler sees updated timestamp; denial leaves meeting details usable. |
| SDK path workaround | Native asset hook fails on `G:\@Basic Soft\flutter` | PowerShell, temporary H: alias | If H: is unused: `subst H: 'G:\@Basic Soft'`, then use `H:\flutter\bin\flutter.bat`. This maps existing files and does not copy/install Flutter. See commands below. | Flutter tests on this machine | `H:\flutter\bin\flutter.bat test` passes. |
| Android storage/SDK | Initial setup was interrupted; SDK path contains spaces | Android Studio → Settings → Languages & Frameworks → Android SDK | After freeing space, choose a path without spaces, e.g. `G:\Android\Sdk`, install required SDK components, run `flutter config --android-sdk G:\Android\Sdk` and `flutter doctor --android-licenses`. Prefer a USB physical device to avoid emulator image storage. | Android build/device verification only | `flutter doctor -v`, `flutter devices`, then `flutter build apk --debug`. Not performed here. |
| Physical-phone networking | Emulator address does not work on a physical phone | Windows network/firewall and Flutter run command | Same trusted Wi-Fi; find laptop IPv4 with `ipconfig`, pass `--dart-define=API_BASE_URL=http://YOUR_LAPTOP_IPV4:8081`. Allow Java/8081 on Private networks only when needed. Use HTTPS for deployed apps. | Physical-phone API calls only | Phone can reach backend and sign in. No firewall rule was changed here. |
| Real payment integration | Member IT23687646 owns gateway and reviews | `docs/component4/API_AND_PAYMENT_CONTRACT.md` | Implement a trusted gateway adapter calling the internal verification boundary. Configure authorized gateway credentials outside source control. | Real money and automated refunds | Gateway sandbox callback verifies amount/currency/reference; client success alone cannot confirm. |

Temporary Flutter alias (already used successfully for verification; it may disappear after reboot):

```powershell
subst
# Only if H: is not already listed or used:
subst H: 'G:\@Basic Soft'
cd frontend
H:\flutter\bin\flutter.bat pub get
H:\flutter\bin\flutter.bat analyze
H:\flutter\bin\flutter.bat test
H:\flutter\bin\flutter.bat run -d chrome --web-port=8085 --dart-define=API_BASE_URL=http://localhost:8081
```

Do not remove H: while Flutter tools are running. Later, from a different drive, `subst H: /D` removes just the alias. A permanent alternative is relocating Flutter to a path without spaces and updating PATH/VS Code SDK settings; do this when no Flutter processes are running.

The first web SDK download hit a locked download file; retrying `flutter precache --web` succeeded. There is no need to disable antivirus or downgrade Flutter. Maven's first sandboxed run also failed with a cache/network permission error; the normal network-enabled wrapper succeeded.

Sources for installation/test infrastructure: [PostgreSQL Windows installer](https://www.postgresql.org/download/windows/), [embedded PostgreSQL test library](https://github.com/zonkyio/embedded-postgres).
