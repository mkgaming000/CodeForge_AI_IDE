# CodeForge — Setup Guide

## Step 1: Install Flutter

Follow the official guide for your OS: https://flutter.dev/docs/get-started/install

Verify your installation:
```bash
flutter doctor
```
All Android-related checks must pass (Android Studio / SDK and a connected device or emulator).

## Step 2: Get dependencies

```bash
cd codeforge
flutter pub get
```

If you see a pub cache error, run:
```bash
flutter pub cache repair
flutter pub get
```

## Step 3: Connect a device or start an emulator

```bash
flutter devices          # list connected devices
flutter emulators        # list available emulators
flutter emulators --launch <emulator_id>
```

## Step 4: Run the app

```bash
flutter run
```

For hot reload while developing, press `r` in the terminal. For hot restart, press `R`.

## Step 5: Add your Claude API key

1. Tap **Settings** on the home screen (or gear icon in the app bar).  
2. Scroll to **AI Assistant**.  
3. Paste your key from https://console.anthropic.com  
4. Tap **Save**.

The key is stored in the Android Keystore via `flutter_secure_storage` — it never leaves your device except in direct API calls to `api.anthropic.com`.

## Step 6: Grant storage access

On first launch, when you tap **Open Folder** or **New Project**, CodeForge will ask for storage permission:

- **Android 10 and below**: a standard "Allow access to files" dialog appears.  
- **Android 11+**: you are taken to **Settings → Apps → CodeForge → Permissions → Files and media** and must grant "All files access" (`MANAGE_EXTERNAL_STORAGE`). This is required to open arbitrary project folders anywhere on the filesystem.

## Step 7: Run the test suite (optional but recommended)

```bash
flutter test
```

This runs the full unit test suite (language registry, undo/redo stack, file model, and editor provider find/replace/save logic) against real temp files on disk — no mocking required.

## A note on the Gradle wrapper

`android/gradle/wrapper/gradle-wrapper.jar` is a compiled binary published by the Gradle project, not source code, so it isn't included as a raw byte blob in this archive. The first time you run `flutter run` or `flutter build apk` with internet access, the Flutter/Gradle tooling downloads it automatically using the version pinned in `gradle-wrapper.properties` (already included) — this is standard behavior for any Flutter Android project, not specific to CodeForge. If you'd rather fetch it explicitly up front:

```bash
cd android
gradle wrapper --gradle-version 8.6
cd ..
```

(Requires a system-wide Gradle install only for this one bootstrap step; every subsequent build uses the project's own `./gradlew`.)

## Build a release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Or an App Bundle for the Play Store:
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

> **Signing**: the release build currently uses the debug keystore. Replace `signingConfig = signingConfigs.debug` in `android/app/build.gradle` with your own keystore before publishing.

## Common issues

| Symptom | Fix |
|---|---|
| `flutter pub get` fails with network error | Run `flutter pub cache clean`, then retry |
| Build fails: `compileSdkVersion` too low | Update Android SDK via Android Studio SDK Manager |
| "All files access" dialog never appears | The permission may be permanently denied; go to **Settings → Apps → CodeForge → Permissions** manually |
| AI features show "No API key" | Complete Step 5 above |
| Font glitches on first load | `google_fonts` downloads fonts on first use; connect to the internet for the first run |
