import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  // App colors - Modern palette
  static const Color primaryColor = Color(0xFF2E5C8A); // Modern navy blue
  static const Color secondaryColor = Color(0xFF4A90E2); // Vibrant blue
  static const Color accentColor = Color(0xFF5AC8FA); // Light blue for water
  static const Color whiteColor = Colors.white;
  static const Color blackColor = Color(0xFF2C3E50); // Dark blue-gray
  static const Color greyColor = Color(0xFF7F8C8D); // Modern gray
  static const Color lightGreyColor = Color(
    0xFFECF0F1,
  ); // Light gray with blue tint
  static const Color errorColor = Color(0xFFE74C3C); // Modern red
  static const Color successColor = Color(0xFF2ECC71); // Modern green
  static const Color warningColor = Color(0xFFF39C12); // Modern orange
  static const Color infoColor = Color(0xFF3498DB); // Modern blue
  static const Color backgroundColor = Color(
    0xFFF8FAFD,
  ); // Very light blue background

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: blackColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: blackColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: blackColor,
  );

  // Padding and margins
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border radius
  static const double defaultBorderRadius = 10.0;
  static const double largeBorderRadius = 20.0;

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Default server URL
  static const String defaultBaseUrl =
      'https://smart-water-distribution-system-vll8.onrender.com';
  static const String defaultApiUrl = '$defaultBaseUrl/api';

  // Dynamic server URL (initialized with default)
  static String _baseUrl = defaultBaseUrl;
  static String _apiUrl = defaultApiUrl;

  // Getters for URLs
  static String get baseUrl => _baseUrl;
  static String get apiUrl => _apiUrl;

  // Update base URL and API URL
  static Future<void> updateBaseUrl(String newBaseUrl) async {
    // Remove trailing slashes if present
    String cleanUrl = newBaseUrl;
    while (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    _baseUrl = cleanUrl;
    _apiUrl = '$cleanUrl/api';

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', cleanUrl);
  }

  // Initialize URLs from SharedPreferences
  static Future<void> initializeUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null) {
      // Remove trailing slashes if present
      String cleanUrl = savedUrl;
      while (cleanUrl.endsWith('/')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }
      _baseUrl = cleanUrl;
      _apiUrl = '$cleanUrl/api';
    }
  }

  // API endpoints
  static String get loginEndpoint => '$apiUrl/customer/login';
  static String get userInfoEndpoint => '$apiUrl/customer/current-user';

  // Socket.IO server URL for real-time notifications
  static String get socketUrl => baseUrl;

  // Toast/Snackbar styles
  static const Duration toastDuration = Duration(seconds: 4);
  static const Duration shortToastDuration = Duration(seconds: 2);
}
