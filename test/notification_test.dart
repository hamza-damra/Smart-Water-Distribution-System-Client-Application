import 'package:flutter_test/flutter_test.dart';
import 'package:mytank/models/notification_model.dart';

void main() {
  group('Notification System Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('should parse notification from server format correctly', () {
      // Arrange - the exact format from your server
      final serverNotificationData = {
        "user": "67aa5bf3bb1b11a0e4e4441f",
        "message":
            "Tank 6805744e17e3b8b934a83aaa has more than one unpaid bills, we can't pump water for you now.",
        "_id": "684b4ba59edc422e2dc2caf3",
        "createdAt": "2025-06-12T21:50:29.855Z",
        "__v": 0,
      };

      // Act
      final notification = NotificationModel.fromJson(serverNotificationData);

      // Assert
      expect(notification.id, equals("684b4ba59edc422e2dc2caf3"));
      expect(notification.message, contains("Tank 6805744e17e3b8b934a83aaa"));
      expect(notification.message, contains("unpaid bills"));
      expect(notification.createdAt, equals("2025-06-12T21:50:29.855Z"));
      expect(notification.isRead, equals(false)); // Should default to false
    });

    test('should handle complete server message format', () {
      // Arrange - the complete message format you provided
      final completeServerMessage = {
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

      // Act
      final userId = completeServerMessage['userId'] as String;
      final notificationData =
          completeServerMessage['notification'] as Map<String, dynamic>;
      final notification = NotificationModel.fromJson(notificationData);

      // Assert
      expect(userId, equals("67aa5bf3bb1b11a0e4e4441f"));
      expect(notification.id, equals("684b4ba59edc422e2dc2caf3"));
      expect(notification.message, contains("Tank 6805744e17e3b8b934a83aaa"));
      expect(notification.createdAt, equals("2025-06-12T21:50:29.855Z"));
    });

    test('should parse multiple notifications correctly', () {
      // Arrange
      final notificationsJson = [
        {
          "_id": "test1",
          "message": "Test notification 1",
          "createdAt": "2025-01-20T10:00:00.000Z",
        },
        {
          "_id": "test2",
          "message": "Test notification 2",
          "createdAt": "2025-01-20T11:00:00.000Z",
        },
      ];

      // Act - Parse notifications individually to avoid SharedPreferences
      final notifications =
          notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();

      // Assert
      expect(notifications.length, equals(2));
      expect(notifications[0].id, equals("test1"));
      expect(notifications[1].id, equals("test2"));
      expect(notifications[0].message, equals("Test notification 1"));
      expect(notifications[1].message, equals("Test notification 2"));
    });

    test('should format notification dates correctly', () {
      // Arrange
      final notification = NotificationModel(
        id: "test",
        message: "Test message",
        createdAt: "2025-01-20T10:30:00.000Z",
        isRead: false,
      );

      // Act
      final formattedDate = notification.getFormattedDate();
      final relativeTime = notification.getRelativeTime();

      // Assert
      expect(formattedDate, isNotEmpty);
      expect(relativeTime, isNotEmpty);
    });

    test('should handle notification read status correctly', () {
      // Arrange
      final notification = NotificationModel(
        id: "test",
        message: "Test message",
        createdAt: "2025-01-20T10:30:00.000Z",
        isRead: false,
      );

      // Act
      final readNotification = notification.copyWith(isRead: true);

      // Assert
      expect(notification.isRead, equals(false));
      expect(readNotification.isRead, equals(true));
      expect(readNotification.id, equals(notification.id));
      expect(readNotification.message, equals(notification.message));
    });
  });
}
