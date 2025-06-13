// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mytank/utilities/token_manager.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _accessToken; // We'll store the cookie token here
  String? _userName;
  String? _userId;

  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  String? get userName => _userName;
  String? get userId => _userId;
  bool get isAuthenticated => _accessToken != null;

  // Update user information
  void updateUserInfo(String name) {
    _userName = name;
    notifyListeners();
  }

  // Update user ID (useful when fetching from API)
  void updateUserId(String id) {
    _userId = id;
    notifyListeners();
    debugPrint('✅ User ID updated: $_userId');
  }

  // Initialize real-time notifications (to be called after login)
  void initializeRealTimeNotifications(BuildContext context) {
    debugPrint('🔔 Attempting to initialize real-time notifications...');
    debugPrint('🔔 Access token available: ${_accessToken != null}');
    debugPrint('🔔 User ID available: ${_userId != null}');
    debugPrint('🔔 User ID value: $_userId');
    
    if (_accessToken != null && _userId != null) {
      try {
        debugPrint('🔔 Initializing real-time notifications with valid credentials');
        
        // Get notification provider and initialize real-time notifications
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );

        notificationProvider.initializeRealTimeNotifications(
          _userId!,
          _accessToken!,
        );
        debugPrint('✅ Real-time notifications initialized for user: $_userId');
      } catch (e) {
        debugPrint('❌ Error initializing real-time notifications: $e');
      }
    } else {
      debugPrint('❌ Cannot initialize real-time notifications: Missing credentials');
      if (_accessToken == null) debugPrint('  - Missing access token');
      if (_userId == null) debugPrint('  - Missing user ID');
    }
  }

  /// Load any previously saved token from local storage.
  Future<void> initialize() async {
    _accessToken = await TokenManager.getToken();
    notifyListeners();
  }

  /// Perform login, parse the `access_token` from the Set-Cookie header.
  Future<void> login(String identityNumber, String password) async {
    _isLoading = true;
    notifyListeners();

    final Uri url = Uri.parse('${Constants.apiUrl}/customer/login');

    debugPrint('🌐 Using login URL: ${url.toString()}');
    final Map<String, String> body = {
      'identity_number': identityNumber,
      'password': password,
    };

    try {
      debugPrint('🔑 Attempting login for identity number: $identityNumber');
      debugPrint('🌐 Login URL: ${url.toString()}');

      final response = await http.post(
        url,
        body: json.encode(body),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📥 Login response status code: ${response.statusCode}');
      debugPrint('📥 Login response headers: ${response.headers}');

      if (response.statusCode == 200) {
        debugPrint('✅ Login successful');

        // The server sets a cookie like "access_token=eyJhbGc..."
        final setCookieHeader = response.headers['set-cookie'];
        debugPrint('🍪 Set-Cookie header: ${setCookieHeader ?? "Not found"}');

        if (setCookieHeader != null) {
          // Use a regex to extract the access_token=... part
          final match = RegExp(
            r'access_token=([^;]+)',
          ).firstMatch(setCookieHeader);

          if (match != null) {
            final tokenValue = match.group(1);
            if (tokenValue != null) {
              _accessToken = tokenValue;

              // Log token details (partial for security)
              final previewLength =
                  tokenValue.length > 15 ? 15 : tokenValue.length;
              debugPrint(
                '🔑 Token extracted (preview): ${tokenValue.substring(0, previewLength)}...',
              );
              debugPrint('🔑 Token length: ${tokenValue.length} characters');

              // Save token locally for later use
              await TokenManager.saveToken(tokenValue);
              debugPrint('💾 Token saved to local storage');

              // Parse response body to get user info
              try {
                final responseData = json.decode(response.body);
                debugPrint(
                  '📄 Response data keys: ${responseData.keys.toList()}',
                );

                // Check different possible response structures
                if (responseData['data'] != null) {
                  // If response has 'data' wrapper
                  _userName = responseData['data']['name'] ?? 'User';
                  _userId = responseData['data']['_id']?.toString() ?? 
                           responseData['data']['id']?.toString();
                } else if (responseData['_id'] != null) {
                  // If response is the user object directly
                  _userName = responseData['name'] ?? 'User';
                  _userId = responseData['_id']?.toString();
                } else {
                  // Fallback
                  _userName = 'User';
                  _userId = null;
                }
                
                debugPrint(
                  '👤 User info extracted: $_userName (ID: $_userId)',
                );
              } catch (e) {
                debugPrint('❌ Error parsing user data: $e');
                _userName = 'User';
                _userId = null;
              }
            } else {
              debugPrint('❌ Token value is null after regex match');
            }
          } else {
            debugPrint('❌ No regex match for access_token in cookie');
          }
        } else {
          debugPrint('❌ Set-Cookie header not found in response');
        }

        notifyListeners();
      } else if (response.statusCode == 401) {
        debugPrint('❌ Login failed: Invalid credentials (401)');
        debugPrint('❌ Response body: ${response.body}');
        throw Exception('Login Failed: Invalid credentials');
      } else {
        debugPrint('❌ Login failed with status code: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        throw Exception('Login Failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Login exception: $e');
      throw Exception('Login Failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear the saved token and log out the user.
  Future<void> logout() async {
    // Note: Real-time notifications disconnection should be handled
    // in the UI layer using logoutWithContext() method

    _accessToken = null;
    _userName = null;
    _userId = null;
    await TokenManager.clearToken();
    notifyListeners();
  }

  /// Logout with context for proper cleanup
  Future<void> logoutWithContext(BuildContext context) async {
    try {
      // Disconnect real-time notifications
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notificationProvider.disconnectRealTimeNotifications();
      debugPrint('✅ Real-time notifications disconnected during logout');
    } catch (e) {
      debugPrint('❌ Error disconnecting real-time notifications: $e');
    }

    // Perform regular logout
    await logout();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['token'];
        _userName = data['user']['name'];
        _userId = data['user']['_id'];
        await TokenManager.saveToken(data['token']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }
}
