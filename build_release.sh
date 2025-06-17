#!/bin/bash

echo "========================================"
echo "   Smart Water System - Release Build"
echo "========================================"
echo

echo "[1/4] Cleaning previous builds..."
flutter clean
echo

echo "[2/4] Getting dependencies..."
flutter pub get
echo

echo "[3/4] Building release APK..."
flutter build apk --release
echo

echo "[4/4] Build complete!"
echo

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "✅ SUCCESS: Release APK created successfully!"
    echo
    echo "📁 Location: build/app/outputs/flutter-apk/app-release.apk"
    echo "📱 App ID: com.smarttank.app"
    echo "🔢 Version: 1.0.0+1"
    echo
    echo "📋 Next steps:"
    echo "   1. Transfer APK to your Android device"
    echo "   2. Enable 'Unknown Sources' in device settings"
    echo "   3. Install the APK"
    echo
    echo "🔐 For production release:"
    echo "   1. Create a keystore file"
    echo "   2. Configure android/key.properties"
    echo "   3. Build with proper signing"
    echo
else
    echo "❌ ERROR: APK build failed!"
    echo "Check the output above for error details."
fi

echo "Press Enter to exit..."
read
