import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mytank/models/user_model.dart';
import 'package:mytank/utilities/token_manager.dart';
import 'package:mytank/utilities/constants.dart';

class UserService {
  // Get the current user data
  static Future<User> getCurrentUser() async {
    try {
      debugPrint('🔍 Fetching current user data from API...');

      // Get token using TokenManager
      final String? token = await TokenManager.getToken();

      if (token == null) {
        debugPrint('❌ Authentication token not found in storage');
        throw Exception('Authentication token not found');
      }

      // Log token details for debugging
      final previewLength = token.length > 15 ? 15 : token.length;
      debugPrint(
        '🔑 Token found (preview): ${token.substring(0, previewLength)}...',
      );
      debugPrint('🔑 Token length: ${token.length} characters');

      // Prepare headers with token as cookie
      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'access_token=$token',
      };

      debugPrint(
        '📤 Sending request to: ${Constants.apiUrl}/customer/current-user',
      );
      debugPrint('📤 Headers: ${headers.toString()}');

      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/customer/current-user'),
        headers: headers,
      );

      debugPrint('📥 Response status code: ${response.statusCode}');
      debugPrint('📥 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        debugPrint('✅ Successfully received user data');
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('📄 Response data keys: ${data.keys.toList()}');
        return User.fromJson(data);
      } else if (response.statusCode == 401) {
        debugPrint('❌ Authentication failed (401): ${response.body}');
        throw Exception('Authentication failed: Invalid or expired token');
      } else {
        debugPrint('❌ Failed to load user: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');
      rethrow;
    }
  }
}
