import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mytank/models/notification_model.dart';
import 'package:mytank/utilities/constants.dart';

class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  bool _isConnected = false;
  String? _userId;

  // Singleton pattern
  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal();

  bool get isConnected => _isConnected;
  String? get userId => _userId;

  // Callback functions for handling events
  Function(NotificationModel)? onNewNotification;
  Function()? onConnect;
  Function()? onDisconnect;
  Function(String)? onError;

  /// Initialize and connect to the Socket.IO server
  Future<void> connect(String userId, String token) async {
    try {
      debugPrint('🔌 Initializing Socket.IO connection...');
      debugPrint('🔌 Server URL: ${Constants.socketUrl}');
      debugPrint('🔌 User ID: $userId');

      _userId = userId;

      // Disconnect existing connection if any
      await disconnect();

      // Configure socket options
      _socket = io.io(
        Constants.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Enable both transports
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build(),
      );

      // Set up event listeners
      _setupEventListeners();

      // Connect to the server
      _socket!.connect();

      debugPrint('✅ Socket.IO connection initiated');
    } catch (e) {
      debugPrint('❌ Error initializing Socket.IO: $e');
      onError?.call('Failed to initialize socket connection: $e');
    }
  }

  /// Set up all socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection successful
    _socket!.on('connect', (data) {
      _isConnected = true;
      debugPrint('✅ Socket.IO connected successfully');
      debugPrint('🔌 Socket ID: ${_socket!.id}');

      // Join user-specific room for targeted notifications
      if (_userId != null) {
        _socket!.emit('join_user_room', {'userId': _userId});
        debugPrint('🏠 Joined user room: $_userId');
      }

      onConnect?.call();
    });

    // Connection failed
    _socket!.on('connect_error', (error) {
      _isConnected = false;
      debugPrint('❌ Socket.IO connection error: $error');
      onError?.call('Connection error: $error');
    });

    // Disconnected from server
    _socket!.on('disconnect', (reason) {
      _isConnected = false;
      debugPrint('🔌 Socket.IO disconnected: $reason');
      onDisconnect?.call();
    });

    // Reconnection attempt
    _socket!.on('reconnect_attempt', (attemptNumber) {
      debugPrint('🔄 Socket.IO reconnection attempt: $attemptNumber');
    });

    // Reconnection successful
    _socket!.on('reconnect', (attemptNumber) {
      _isConnected = true;
      debugPrint('✅ Socket.IO reconnected after $attemptNumber attempts');

      // Rejoin user room after reconnection
      if (_userId != null) {
        _socket!.emit('join_user_room', {'userId': _userId});
        debugPrint('🏠 Rejoined user room: $_userId');
      }

      onConnect?.call();
    });

    // Listen for new notifications
    _socket!.on('new_notification', (data) {
      debugPrint('🔔 Received new notification: $data');

      try {
        // Parse the incoming data structure
        // Expected format: { "userId": "...", "notification": { ... } }
        if (data is Map<String, dynamic>) {
          final String? receivedUserId = data['userId']?.toString();
          final Map<String, dynamic>? notificationData =
              data['notification'] as Map<String, dynamic>?;

          debugPrint('🔍 Received userId: $receivedUserId');
          debugPrint('🔍 Current userId: $_userId');
          debugPrint('🔍 Notification data: $notificationData');

          // Check if this notification is for the current user
          if (receivedUserId == _userId && notificationData != null) {
            // Create NotificationModel from received data
            final notification = NotificationModel.fromJson(notificationData);
            debugPrint('✅ Parsed notification: ${notification.message}');
            debugPrint('✅ Notification ID: ${notification.id}');
            debugPrint('✅ Created at: ${notification.createdAt}');

            // Trigger callback to update UI
            onNewNotification?.call(notification);
          } else if (receivedUserId != _userId) {
            debugPrint(
              'ℹ️ Notification not for current user ($receivedUserId != $_userId)',
            );
          } else {
            debugPrint('❌ Notification data is null or invalid');
          }
        } else {
          debugPrint('❌ Invalid data format received: ${data.runtimeType}');
        }
      } catch (e) {
        debugPrint('❌ Error parsing notification: $e');
        debugPrint('❌ Raw data: $data');
        onError?.call('Failed to parse notification: $e');
      }
    });

    // Listen for other custom events if needed
    _socket!.on('notification_read', (data) {
      debugPrint('📖 Notification marked as read: $data');
      // Handle notification read status updates if needed
    });
  }

  /// Disconnect from the Socket.IO server
  Future<void> disconnect() async {
    if (_socket != null) {
      debugPrint('🔌 Disconnecting Socket.IO...');

      // Leave user room before disconnecting
      if (_userId != null) {
        _socket!.emit('leave_user_room', {'userId': _userId});
        debugPrint('🏠 Left user room: $_userId');
      }

      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _userId = null;

      debugPrint('✅ Socket.IO disconnected and disposed');
    }
  }

  /// Send a custom event to the server
  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
      debugPrint('📤 Emitted event: $event with data: $data');
    } else {
      debugPrint('❌ Cannot emit event: Socket not connected');
    }
  }

  /// Check connection status
  void checkConnection() {
    if (_socket != null) {
      debugPrint('🔍 Socket connection status:');
      debugPrint('  - Connected: $_isConnected');
      debugPrint('  - Socket ID: ${_socket!.id}');
      debugPrint('  - User ID: $_userId');
    } else {
      debugPrint('🔍 Socket is not initialized');
    }
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _instance = null;
  }
}
