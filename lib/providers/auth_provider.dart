// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mytank/utilities/token_manager.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _accessToken; // We'll store the cookie token here

  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;

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
      'https://smart-water-distribution-system.onrender.com/api/customer/login',
    );
    final Map<String, String> body = {
      'identity_number': identityNumber,
      'password': password,
    };

    try {
      final response = await http.post(
        url,
        body: json.encode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // The server sets a cookie like "access_token=eyJhbGc..."
        final setCookieHeader = response.headers['set-cookie'];
        if (setCookieHeader != null) {
          // Use a regex to extract the access_token=... part
          final match =
          RegExp(r'access_token=([^;]+)').firstMatch(setCookieHeader);
          if (match != null) {
            final tokenValue = match.group(1);
            if (tokenValue != null) {
              _accessToken = tokenValue;
              // Save token locally for later use
              await TokenManager.saveToken(tokenValue);
            }
          }
        }

        notifyListeners();
      } else if (response.statusCode == 401) {
        throw Exception('Login Failed: Invalid credentials');
      } else {
        throw Exception('Login Failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login Failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear the saved token and log out the user.
  Future<void> logout() async {
    _accessToken = null;
    await TokenManager.clearToken();
    notifyListeners();
  }
}
