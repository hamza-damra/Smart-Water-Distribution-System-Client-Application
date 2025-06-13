import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../providers/auth_provider.dart';

class UpdateDataProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;

  // Fetch user data to pre-fill the form
  Future<void> fetchUserData(AuthProvider authProvider) async {
    if (authProvider.accessToken == null) {
      _errorMessage = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching user profile data...');

      final apiUrl =
          'https://smart-water-distribution-system-vll8.onrender.com/api/customer/current-user';
      debugPrint('🌐 Profile API URL: $apiUrl');

      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'access_token=${authProvider.accessToken}',
      };

      debugPrint('📤 Headers: ${headers.toString()}');

      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      debugPrint('📥 Response status code: ${response.statusCode}');
      debugPrint('📥 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        debugPrint('📥 Response body: ${response.body}');
        final responseData = json.decode(response.body);

        // The current-user endpoint directly returns the user data object
        // without wrapping it in a success/data structure
        _userData = responseData;
        debugPrint('✅ User data fetched successfully');
        debugPrint('📄 User data keys: ${_userData?.keys.toList()}');
      } else if (response.statusCode == 401) {
        debugPrint('❌ Authentication failed (401): ${response.body}');
        _errorMessage = 'Authentication failed: Invalid or expired token';
      } else {
        debugPrint('❌ Failed to fetch user data: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        _errorMessage = 'Failed to fetch user data: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ Exception while fetching user data: $e');
      _errorMessage = 'Error fetching user data: $e';
    } finally {
      _isLoading = false;
      debugPrint(
        '🔄 User data loading completed. Success: ${_errorMessage == null}',
      );
      notifyListeners();
    }
  }

  // Update user data
  Future<void> updateData({
    required String identityNumber,
    required String name,
    required String email,
    required String phone,
    required AuthProvider authProvider,
  }) async {
    if (authProvider.accessToken == null) {
      throw Exception('Not authenticated');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Uri url = Uri.parse(
      'https://smart-water-distribution-system-vll8.onrender.com/api/customer/update-data',
    );

    debugPrint('🌐 Update data API URL: ${url.toString()}');
    final Map<String, String> body = {
      'identity_number': identityNumber,
      'name': name,
      'email': email,
      'phone': phone,
    };

    try {
      debugPrint('📤 Sending update request with data: ${json.encode(body)}');

      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'access_token=${authProvider.accessToken}',
      };

      debugPrint('📤 Headers: ${headers.toString()}');

      final response = await http.post(
        url,
        body: json.encode(body),
        headers: headers,
      );

      debugPrint('📥 Response status code: ${response.statusCode}');
      debugPrint('📥 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        debugPrint('📥 Response body: ${response.body}');
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          debugPrint('✅ Data updated successfully');

          // Update user data in auth provider
          authProvider.updateUserInfo(name);
          debugPrint('✅ Updated user info in auth provider');

          // Update local user data
          if (_userData != null) {
            _userData!['identity_number'] = identityNumber;
            _userData!['name'] = name;
            _userData!['email'] = email;
            _userData!['phone'] = phone;
            debugPrint('✅ Updated local user data');
          }
        } else {
          debugPrint('❌ Update failed: ${responseData['message']}');
          throw Exception(responseData['message'] ?? 'Failed to update data');
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Authentication failed (401): ${response.body}');
        throw Exception('Authentication failed: Invalid or expired token');
      } else {
        debugPrint('❌ Update failed with status code: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception while updating user data: $e');
      _errorMessage = 'Error: $e';
      throw Exception('Error: $e');
    } finally {
      _isLoading = false;
      debugPrint('🔄 Update data completed. Success: ${_errorMessage == null}');
      notifyListeners();
    }
  }

  // Upload avatar image
  Future<bool> uploadAvatar(File imageFile, AuthProvider authProvider) async {
    if (authProvider.accessToken == null) {
      _errorMessage = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📸 Starting avatar upload...');

      final uri = Uri.parse(
        'https://smart-water-distribution-system-vll8.onrender.com/api/customer/upload-avatar',
      );

      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Cookie': 'access_token=${authProvider.accessToken}',
      });

      // Add file
      var multipartFile = await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
      );
      request.files.add(multipartFile);

      debugPrint('📤 Sending avatar upload request...');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Avatar upload response status: ${response.statusCode}');
      debugPrint('📥 Avatar upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          debugPrint('✅ Avatar uploaded successfully');

          // Update local user data with new avatar URL if provided
          if (responseData['avatarUrl'] != null && _userData != null) {
            _userData!['avatar_url'] = responseData['avatarUrl'];
            debugPrint('✅ Updated local avatar URL');
          }

          return true;
        } else {
          debugPrint('❌ Avatar upload failed: ${responseData['message']}');
          _errorMessage = responseData['message'] ?? 'Failed to upload avatar';
          return false;
        }
      } else {
        debugPrint(
          '❌ Avatar upload failed with status: ${response.statusCode}',
        );
        _errorMessage = 'Failed to upload avatar: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception during avatar upload: $e');
      _errorMessage = 'Error uploading avatar: $e';
      return false;
    } finally {
      _isLoading = false;
      debugPrint('🔄 Avatar upload completed');
      notifyListeners();
    }
  }
}
