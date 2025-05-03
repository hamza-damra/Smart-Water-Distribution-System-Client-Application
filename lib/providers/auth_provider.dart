// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mytank/utilities/token_manager.dart';
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

  /// Load any previously saved token from local storage.
  Future<void> initialize() async {
    _accessToken = await TokenManager.getToken();
    notifyListeners();
  }

  /// Perform login, parse the `access_token` from the Set-Cookie header.
  Future<void> login(String identityNumber, String password) async {
    _isLoading = true;
    notifyListeners();

    final Uri url = Uri.parse(
      'https://smart-water-distribution-system-q6x7.onrender.com/api/customer/login',
    );

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

                if (responseData['data'] != null) {
                  _userName = responseData['data']['name'] ?? 'User';
                  _userId = responseData['data']['id']?.toString();
                  debugPrint(
                    '👤 User info extracted: $_userName (ID: $_userId)',
                  );
                }
              } catch (e) {
                debugPrint('❌ Error parsing user data: $e');
                _userName = 'User';
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
    _accessToken = null;
    _userName = null;
    _userId = null;
    await TokenManager.clearToken();
    notifyListeners();
  }
}
