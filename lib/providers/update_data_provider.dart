import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateDataProvider with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> updateData({
    required String identityNumber,
    required String name,
    required String email,
    required String phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    final Uri url = Uri.parse('https://smart-water-distribution-system.onrender.com/api/customer/update-data');
    final Map<String, String> body = {
      'identity_number': identityNumber,
      'name': name,
      'email': email,
      'phone': phone,
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
        throw Exception('Failed to update data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}