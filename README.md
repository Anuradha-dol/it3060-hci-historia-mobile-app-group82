# HISTORIA

HISTORIA is the IT3060 HCI group project. It is a mobile app for exploring historical places, finding local guides, and managing guide approvals.

The repository has two main parts:

- `backend` - Spring Boot API with PostgreSQL, JWT authentication, email OTPs, Google login, guide registration, and admin guide review.
- `frontend` - Flutter mobile app that talks to the backend API.

These notes are written for someone setting up the project on a clean laptop.

## What To Install First

Install these before opening the project:

- Git
- Java JDK 17
- PostgreSQL
- Flutter SDK with Dart 3.12.2 or newer
- Android Studio with Android SDK and an emulator
- A Gmail account with an app password, for email OTPs
- A Google Cloud OAuth Web client ID, for Google sign-in

After installing Flutter, run this once and fix anything it reports:

```powershell
flutter doctor
```

For the backend, Maven does not need to be installed separately because the project includes the Maven wrapper.

## Clone The Project

```powershell
git clone https://github.com/Anuradha-dol/it3060-hci-historia-mobile-app-group82.git
cd it3060-hci-historia-mobile-app-group82
```

If you are working on the user management branch:

```powershell
git checkout feature/user-management
```

## Set Up PostgreSQL

Start PostgreSQL, then create a database named `historia`.

```powershell
psql -U postgres
```

Inside the PostgreSQL shell:

```sql
CREATE DATABASE historia;
\q
```

The backend connects to:

```text
jdbc:postgresql://localhost:5432/historia
```

If your PostgreSQL username is not `postgres`, put your username in the local backend config shown below.

## Backend Local Config

Create this file on your own machine:

```text
backend/src/main/resources/application-local.yml
```

This file is ignored by Git. Do not commit it.

Use this as the starting point and replace every placeholder:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/historia
    username: postgres
    password: YOUR_POSTGRES_PASSWORD

  mail:
    username: YOUR_GMAIL_ADDRESS
    password: YOUR_GMAIL_APP_PASSWORD

google:
  oauth:
    client-id: YOUR_GOOGLE_WEB_CLIENT_ID

jwt:
  secret: YOUR_BASE64_JWT_SECRET

admin:
  username: admin
  email: admin@historia.com
  phone: "0700000000"
  password: CHANGE_THIS_ADMIN_PASSWORD
```

The JWT secret must be Base64 text that decodes to a long random key. On Windows PowerShell, you can generate one like this:

```powershell
$bytes = New-Object byte[] 64
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

The admin account is created automatically on the first backend run, but only if there is no admin user already in the database.

## Google Sign-In Setup

For normal email/password login, Google setup is not used by the user. The backend still needs a Google Web client ID configured because the Google token verifier is created when the app starts.

For Android Google sign-in, Google Cloud needs an Android OAuth client matching this app:

```text
Package name: com.example.frontend
```

To get the debug SHA-1 for your laptop:

```powershell
cd frontend/android
.\gradlew signingReport
```

In Google Cloud, keep the Android OAuth client for the package name and SHA-1, and use the Web OAuth client ID in both places:

- `google.oauth.client-id` in `backend/src/main/resources/application-local.yml`
- `GOOGLE_WEB_CLIENT_ID` when running Flutter, if you want to override the value in the app

Example Flutter run with a client ID:

```powershell
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
```

## Run The Backend

Open a terminal in the project root:

```powershell
cd backend
.\mvnw.cmd clean test
.\mvnw.cmd spring-boot:run
```

The API runs on:

```text
http://localhost:8081
```

Hibernate is set to `ddl-auto: update`, so the database tables are created or updated when the backend starts.

## Run The Flutter App

Open another terminal in the project root:

```powershell
cd frontend
flutter pub get
flutter devices
flutter run
```

The Android emulator can reach the backend through this URL:

```text
http://10.0.2.2:8081
```

That is already set in:

```text
frontend/lib/config/api_config.dart
```

If you run the app on a real Android phone, `10.0.2.2` will not work. Put the phone and laptop on the same Wi-Fi network, find the laptop IP address with `ipconfig`, and change the base URL to something like:

```dart
static const String baseUrl = 'http://192.168.1.10:8081';
```

Make sure Windows Firewall allows the backend port if a real phone cannot connect.

## Useful Checks

Backend:

```powershell
cd backend
.\mvnw.cmd test
```

Frontend:

```powershell
cd frontend
flutter analyze
```

## Common Problems

If the backend says Google OAuth is not configured, check `google.oauth.client-id` in `application-local.yml`.

If registration works but no OTP email arrives, check the Gmail address and app password in `spring.mail`.

If the app says it cannot connect to the server, make sure the backend is running on port `8081` and the Flutter base URL matches your device type.

If PostgreSQL connection fails, confirm that PostgreSQL is running, the `historia` database exists, and the username/password in `application-local.yml` are correct.
