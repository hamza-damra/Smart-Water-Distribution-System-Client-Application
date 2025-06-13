import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mytank/models/notification_model.dart';
import 'package:mytank/services/socket_service.dart';
import 'package:mytank/services/user_service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _isSocketConnected = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSocketConnected => _isSocketConnected;

  // Get count of unread notifications
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Get only unread notifications
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  // Get only read notifications
  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  // Initialize notifications from API data
  void initializeNotifications(List<dynamic> notificationsJson) {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Parse notifications from JSON
      final List<NotificationModel> parsedNotifications =
          notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();

      // Load read status from local storage
      _loadReadStatusFromStorage(parsedNotifications);
    } catch (e) {
      _error = 'Failed to load notifications: $e';
      debugPrint('❌ Error initializing notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load read status from SharedPreferences
  Future<void> _loadReadStatusFromStorage(
    List<NotificationModel> notifications,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotificationIds =
          prefs.getStringList('read_notifications') ?? [];

      _notifications =
          notifications.map((notification) {
            final isRead = readNotificationIds.contains(notification.id);
            return notification.copyWith(isRead: isRead);
          }).toList();

      // Sort notifications by creation date (newest first)
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint(
        '✅ Loaded ${_notifications.length} notifications, $unreadCount unread',
      );
    } catch (e) {
      debugPrint('❌ Error loading read status: $e');
      _notifications = notifications;
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);

        // Save to SharedPreferences
        await _saveReadStatusToStorage();

        notifyListeners();
        debugPrint('✅ Marked notification $notificationId as read');
      }
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      bool hasChanges = false;
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await _saveReadStatusToStorage();
        notifyListeners();
        debugPrint('✅ Marked all notifications as read');
      }
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  // Save read status to SharedPreferences
  Future<void> _saveReadStatusToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotificationIds =
          _notifications.where((n) => n.isRead).map((n) => n.id).toList();

      await prefs.setStringList('read_notifications', readNotificationIds);
    } catch (e) {
      debugPrint('❌ Error saving read status: $e');
    }
  }

  // Clear all notifications (for testing purposes)
  Future<void> clearAllNotifications() async {
    try {
      _notifications.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('read_notifications');
      notifyListeners();
      debugPrint('✅ Cleared all notifications');
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  // Refresh notifications (to be called when user data is refreshed)
  void refreshNotifications(List<dynamic> notificationsJson) {
    initializeNotifications(notificationsJson);
  }

  // Fetch fresh notifications from the API
  Future<void> fetchNotifications() async {
    try {
      debugPrint('🔄 Fetching fresh notifications from API...');

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch current user data which includes notifications
      final user = await UserService.getCurrentUser();

      debugPrint(
        '✅ Successfully fetched user data with ${user.notifications.length} notifications',
      );

      // Initialize notifications with the fresh data
      initializeNotifications(user.notifications);
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      _error = 'Failed to refresh notifications: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize real-time notifications with Socket.IO
  void initializeRealTimeNotifications(String userId, String token) {
    try {
      debugPrint('🔔 Initializing real-time notifications for user: $userId');

      final socketService = SocketService.instance;

      // Set up event handlers
      socketService.onNewNotification = _handleNewNotification;
      socketService.onConnect = _handleSocketConnect;
      socketService.onDisconnect = _handleSocketDisconnect;
      socketService.onError = _handleSocketError;

      // Connect to socket server
      socketService.connect(userId, token);

      debugPrint('✅ Real-time notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing real-time notifications: $e');
      _error = 'Failed to initialize real-time notifications: $e';
      notifyListeners();
    }
  }

  // Handle new notification received via Socket.IO
  void _handleNewNotification(NotificationModel notification) {
    try {
      debugPrint('🔔 Processing new real-time notification:');
      debugPrint('   📝 Message: ${notification.message}');
      debugPrint('   🆔 ID: ${notification.id}');
      debugPrint('   📅 Created: ${notification.createdAt}');
      debugPrint('   📖 Read status: ${notification.isRead}');

      // Check if notification already exists to avoid duplicates
      final existingIndex = _notifications.indexWhere(
        (n) => n.id == notification.id,
      );
      if (existingIndex != -1) {
        debugPrint('⚠️ Notification already exists, skipping duplicate');
        return;
      }

      // Add the new notification to the beginning of the list
      _notifications.insert(0, notification);

      // Sort notifications by creation date (newest first)
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Clear any previous errors
      _error = null;

      // Notify listeners to update UI
      notifyListeners();

      debugPrint(
        '✅ New notification added successfully. Total: ${_notifications.length}',
      );
      debugPrint('📊 Unread count: $unreadCount');

      // Show a brief summary of all notifications
      debugPrint('📋 Current notifications:');
      for (int i = 0; i < _notifications.length && i < 3; i++) {
        final n = _notifications[i];
        debugPrint(
          '   ${i + 1}. ${n.message.substring(0, n.message.length > 50 ? 50 : n.message.length)}${n.message.length > 50 ? '...' : ''} (${n.isRead ? 'read' : 'unread'})',
        );
      }
      if (_notifications.length > 3) {
        debugPrint('   ... and ${_notifications.length - 3} more');
      }
    } catch (e) {
      debugPrint('❌ Error handling new notification: $e');
      _error = 'Failed to process new notification: $e';
      notifyListeners();
    }
  }

  // Handle socket connection established
  void _handleSocketConnect() {
    debugPrint('✅ Socket connected - real-time notifications active');
    _isSocketConnected = true;
    _error = null;
    notifyListeners();
  }

  // Handle socket disconnection
  void _handleSocketDisconnect() {
    debugPrint('🔌 Socket disconnected - real-time notifications inactive');
    _isSocketConnected = false;
    notifyListeners();
  }

  // Handle socket errors
  void _handleSocketError(String error) {
    debugPrint('❌ Socket error: $error');
    _isSocketConnected = false;
    _error = 'Real-time connection error: $error';
    notifyListeners();
  }

  // Disconnect real-time notifications
  void disconnectRealTimeNotifications() {
    try {
      debugPrint('🔌 Disconnecting real-time notifications...');

      final socketService = SocketService.instance;
      socketService.disconnect();

      _isSocketConnected = false;

      debugPrint('✅ Real-time notifications disconnected');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error disconnecting real-time notifications: $e');
    }
  }

  // Add a new notification manually (for testing purposes)
  void addTestNotification() {
    final testNotification = NotificationModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      message: 'Test notification received at ${DateTime.now().toString()}',
      createdAt: DateTime.now().toIso8601String(),
      isRead: false,
    );

    _handleNewNotification(testNotification);
  }

  // Test with the exact format from your server
  void addTestNotificationWithServerFormat() {
    // Simulate the exact message format you provided
    final serverMessage = {
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

    debugPrint('🧪 Testing with server format: $serverMessage');

    try {
      final notificationData =
          serverMessage['notification'] as Map<String, dynamic>;
      final notification = NotificationModel.fromJson(notificationData);

      debugPrint(
        '✅ Successfully parsed test notification: ${notification.message}',
      );
      _handleNewNotification(notification);
    } catch (e) {
      debugPrint('❌ Error testing server format: $e');
    }
  }
}
