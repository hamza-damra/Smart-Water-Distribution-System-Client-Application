// bills_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/bill_model.dart';
import 'auth_provider.dart';
import 'package:mytank/utilities/token_manager.dart';

class BillsProvider with ChangeNotifier {
  List<Bill> _bills = [];
  bool _isLoading = false;
  String? _error;

  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get total unpaid bills amount
  double get totalUnpaidAmount {
    double total = 0;
    for (var bill in _bills) {
      if (bill.status == 'Unpaid') {
        total += bill.totalPrice;
      }
    }
    return total;
  }

  // Get total bills margin (sum of all bills)
  double get totalBillsMargin {
    double total = 0;
    for (var bill in _bills) {
      total += bill.totalPrice;
    }
    return total;
  }

  // Fetch bills from API
  Future<void> fetchBills(AuthProvider authProvider) async {
    if (authProvider.accessToken == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching bills from API...');

      // Get token using TokenManager for consistency
      final String? token = await TokenManager.getToken();

      if (token == null) {
        debugPrint('❌ Authentication token not found in storage');
        throw Exception('Authentication token not found');
      }

      final apiUrl =
          'https://smart-water-distribution-system-q6x7.onrender.com/api/bill/my-bills';
      debugPrint('🌐 Bills API URL: $apiUrl');

      // Prepare headers with token as cookie
      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'access_token=$token',
      };

      debugPrint('📤 Headers: ${headers.toString()}');

      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      debugPrint('📥 Response status code: ${response.statusCode}');
      debugPrint('📥 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        debugPrint('✅ Successfully received bills data');
        final List<dynamic> billsJson = json.decode(response.body);
        debugPrint('📄 Number of bills received: ${billsJson.length}');
        _bills = billsJson.map((json) => Bill.fromJson(json)).toList();
        debugPrint('✅ Bills data processed successfully');
      } else if (response.statusCode == 401) {
        debugPrint('❌ Authentication failed (401): ${response.body}');
        _error = 'Authentication failed: Invalid or expired token';
      } else {
        debugPrint('❌ Failed to load bills: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        _error = 'Failed to load bills: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ Exception while fetching bills: $e');
      _error = 'Error fetching bills: $e';
    } finally {
      _isLoading = false;
      debugPrint('🔄 Bills loading completed. Success: ${_error == null}');
      notifyListeners();
    }
  }

  // Clear bills data on logout
  void clearBills() {
    _bills = [];
    _error = null;
    notifyListeners();
  }
}
