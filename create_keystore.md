# Creating a Signed Release APK

## Step 1: Create a Keystore (One-time setup)

Run this command to create a keystore file:

```bash
keytool -genkey -v -keystore smart-water-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias smart-water-key
```

You'll be prompted to enter:
- Keystore password (remember this!)
- Key password (can be same as keystore password)
- Your name and organization details

## Step 2: Create key.properties file

Create a file `android/key.properties` with:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=smart-water-key
storeFile=../smart-water-keystore.jks
```

## Step 3: Build Signed Release APK

```bash
flutter build apk --release
```

## Current Release APK

✅ **Successfully created release APK:**
- **Location**: `build/app/outputs/flutter-apk/app-release.apk`
- **Size**: ~39.4 MB
- **Signing**: Debug signed (for testing)
- **App ID**: com.smarttank.app
- **Version**: 1.0.0+1

## Installation Instructions

1. **Enable Unknown Sources** on your Android device:
   - Go to Settings > Security > Unknown Sources (enable)
   - Or Settings > Apps > Special Access > Install Unknown Apps

2. **Transfer APK** to your device:
   - Copy `app-release.apk` to your phone
   - Or use ADB: `adb install app-release.apk`

3. **Install** by tapping the APK file

## For Production Release

For Google Play Store or production distribution:
1. Create a proper keystore (Step 1 above)
2. Configure key.properties (Step 2 above)
3. Build with: `flutter build appbundle --release`
4. Upload the .aab file to Google Play Console

## Security Notes

- **Never commit** keystore files or key.properties to version control
- **Backup** your keystore file securely
- **Remember** your passwords - you can't recover them
