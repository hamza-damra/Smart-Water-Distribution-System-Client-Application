import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A utility class to handle back button behavior in a Flutter app
class BackButtonHandler {
  /// Initialize the back button handler with proper system UI settings
  static void init() {
    // Set system UI overlay style for Android
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Enable edge-to-edge display
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  /// Create a WillPopScope wrapper for handling back button presses
  static Widget wrapWithBackHandler(
    BuildContext context,
    Widget child, {
    Future<bool> Function()? onWillPop,
  }) {
    return WillPopScope(
      onWillPop: onWillPop ?? () async => true,
      child: child,
    );
  }
}
