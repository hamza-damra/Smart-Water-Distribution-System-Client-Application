import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/utilities/route_manager.dart';

void main() {
  group('Settings Integration Tests', () {
    test('should have settings route properly configured', () {
      // Verify the settings route is defined
      expect(RouteManager.settingsRoute, equals('/settings'));
    });

    test('should handle complete URL update flow', () async {
      // Start with clean state
      SharedPreferences.setMockInitialValues({});
      
      // Step 1: Initialize with default URL (first-time user)
      await Constants.initializeUrls();
      final initialBaseUrl = Constants.baseUrl;
      final initialApiUrl = Constants.apiUrl;
      
      // Verify initial state
      expect(initialBaseUrl, isNotEmpty);
      expect(initialApiUrl, isNotEmpty);
      expect(initialApiUrl, contains('/api'));
      
      // Step 2: Update URL through settings
      const newServerUrl = 'https://new-server.example.com';
      await Constants.updateBaseUrl(newServerUrl);
      
      // Verify URL update
      expect(Constants.baseUrl, equals(newServerUrl));
      expect(Constants.apiUrl, equals('$newServerUrl/api'));
      
      // Step 3: Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('server_url'), equals(newServerUrl));
      
      // Step 4: Simulate app restart by reinitializing
      await Constants.initializeUrls();
      
      // Verify URLs are restored from storage
      expect(Constants.baseUrl, equals(newServerUrl));
      expect(Constants.apiUrl, equals('$newServerUrl/api'));
    });

    test('should handle URL normalization correctly', () async {
      // Test various URL formats
      final testCases = [
        {
          'input': 'https://example.com/',
          'expected': 'https://example.com',
        },
        {
          'input': 'http://test.com',
          'expected': 'http://test.com',
        },
        {
          'input': 'https://api.server.com//',
          'expected': 'https://api.server.com',
        },
      ];

      for (final testCase in testCases) {
        await Constants.updateBaseUrl(testCase['input']!);
        expect(Constants.baseUrl, equals(testCase['expected']));
        expect(Constants.apiUrl, equals('${testCase['expected']}/api'));
      }
    });

    test('should provide correct endpoint URLs after configuration', () async {
      const customUrl = 'https://custom.server.com';
      await Constants.updateBaseUrl(customUrl);
      
      // Verify all endpoint URLs are updated
      expect(Constants.loginEndpoint, equals('$customUrl/api/customer/login'));
      expect(Constants.userInfoEndpoint, equals('$customUrl/api/customer/current-user'));
      expect(Constants.socketUrl, equals(customUrl));
    });
  });
}
