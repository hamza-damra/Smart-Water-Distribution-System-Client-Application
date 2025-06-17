import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/utilities/route_manager.dart';

void main() {
  group('URL Configuration Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should use default URLs when no saved URL exists', () async {
      await Constants.initializeUrls();

      expect(
        Constants.baseUrl,
        equals('https://smart-water-distribution-system-vll8.onrender.com'),
      );
      expect(
        Constants.apiUrl,
        equals('https://smart-water-distribution-system-vll8.onrender.com/api'),
      );
    });

    test('should use saved URL when it exists in SharedPreferences', () async {
      // Set up mock SharedPreferences with a saved URL
      SharedPreferences.setMockInitialValues({
        'server_url': 'https://custom-server.com',
      });

      await Constants.initializeUrls();

      expect(Constants.baseUrl, equals('https://custom-server.com'));
      expect(Constants.apiUrl, equals('https://custom-server.com/api'));
    });

    test('should update URLs when updateBaseUrl is called', () async {
      const newUrl = 'https://new-server.com';

      await Constants.updateBaseUrl(newUrl);

      expect(Constants.baseUrl, equals(newUrl));
      expect(Constants.apiUrl, equals('$newUrl/api'));

      // Verify it was saved to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('server_url'), equals(newUrl));
    });

    test('should provide correct endpoint URLs', () async {
      const customUrl = 'https://test-server.com';
      await Constants.updateBaseUrl(customUrl);

      expect(Constants.loginEndpoint, equals('$customUrl/api/customer/login'));
      expect(
        Constants.userInfoEndpoint,
        equals('$customUrl/api/customer/current-user'),
      );
      expect(Constants.socketUrl, equals(customUrl));
    });

    test('should handle URL with trailing slash', () async {
      const urlWithSlash = 'https://test-server.com/';
      const expectedCleanUrl = 'https://test-server.com';
      await Constants.updateBaseUrl(urlWithSlash);

      // The updateBaseUrl method should remove trailing slash
      expect(Constants.baseUrl, equals(expectedCleanUrl));
      expect(Constants.apiUrl, equals('$expectedCleanUrl/api'));
    });
  });

  group('Settings Flow Tests', () {
    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should have correct settings route defined', () {
      expect(RouteManager.settingsRoute, equals('/settings'));
    });

    test('should handle first-time user flow correctly', () async {
      // Clear SharedPreferences to simulate first-time user
      SharedPreferences.setMockInitialValues({});

      await Constants.initializeUrls();

      // Should use default URLs for first-time users
      expect(
        Constants.baseUrl,
        equals('https://smart-water-distribution-system-vll8.onrender.com'),
      );
      expect(
        Constants.apiUrl,
        equals('https://smart-water-distribution-system-vll8.onrender.com/api'),
      );
    });

    test('should handle returning user flow correctly', () async {
      // Set up mock SharedPreferences with existing server URL
      SharedPreferences.setMockInitialValues({
        'server_url': 'https://custom-server.com',
      });

      await Constants.initializeUrls();

      // Should use saved URLs for returning users
      expect(Constants.baseUrl, equals('https://custom-server.com'));
      expect(Constants.apiUrl, equals('https://custom-server.com/api'));
    });

    test('should update URLs through settings correctly', () async {
      const newUrl = 'https://new-settings-server.com';

      await Constants.updateBaseUrl(newUrl);

      // Verify URLs are updated
      expect(Constants.baseUrl, equals(newUrl));
      expect(Constants.apiUrl, equals('$newUrl/api'));

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('server_url'), equals(newUrl));
    });

    test('should handle URL normalization in settings', () async {
      // Test URL with trailing slash
      const urlWithSlash = 'https://test-server.com/';
      const expectedCleanUrl = 'https://test-server.com';

      await Constants.updateBaseUrl(urlWithSlash);

      expect(Constants.baseUrl, equals(expectedCleanUrl));
      expect(Constants.apiUrl, equals('$expectedCleanUrl/api'));
    });
  });
}
