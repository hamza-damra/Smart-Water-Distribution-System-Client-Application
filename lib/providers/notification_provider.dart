import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mytank/models/notification_model.dart';
import 'package:mytank/services/socket_service.dart';
import 'package:mytank/services/user_service.dart';
import 'package:mytank/utilities/token_manager.dart';
import 'dart:async';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _isSocketConnected = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  String? _currentUserId;

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

      _currentUserId = userId;

      final socketService = SocketService.instance;

      // Set up event handlers
      socketService.onNewNotification = _handleNewNotification;
      socketService.onTankLevelUpdate = _handleTankLevelUpdate;
      socketService.onConnect = _handleSocketConnect;
      socketService.onDisconnect = _handleSocketDisconnect;
      socketService.onError = _handleSocketError;

      // Connect to socket server
      socketService.connect(userId, token);

      // Start heartbeat to maintain connection
      _startHeartbeat();

      debugPrint('✅ Real-time notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing real-time notifications: $e');
      _error = 'Failed to initialize real-time notifications: $e';
      notifyListeners();
    }
  }

  // Start heartbeat to ensure connection stays alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      final socketService = SocketService.instance;
      if (socketService.isConnected && _currentUserId != null) {
        socketService.emit('heartbeat', {'userId': _currentUserId});
        debugPrint('💓 Heartbeat sent');
      }
    });
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

      // Notify listeners to update UI IMMEDIATELY
      notifyListeners();

      debugPrint(
        '✅ New notification added successfully. Total: ${_notifications.length}',
      );
      debugPrint('📊 Unread count: $unreadCount');

      // Schedule another notification to ensure UI updates
      Future.delayed(Duration(milliseconds: 100), () {
        notifyListeners();
      });

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

  // Handle tank level update received via Socket.IO
  void _handleTankLevelUpdate(Map<String, dynamic> data) {
    try {
      final String? tankId = data['tank_id']?.toString();
      final double? currentLevel = (data['current_level'] as num?)?.toDouble();

      debugPrint('🌊 Processing tank level update:');
      debugPrint('   🏷️ Tank ID: $tankId');
      debugPrint('   📊 Current Level: $currentLevel L');

      if (tankId == null || currentLevel == null) {
        debugPrint('❌ Invalid tank level update data');
        return;
      }

      // Create a notification for the tank level update
      final notificationMessage =
          'Tank level updated: ${currentLevel.toStringAsFixed(1)}L';
      final notification = NotificationModel(
        id: 'tank_update_${tankId}_${DateTime.now().millisecondsSinceEpoch}',
        message: notificationMessage,
        createdAt: DateTime.now().toIso8601String(),
        isRead: false,
      );

      // Add the notification to the list
      _handleNewNotification(notification);

      // Store tank level update for processing
      _updateTankLevel(tankId, currentLevel);

      debugPrint('✅ Tank level update processed successfully');
    } catch (e) {
      debugPrint('❌ Error handling tank level update: $e');
      _error = 'Failed to process tank level update: $e';
      notifyListeners();
    }
  }

  // Update tank level in relevant providers
  void _updateTankLevel(String tankId, double currentLevel) {
    try {
      debugPrint('🔄 Updating tank level in providers...');
      debugPrint('   🏷️ Tank ID: $tankId');
      debugPrint('   📊 New Level: $currentLevel L');

      // Store the update for later processing when providers are available
      // This will be handled by the application when it has access to the provider context
      _pendingTankUpdates[tankId] = currentLevel;

      debugPrint('✅ Tank level update stored for processing');
    } catch (e) {
      debugPrint('❌ Error storing tank level update: $e');
    }
  }

  // Store pending tank updates
  final Map<String, double> _pendingTankUpdates = {};

  // Get and clear pending tank updates
  Map<String, double> getPendingTankUpdates() {
    final updates = Map<String, double>.from(_pendingTankUpdates);
    _pendingTankUpdates.clear();
    return updates;
  }

  // Process tank level updates with provider access
  void processTankLevelUpdates(dynamic mainTankProvider, dynamic tankProvider) {
    try {
      final updates = getPendingTankUpdates();
      if (updates.isEmpty) return;

      debugPrint(
        '🔄 Processing ${updates.length} pending tank level updates...',
      );

      for (final entry in updates.entries) {
        final tankId = entry.key;
        final currentLevel = entry.value;

        debugPrint('   🌊 Processing update for tank $tankId: $currentLevel L');

        // Update MainTankProvider if it has the updateTankLevel method
        if (mainTankProvider != null) {
          try {
            mainTankProvider.updateTankLevel(tankId, currentLevel);
            debugPrint('   ✅ Updated MainTankProvider');
          } catch (e) {
            debugPrint('   ❌ Error updating MainTankProvider: $e');
          }
        }

        // Update TankProvider if it has the updateTankLevel method
        if (tankProvider != null) {
          try {
            tankProvider.updateTankLevel(tankId, currentLevel);
            debugPrint('   ✅ Updated TankProvider');
          } catch (e) {
            debugPrint('   ❌ Error updating TankProvider: $e');
          }
        }
      }

      debugPrint('✅ All pending tank level updates processed');
    } catch (e) {
      debugPrint('❌ Error processing tank level updates: $e');
    }
  }

  // Handle socket connection established
  void _handleSocketConnect() {
    debugPrint('✅ Socket connected - real-time notifications active');
    _isSocketConnected = true;
    _error = null;

    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();

    // Notify UI immediately
    notifyListeners();

    // Start heartbeat to maintain connection
    _startHeartbeat();
  }

  // Handle socket disconnection
  void _handleSocketDisconnect() {
    debugPrint('🔌 Socket disconnected - real-time notifications inactive');
    _isSocketConnected = false;
    notifyListeners();

    // Stop heartbeat
    _heartbeatTimer?.cancel();

    // Attempt to reconnect after 5 seconds
    _attemptReconnect();
  }

  // Handle socket errors
  void _handleSocketError(String error) {
    debugPrint('❌ Socket error: $error');
    _isSocketConnected = false;
    _error = 'Real-time connection error: $error';
    notifyListeners();

    // Attempt to reconnect after 3 seconds
    _attemptReconnect();
  }

  // Attempt to reconnect to socket
  void _attemptReconnect() {
    if (_currentUserId == null) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), () async {
      if (!_isSocketConnected && _currentUserId != null) {
        debugPrint('🔄 Attempting to reconnect real-time notifications...');
        try {
          // Get current token for reconnection
          final token = await TokenManager.getToken();
          if (token != null) {
            final socketService = SocketService.instance;
            socketService.connect(_currentUserId!, token);
            debugPrint('✅ Reconnection attempt initiated with valid token');
          } else {
            debugPrint('❌ No valid token found for reconnection');
          }
        } catch (e) {
          debugPrint('❌ Reconnection failed: $e');
        }
      }
    });
  }

  // Disconnect real-time notifications
  void disconnectRealTimeNotifications() {
    try {
      debugPrint('🔌 Disconnecting real-time notifications...');

      final socketService = SocketService.instance;
      socketService.disconnect();

      _isSocketConnected = false;
      _currentUserId = null;

      // Cancel timers
      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();

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

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }
}
