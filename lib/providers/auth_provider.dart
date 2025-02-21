import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mytank/utilities/token_manager.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _token;

  bool get isLoading => _isLoading;
  String? get token => _token;

  bool get isAuthenticated => _token != null;

  Future<void> initialize() async {
    _token = await TokenManager.getToken();
    notifyListeners();
  }

  Future<void> login(String identityNumber, String password) async {
    _isLoading = true;
    notifyListeners();

    final Uri url = Uri.parse('https://smart-water-distribution-system.onrender.com/api/customer/login');
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
        final Map<String, dynamic> data = json.decode(response.body);
        _token = data['token'];
        await TokenManager.saveToken(_token!);
        notifyListeners();
      } else if (response.statusCode == 401) {
        throw Exception('Login Failed: Invalid credentials');
      } else {
        throw Exception('Login Failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login Failed: Invalid credentials');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    await TokenManager.clearToken();
    notifyListeners();
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    final Uri url = Uri.parse('https://smart-water-distribution-system.onrender.com/api/customer/update-password');
    final Map<String, String> body = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };

    try {
      final response = await http.post(
        url,
        body: json.encode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update password');
      }
    } catch (e) {
      throw Exception('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}