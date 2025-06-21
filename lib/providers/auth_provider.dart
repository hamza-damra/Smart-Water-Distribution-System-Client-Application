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
        debugPrint(
          '🔔 Initializing real-time notifications with valid credentials',
        );

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
      debugPrint(
        '❌ Cannot initialize real-time notifications: Missing credentials',
      );
      if (_accessToken == null) debugPrint('  - Missing access token');
      if (_userId == null) debugPrint('  - Missing user ID');
    }
  }

  /// Load any previously saved token from local storage and validate it.
  Future<void> initialize() async {
    try {
      debugPrint('🔄 Initializing AuthProvider...');

      // Get complete session data from storage
      final sessionData = await TokenManager.getCompleteSession();
      final token = sessionData['token'];
      final userName = sessionData['userName'];
      final userId = sessionData['userId'];
      final isLoggedIn = sessionData['isLoggedIn'] == 'true';

      debugPrint('📖 Session data retrieved:');
      debugPrint('   Token: ${token != null ? 'present' : 'null'}');
      debugPrint('   User: $userName');
      debugPrint('   User ID: $userId');
      debugPrint('   Is Logged In: $isLoggedIn');

      if (token != null && isLoggedIn) {
        _accessToken = token;
        _userName = userName;
        _userId = userId;

        debugPrint('🔑 Found saved session, validating token...');

        // TEMPORARY: Skip token validation to test if this is the issue
        // Comment out the validation line to see if login state persists
        // await _validateTokenAndFetchUserInfo();

        // Instead, just trust the saved session for now
        debugPrint('⚠️ TEMPORARY: Skipping token validation for debugging');
        debugPrint('✅ Using saved session without validation');
      } else {
        debugPrint('🔑 No valid saved session found');
        await TokenManager.clearCompleteSession();
      }
    } catch (e) {
      debugPrint('❌ Error during initialization: $e');
      // Clear invalid session
      await logout();
    }
    notifyListeners();
  }

  /// Validate the current token and fetch user information
  Future<void> _validateTokenAndFetchUserInfo() async {
    if (_accessToken == null) {
      debugPrint('❌ Cannot validate token: _accessToken is null');
      return;
    }

    try {
      debugPrint('🔍 Validating token with API...');
      debugPrint('🌐 API URL: ${Constants.apiUrl}/customer/current-user');
      debugPrint('🔑 Token preview: ${_accessToken!.substring(0, 15)}...');

      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/customer/current-user'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📡 Token validation response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📊 Parsed response data: $data');

        if (data['success'] == true && data['user'] != null) {
          _userName = data['user']['name'] ?? data['user']['fullName'];
          _userId = data['user']['_id'];

          // Update stored session data with validated information
          await TokenManager.saveCompleteSession(
            token: _accessToken!,
            userName: _userName!,
            userId: _userId,
          );

          debugPrint('✅ Token validated successfully for user: $_userName');
        } else {
          debugPrint(
            '❌ Invalid token response - success: ${data['success']}, user: ${data['user']}',
          );
          await logout();
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Token expired or invalid (401 Unauthorized)');
        await logout();
      } else {
        debugPrint(
          '❌ Token validation failed with status: ${response.statusCode}',
        );
        debugPrint('❌ Response body: ${response.body}');
        // Don't logout on network errors, keep the token for retry
        debugPrint('⚠️ Keeping token for retry due to network/server error');
      }
    } catch (e) {
      debugPrint('❌ Token validation error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      // Don't logout on network errors, keep the token for retry
      debugPrint('⚠️ Keeping token for retry due to network error');
    }
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

              // Save token locally for later use (temporary, will be updated with complete session)
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
                  _userId =
                      responseData['data']['_id']?.toString() ??
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

                debugPrint('👤 User info extracted: $_userName (ID: $_userId)');

                // Save complete session data
                await TokenManager.saveCompleteSession(
                  token: tokenValue,
                  userName: _userName!,
                  userId: _userId,
                );
                debugPrint('✅ Complete session saved to SharedPreferences');
              } catch (e) {
                debugPrint('❌ Error parsing user data: $e');
                _userName = 'User';
                _userId = null;

                // Still save session even with minimal user data
                await TokenManager.saveCompleteSession(
                  token: tokenValue,
                  userName: _userName!,
                  userId: _userId,
                );
                debugPrint('✅ Session saved with minimal user data');
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

  /// Check if the current session is still valid
  Future<bool> isSessionValid() async {
    if (_accessToken == null) return false;

    try {
      await _validateTokenAndFetchUserInfo();
      return _accessToken != null; // Will be null if validation failed
    } catch (e) {
      debugPrint('❌ Session validation error: $e');
      return false;
    }
  }

  /// Clear the saved token and log out the user.
  Future<void> logout() async {
    // Note: Real-time notifications disconnection should be handled
    // in the UI layer using logoutWithContext() method

    debugPrint('🚪 Logging out user...');
    _accessToken = null;
    _userName = null;
    _userId = null;

    // Clear complete session from SharedPreferences
    await TokenManager.clearCompleteSession();
    debugPrint('✅ User logged out and session cleared');

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

        // Save complete session data
        await TokenManager.saveCompleteSession(
          token: data['token'],
          userName: _userName!,
          userId: _userId,
        );
        debugPrint('✅ Registration successful, session saved');

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }
}
