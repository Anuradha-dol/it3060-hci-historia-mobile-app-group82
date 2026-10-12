# Start Here

This repository contains the final HISTORIA mobile app for the IT3060 Human Computer Interaction module in Year 3, Semester 2.

Use the root `README.md` as the main guide. It explains the project idea, HCI assignment background, user roles, technology stack, backend REST API, PostgreSQL database, Flutter frontend, setup steps, and test commands.

Quick local flow:

1. Install Java 17, PostgreSQL, Flutter, Android Studio, and Git.
2. Create the local PostgreSQL database named `historia`.
3. Copy `backend/src/main/resources/application-local.example.yml` to `backend/src/main/resources/application-local.yml`.
4. Fill in your local database password, JWT secret, mail credentials, Google client ID, and optional admin account.
5. Start the backend from `backend/` with `.\mvnw.cmd spring-boot:run`.
6. Start the Flutter app from the repository root with `.\scripts\Run-Flutter.ps1 -Target emulator`.

Useful checks:

```powershell
cd backend
.\mvnw.cmd test
```

```powershell
cd frontend
flutter analyze
flutter test
```

For the full explanation, read `README.md`.
