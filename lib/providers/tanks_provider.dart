// tanks_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/tank_model.dart';

class TanksProvider with ChangeNotifier {
  List<Tank> _tanks = [];
  List<Tank> get tanks => _tanks;

  Future<void> fetchTanks(BuildContext context) async {
    const url =
        'https://smart-water-distribution-system-q6x7.onrender.com/api/tank/customer-tanks';

    try {
      // 1) Retrieve the token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      // 2) Send the GET request with the token as a Cookie
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': 'access_token=$token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        _tanks = data.map((tankJson) => Tank.fromJson(tankJson)).toList();
        notifyListeners();
      } else {
        throw Exception(
          'Failed to load tanks. Status code: ${response.statusCode}',
        );
      }
    } catch (error) {
      debugPrint('Error in fetchTanks(): $error');
      rethrow;
    }
  }
}
