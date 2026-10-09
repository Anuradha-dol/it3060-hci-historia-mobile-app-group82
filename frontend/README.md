# HISTORIA Flutter App

This is the Flutter frontend for HISTORIA. Use the root `README.md` if you are setting up the whole project from a clean laptop. This file is only the quick frontend note.

## Run Locally

Start the Spring Boot backend first. It should be running on port `8081`.

Then run the app from the repository root with the helper script:

```powershell
.\scripts\Run-Flutter.ps1 -Target emulator
```

Supported targets:

- `emulator` uses `http://10.0.2.2:8081`
- `usb` runs `adb reverse tcp:8081 tcp:8081` and uses `http://127.0.0.1:8081`
- `chrome` uses `http://localhost:8081` and `--web-port 5300`
- `wifi` uses `http://YOUR_LAPTOP_LAN_IP:8081`

Examples:

```powershell
.\scripts\Run-Flutter.ps1 -Target usb
.\scripts\Run-Flutter.ps1 -Target chrome
.\scripts\Run-Flutter.ps1 -Target wifi -LaptopIp 192.168.1.10
```

If more than one device is connected, run `flutter devices` and pass `-DeviceId YOUR_DEVICE_ID`.

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
.\scripts\Run-Flutter.ps1 -Target emulator -GoogleWebClientId YOUR_GOOGLE_WEB_CLIENT_ID
```

The same Web client ID must also be set in the backend `application-local.yml`. For Chrome Google sign-in, add `http://localhost:5300` as an authorized JavaScript origin in the Web OAuth client.

## Check Before Pushing

```powershell
flutter analyze
```
