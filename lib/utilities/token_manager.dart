import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';

  // Token management
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    debugPrint('💾 Token saved to SharedPreferences');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    debugPrint('🗑️ Token cleared from SharedPreferences');
  }

  // User data management
  static Future<void> saveUserData({
    required String userName,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, userName);
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
    debugPrint('💾 User data saved: $userName (ID: $userId)');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userIdKey);
    debugPrint('🗑️ User data cleared from SharedPreferences');
  }

  // Login state management
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    debugPrint('💾 Login state saved: $isLoggedIn');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Complete session management
  static Future<void> saveCompleteSession({
    required String token,
    required String userName,
    String? userId,
  }) async {
    await saveToken(token);
    await saveUserData(userName: userName, userId: userId);
    await setLoggedIn(true);
    debugPrint('✅ Complete session saved to SharedPreferences');
  }

  static Future<Map<String, String?>> getCompleteSession() async {
    final token = await getToken();
    final userName = await getUserName();
    final userId = await getUserId();
    final isLoggedIn = await TokenManager.isLoggedIn();

    debugPrint(
      '📖 Retrieved session: token=${token != null ? 'present' : 'null'}, user=$userName, loggedIn=$isLoggedIn',
    );

    return {
      'token': token,
      'userName': userName,
      'userId': userId,
      'isLoggedIn': isLoggedIn.toString(),
    };
  }

  static Future<void> clearCompleteSession() async {
    await clearToken();
    await clearUserData();
    await setLoggedIn(false);
    debugPrint('🗑️ Complete session cleared from SharedPreferences');
  }
}
