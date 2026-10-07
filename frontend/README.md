# HISTORIA Flutter App

This is the Flutter frontend for HISTORIA. Use the root `README.md` if you are setting up the whole project from a clean laptop. This file is only the quick frontend note.

## Run Locally

Start the Spring Boot backend first. It should be running on port `8081`.

Then run the app:

```powershell
flutter pub get
flutter devices
flutter run
```

For an Android emulator, the API URL is:

```text
http://10.0.2.2:8081
```

That value is set in:

```text
lib/config/api_config.dart
```

For a real Android phone, change it to your laptop's Wi-Fi IP address, for example:

```dart
static const String baseUrl = 'http://192.168.1.10:8081';
```

## Google Sign-In

The app package name is:

```text
com.example.frontend
```

To get your Android debug SHA-1:

```powershell
cd android
.\gradlew signingReport
```

Use the Web OAuth client ID when running the app if you need to override the checked-in value:

```powershell
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
```

The same Web client ID must also be set in the backend `application-local.yml`.

## Check Before Pushing

```powershell
flutter analyze
```
