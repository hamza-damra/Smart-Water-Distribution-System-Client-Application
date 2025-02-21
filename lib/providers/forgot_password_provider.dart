import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordProvider with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> submitEmail(String email) async {
    _isLoading = true;
    notifyListeners();

    final Uri url = Uri.parse('https://smart-water-distribution-system.onrender.com/api/customer/forgot-password');
    final Map<String, String> body = {
      'email': email,
    };

    try {
      final response = await http.post(
        url,
        body: json.encode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        throw Exception('Failed to send reset email');
      }
    } catch (e) {
      throw Exception('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}