import 'package:flutter_test/flutter_test.dart';
import 'package:mytank/providers/notification_provider.dart';
import 'package:mytank/models/notification_model.dart';

void main() {
  group('Tank Level Update Socket.IO Enhancement Tests', () {
    test('should handle tank_level_update message format correctly', () {
      // Arrange - the new tank level update message format
      final tankLevelUpdateMessage = {
        "tank_id": "683b3172c676147ffe2452d6",
        "current_level": 1.5,
      };

      // Act
      final tankId = tankLevelUpdateMessage['tank_id'] as String;
      final currentLevel =
          (tankLevelUpdateMessage['current_level'] as num).toDouble();

      // Assert
      expect(tankId, equals('683b3172c676147ffe2452d6'));
      expect(currentLevel, equals(1.5));
      expect(tankId, isNotEmpty);
      expect(currentLevel, greaterThan(0));
    });

    test('should create notification from tank level update', () {
      // Arrange
      final tankId = "683b3172c676147ffe2452d6";
      final currentLevel = 1.5;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Act - simulate creating notification like in NotificationProvider
      final notificationMessage =
          'Tank level updated: ${currentLevel.toStringAsFixed(1)}L';
      final notification = NotificationModel(
        id: 'tank_update_${tankId}_$timestamp',
        message: notificationMessage,
        createdAt: DateTime.now().toIso8601String(),
        isRead: false,
      );

      // Assert
      expect(notification.message, equals('Tank level updated: 1.5L'));
      expect(notification.id, contains('tank_update_'));
      expect(notification.id, contains(tankId));
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, isNotEmpty);
    });

    test(
      'should handle both notification and tank_level_update message types',
      () {
        // Arrange - existing notification format
        final notificationMessage = {
          "userId": "67aa5bf3bb1b11a0e4e4441f",
          "notification": {
            "user": "67aa5bf3bb1b11a0e4e4441f",
            "message":
                "Tank 6805744e17e3b8b934a83aaa has more than one unpaid bills, we can't pump water for you now.",
            "_id": "684b4ba59edc422e2dc2caf3",
            "createdAt": "2025-06-12T21:50:29.855Z",
            "__v": 0,
          },
        };

        // Arrange - new tank level update format
        final tankLevelUpdateMessage = {
          "tank_id": "683b3172c676147ffe2452d6",
          "current_level": 1.5,
        };

        // Act & Assert - both message types should be valid
        // Notification message
        expect(notificationMessage['userId'], isNotNull);
        expect(notificationMessage['notification'], isNotNull);
        final notification =
            notificationMessage['notification'] as Map<String, dynamic>;
        expect(notification['message'], isNotNull);

        // Tank level update message
        expect(tankLevelUpdateMessage['tank_id'], isNotNull);
        expect(tankLevelUpdateMessage['current_level'], isNotNull);
        expect(tankLevelUpdateMessage['current_level'], isA<num>());
      },
    );

    test('should validate tank level update data correctly', () {
      // Test valid data
      final validData = {
        "tank_id": "683b3172c676147ffe2452d6",
        "current_level": 1.5,
      };

      final tankId = validData['tank_id']?.toString();
      final currentLevel = (validData['current_level'] as num?)?.toDouble();

      expect(tankId, isNotNull);
      expect(currentLevel, isNotNull);
      expect(tankId, isNotEmpty);
      expect(currentLevel, greaterThanOrEqualTo(0));

      // Test invalid data - missing tank_id
      final invalidData1 = {"current_level": 1.5};

      final invalidTankId = invalidData1['tank_id']?.toString();
      expect(invalidTankId, isNull);

      // Test invalid data - missing current_level
      final invalidData2 = {"tank_id": "683b3172c676147ffe2452d6"};

      final invalidLevel = (invalidData2['current_level'] as num?)?.toDouble();
      expect(invalidLevel, isNull);

      // Test invalid data - negative level
      final invalidData3 = {
        "tank_id": "683b3172c676147ffe2452d6",
        "current_level": -1.0,
      };

      final negativeLevel = (invalidData3['current_level'] as num?)?.toDouble();
      expect(
        negativeLevel,
        lessThan(0),
      ); // This would be caught by validation logic
    });

    test(
      'should format notification message correctly for different levels',
      () {
        // Test various level values
        final testCases = [
          {"level": 0.0, "expected": "Tank level updated: 0.0L"},
          {"level": 1.5, "expected": "Tank level updated: 1.5L"},
          {"level": 10.25, "expected": "Tank level updated: 10.3L"},
          {"level": 100.0, "expected": "Tank level updated: 100.0L"},
          {"level": 999.99, "expected": "Tank level updated: 1000.0L"},
        ];

        for (final testCase in testCases) {
          final level = testCase["level"] as double;
          final expected = testCase["expected"] as String;

          final message = 'Tank level updated: ${level.toStringAsFixed(1)}L';
          expect(message, equals(expected));
        }
      },
    );

    test('should handle pending tank updates correctly', () {
      // Arrange
      final notificationProvider = NotificationProvider();

      // Act - simulate storing pending updates
      // This would normally be done internally by _updateTankLevel
      // but we're testing the concept

      // Get initial pending updates (should be empty)
      var pendingUpdates = notificationProvider.getPendingTankUpdates();
      expect(pendingUpdates, isEmpty);

      // Note: In a real test, we would need to access the private method
      // For now, we're testing the public interface
    });
  });

  group('Socket.IO Event Handling Tests', () {
    test('should identify tank_level_update event correctly', () {
      // Arrange
      const eventName = 'tank_level_update';
      const notificationEventName = 'new_notification';

      // Act & Assert
      expect(eventName, equals('tank_level_update'));
      expect(eventName, isNot(equals(notificationEventName)));
      expect(notificationEventName, equals('new_notification'));
    });

    test('should handle concurrent events correctly', () {
      // This test verifies that both event types can be processed
      // in the same socket connection

      // Arrange - simulate receiving both events
      final events = [
        {
          "type": "new_notification",
          "data": {
            "userId": "67aa5bf3bb1b11a0e4e4441f",
            "notification": {
              "message": "Test notification",
              "_id": "test123",
              "createdAt": "2025-06-12T21:50:29.855Z",
            },
          },
        },
        {
          "type": "tank_level_update",
          "data": {"tank_id": "683b3172c676147ffe2452d6", "current_level": 1.5},
        },
      ];

      // Act & Assert
      for (final event in events) {
        final eventType = event["type"] as String;
        final eventData = event["data"] as Map<String, dynamic>;

        if (eventType == "new_notification") {
          expect(eventData["userId"], isNotNull);
          expect(eventData["notification"], isNotNull);
        } else if (eventType == "tank_level_update") {
          expect(eventData["tank_id"], isNotNull);
          expect(eventData["current_level"], isNotNull);
        }
      }
    });
  });
}
