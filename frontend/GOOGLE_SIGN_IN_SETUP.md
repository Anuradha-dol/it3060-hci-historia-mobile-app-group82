# Google Sign-In Setup

Google login does not use the app password or username fields. The Flutter app asks Google for an ID token through `google_sign_in` 6.x, then the backend verifies that token and creates or opens the local HISTORIA user.

For Android, Google Cloud must have an Android OAuth client that matches this app build:

- Package name: `com.example.frontend`
- Debug signing certificate SHA-1 on this machine: `E6:22:17:CD:39:2B:36:16:18:2D:F6:A1:9D:EF:7A:0B:7F:51:FE:3C`
- Web client ID: the same value used by `GOOGLE_WEB_CLIENT_ID` in Flutter and `GOOGLE_CLIENT_ID` in the backend

To get the debug SHA-1 on Windows:

```powershell
cd frontend/android
.\gradlew signingReport
```

Or, if `keytool` is on PATH:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

If the app says Google account re-authentication failed, the native Android flow returned `[16] Account reauth failed`. Remove and add the Google account in the emulator, then confirm the package name, SHA-1, and Web client ID in Google Cloud.

If logcat shows `ApiException: 10`, Google rejected the app as a developer configuration error. In Google Cloud Console, create or update an Android OAuth client with package `com.example.frontend` and SHA-1 `E6:22:17:CD:39:2B:36:16:18:2D:F6:A1:9D:EF:7A:0B:7F:51:FE:3C`. The backend and Flutter app must continue to use the Web OAuth client ID, not the Android client ID.
