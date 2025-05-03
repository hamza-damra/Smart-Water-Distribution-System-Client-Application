# Smart Tank Android Installation Guide

This document provides instructions for installing and distributing the Smart Tank Android application.

## Available Installation Files

The following installation files are available:

### APK Files (Direct Installation)

1. **Universal APK (all architectures):**
   - Location: `build/app/outputs/flutter-apk/app-release.apk`
   - Size: ~38.6MB
   - Use this if you're unsure which architecture to use or want a single APK that works on all devices.

2. **Architecture-specific APKs (smaller size):**
   - ARM 32-bit: `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (~23.5MB)
     - For older Android devices with 32-bit processors
   - ARM 64-bit: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~24.0MB)
     - For most modern Android devices (recommended for most users)
   - x86_64: `build/app/outputs/flutter-apk/app-x86_64-release.apk` (~24.1MB)
     - For emulators and rare x86_64 Android devices

3. **Debug APK (for testing):**
   - Location: `build/app/outputs/flutter-apk/app-debug.apk`
   - Use this for testing purposes only, not for distribution.

### App Bundle (Google Play Store)

- Location: `build/app/outputs/bundle/release/app-release.aab`
- Size: ~37.0MB
- Use this file for uploading to the Google Play Store.

## Installation Instructions

### Direct APK Installation (for users)

1. Transfer the appropriate APK file to the Android device (via email, USB, cloud storage, etc.)
2. On the Android device, locate and tap the APK file
3. If prompted, allow installation from unknown sources
4. Follow the on-screen instructions to complete the installation
5. Once installed, the "Smart Tank" app will appear in the app drawer

### Google Play Store Publishing (for developers)

1. Sign in to the [Google Play Console](https://play.google.com/console)
2. Create a new app or select an existing app
3. Navigate to "Production" > "Create new release"
4. Upload the `app-release.aab` file
5. Complete the store listing, content rating, and pricing & distribution sections
6. Submit the app for review

## Security Information

The APK and AAB files are signed with the following keystore information:

- Keystore location: `android/app/keystore/smart_tank.keystore`
- Keystore password: `smarttank123`
- Key alias: `smart_tank`
- Key password: `smarttank123`
- Validity: 10,000 days

**Important:** Keep the keystore file and passwords secure. You will need the same keystore to sign future updates of the app.

## Technical Details

- Application ID: `com.smarttank.app`
- Version: 1.0.0+1
- Min SDK: 21 (Android 5.0 Lollipop)
- Target SDK: 34 (Android 14)
- Compile SDK: 34 (Android 14)

## Troubleshooting

If you encounter installation issues:

1. Make sure "Install from unknown sources" is enabled in your device settings
2. Check that you have enough storage space on your device
3. If updating, try uninstalling the previous version first
4. Ensure your Android version is compatible (Android 5.0 or higher)

For any other issues, please contact support at support@smarttank.com
