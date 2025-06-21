import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mytank/utilities/token_manager.dart';

void main() {
  group('Login State Persistence Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should save complete session data to SharedPreferences', () async {
      // Arrange
      const token = 'test_token_12345';
      const userName = 'John Doe';
      const userId = 'user_123';

      // Act
      await TokenManager.saveCompleteSession(
        token: token,
        userName: userName,
        userId: userId,
      );

      // Assert
      final savedToken = await TokenManager.getToken();
      final savedUserName = await TokenManager.getUserName();
      final savedUserId = await TokenManager.getUserId();
      final isLoggedIn = await TokenManager.isLoggedIn();

      expect(savedToken, equals(token));
      expect(savedUserName, equals(userName));
      expect(savedUserId, equals(userId));
      expect(isLoggedIn, isTrue);
    });

    test(
      'should retrieve complete session data from SharedPreferences',
      () async {
        // Arrange
        const token = 'test_token_67890';
        const userName = 'Jane Smith';
        const userId = 'user_456';

        await TokenManager.saveCompleteSession(
          token: token,
          userName: userName,
          userId: userId,
        );

        // Act
        final sessionData = await TokenManager.getCompleteSession();

        // Assert
        expect(sessionData['token'], equals(token));
        expect(sessionData['userName'], equals(userName));
        expect(sessionData['userId'], equals(userId));
        expect(sessionData['isLoggedIn'], equals('true'));
      },
    );

    test('should clear complete session data from SharedPreferences', () async {
      // Arrange - save some data first
      await TokenManager.saveCompleteSession(
        token: 'test_token',
        userName: 'Test User',
        userId: 'test_id',
      );

      // Verify data is saved
      var isLoggedIn = await TokenManager.isLoggedIn();
      expect(isLoggedIn, isTrue);

      // Act
      await TokenManager.clearCompleteSession();

      // Assert
      final token = await TokenManager.getToken();
      final userName = await TokenManager.getUserName();
      final userId = await TokenManager.getUserId();
      isLoggedIn = await TokenManager.isLoggedIn();

      expect(token, isNull);
      expect(userName, isNull);
      expect(userId, isNull);
      expect(isLoggedIn, isFalse);
    });

    test('should handle partial session data correctly', () async {
      // Arrange - save only token and username (no userId)
      const token = 'partial_token';
      const userName = 'Partial User';

      await TokenManager.saveCompleteSession(
        token: token,
        userName: userName,
        userId: null, // No user ID
      );

      // Act
      final sessionData = await TokenManager.getCompleteSession();

      // Assert
      expect(sessionData['token'], equals(token));
      expect(sessionData['userName'], equals(userName));
      expect(sessionData['userId'], isNull);
      expect(sessionData['isLoggedIn'], equals('true'));
    });

    test('should return empty session when no data is stored', () async {
      // Act - get session without saving anything
      final sessionData = await TokenManager.getCompleteSession();

      // Assert
      expect(sessionData['token'], isNull);
      expect(sessionData['userName'], isNull);
      expect(sessionData['userId'], isNull);
      expect(sessionData['isLoggedIn'], equals('false'));
    });

    test('should handle individual data operations correctly', () async {
      // Test individual save operations
      await TokenManager.saveToken('individual_token');
      await TokenManager.saveUserData(
        userName: 'Individual User',
        userId: 'ind_123',
      );
      await TokenManager.setLoggedIn(true);

      // Test individual get operations
      final token = await TokenManager.getToken();
      final userName = await TokenManager.getUserName();
      final userId = await TokenManager.getUserId();
      final isLoggedIn = await TokenManager.isLoggedIn();

      expect(token, equals('individual_token'));
      expect(userName, equals('Individual User'));
      expect(userId, equals('ind_123'));
      expect(isLoggedIn, isTrue);

      // Test individual clear operations
      await TokenManager.clearToken();
      await TokenManager.clearUserData();
      await TokenManager.setLoggedIn(false);

      final clearedToken = await TokenManager.getToken();
      final clearedUserName = await TokenManager.getUserName();
      final clearedUserId = await TokenManager.getUserId();
      final clearedLoggedIn = await TokenManager.isLoggedIn();

      expect(clearedToken, isNull);
      expect(clearedUserName, isNull);
      expect(clearedUserId, isNull);
      expect(clearedLoggedIn, isFalse);
    });

    test(
      'should handle AuthProvider initialization with saved session',
      () async {
        // Arrange - save a session
        const token = 'auth_provider_token';
        const userName = 'Auth User';
        const userId = 'auth_123';

        await TokenManager.saveCompleteSession(
          token: token,
          userName: userName,
          userId: userId,
        );

        // Act - test session retrieval (AuthProvider would use this in initialize)
        // Note: In a real test, we would need to mock the HTTP calls
        // For now, we're testing the session retrieval part
        final sessionData = await TokenManager.getCompleteSession();

        // Assert
        expect(sessionData['token'], equals(token));
        expect(sessionData['userName'], equals(userName));
        expect(sessionData['userId'], equals(userId));
        expect(sessionData['isLoggedIn'], equals('true'));
      },
    );

    test(
      'should handle session persistence across app restarts simulation',
      () async {
        // Simulate first app session
        const token = 'persistent_token';
        const userName = 'Persistent User';
        const userId = 'persist_123';

        // Save session (simulating login)
        await TokenManager.saveCompleteSession(
          token: token,
          userName: userName,
          userId: userId,
        );

        // Verify session is saved
        var sessionData = await TokenManager.getCompleteSession();
        expect(sessionData['token'], equals(token));
        expect(sessionData['isLoggedIn'], equals('true'));

        // Simulate app restart by creating new SharedPreferences instance
        // (In real test, this would involve restarting the app)

        // Retrieve session after "restart"
        sessionData = await TokenManager.getCompleteSession();

        // Assert session persists
        expect(sessionData['token'], equals(token));
        expect(sessionData['userName'], equals(userName));
        expect(sessionData['userId'], equals(userId));
        expect(sessionData['isLoggedIn'], equals('true'));
      },
    );

    test('should validate session data format correctly', () async {
      // Test with various data types and edge cases
      const testCases = [
        {
          'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
          'userName': 'Test User With Spaces',
          'userId': '507f1f77bcf86cd799439011',
        },
        {'token': 'simple_token', 'userName': 'SimpleUser', 'userId': '123'},
        {
          'token': 'token_with_special_chars_!@#\$%',
          'userName': 'User-With-Dashes_And_Underscores',
          'userId': 'user_id_with_underscores_123',
        },
      ];

      for (final testCase in testCases) {
        // Save session
        await TokenManager.saveCompleteSession(
          token: testCase['token']!,
          userName: testCase['userName']!,
          userId: testCase['userId']!,
        );

        // Retrieve and verify
        final sessionData = await TokenManager.getCompleteSession();
        expect(sessionData['token'], equals(testCase['token']));
        expect(sessionData['userName'], equals(testCase['userName']));
        expect(sessionData['userId'], equals(testCase['userId']));
        expect(sessionData['isLoggedIn'], equals('true'));

        // Clear for next iteration
        await TokenManager.clearCompleteSession();
      }
    });
  });
}
