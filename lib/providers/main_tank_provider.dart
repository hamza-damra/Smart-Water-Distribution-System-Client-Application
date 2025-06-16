import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../models/main_tank_model.dart';

class MainTankProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  MainTank? _mainTank;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MainTank? get mainTank => _mainTank;

  // Check if there's an error
  bool get hasError => _errorMessage != null;

  // Check if user has no tank data (not an error, just no data available)
  bool get hasNoTankData => !_isLoading && _errorMessage == null && _mainTank == null;

  // Fetch main tank data from current user endpoint
  Future<void> fetchMainTankData(AuthProvider authProvider) async {
    if (authProvider.accessToken == null) {
      _errorMessage = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching main tank data...');

      final apiUrl =
          'https://smart-water-distribution-system-vll8.onrender.com/api/customer/current-user';
      debugPrint('🌐 API URL: $apiUrl');

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

        // Extract main tank data from the response
        if (responseData['main_tank'] != null) {
          _mainTank = MainTank.fromJson(responseData['main_tank']);
          debugPrint('✅ Main tank data fetched successfully');
          debugPrint('📄 Tank ID: ${_mainTank?.id}');
          debugPrint('📄 Current Level: ${_mainTank?.currentLevel}');
          debugPrint('📄 Max Capacity: ${_mainTank?.maxCapacity}');
        } else {
          debugPrint('❌ No main tank data found in response');
          _errorMessage = 'No main tank data available';
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Authentication failed (401): ${response.body}');
        _errorMessage = 'Authentication failed: Invalid or expired token';
      } else {
        debugPrint('❌ Failed to fetch main tank data: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        _errorMessage =
            'Failed to fetch main tank data: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ Exception while fetching main tank data: $e');
      _errorMessage = 'Error fetching main tank data: $e';
    } finally {
      _isLoading = false;
      debugPrint(
        '🔄 Main tank data loading completed. Success: ${_errorMessage == null}',
      );
      notifyListeners();
    }
  }

  // Refresh main tank data
  Future<void> refreshMainTankData(AuthProvider authProvider) async {
    await fetchMainTankData(authProvider);
  }

  // Clear main tank data on logout
  void clearMainTankData() {
    _mainTank = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Get water level as percentage (0.0 to 1.0)
  double get waterLevelPercentage {
    if (_mainTank == null || _mainTank!.maxCapacity <= 0) return 0.0;
    return (_mainTank!.currentLevel / _mainTank!.maxCapacity).clamp(0.0, 1.0);
  }

  // Get status text based on water level
  String get statusText {
    final percentage = waterLevelPercentage;
    if (percentage >= 0.75) return 'High';
    if (percentage >= 0.25) return 'Medium';
    return 'Low';
  }

  // Get status color based on water level
  Color get statusColor {
    final percentage = waterLevelPercentage;
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.25) return Colors.orange;
    return Colors.red;
  }

  // Get current month usage
  double get currentMonthUsage {
    if (_mainTank?.amountPerMonth == null ||
        _mainTank!.amountPerMonth['days'] == null) {
      return 0.0;
    }

    double total = 0;
    Map<String, dynamic> days = _mainTank!.amountPerMonth['days'];
    days.forEach((day, amount) {
      total += (amount is num) ? amount.toDouble() : 0.0;
    });

    return total;
  }

  // Get current day usage
  double get currentDayUsage {
    if (_mainTank?.amountPerMonth == null ||
        _mainTank!.amountPerMonth['days'] == null) {
      return 0.0;
    }

    final now = DateTime.now();
    final currentDay = now.day.toString();
    Map<String, dynamic> days = _mainTank!.amountPerMonth['days'];

    final usage = days[currentDay];
    return (usage is num) ? usage.toDouble() : 0.0;
  }

  // Get current week usage (last 7 days)
  double get currentWeekUsage {
    if (_mainTank?.amountPerMonth == null ||
        _mainTank!.amountPerMonth['days'] == null) {
      return 0.0;
    }

    final now = DateTime.now();
    final currentDay = now.day;
    Map<String, dynamic> days = _mainTank!.amountPerMonth['days'];

    double total = 0;
    for (int i = 0; i < 7; i++) {
      final day = currentDay - i;
      if (day > 0) {
        final dayStr = day.toString();
        final usage = days[dayStr];
        total += (usage is num) ? usage.toDouble() : 0.0;
      }
    }

    return total;
  }

  // Get daily average usage for current month
  double get dailyAverageUsage {
    if (_mainTank?.amountPerMonth == null ||
        _mainTank!.amountPerMonth['days'] == null) {
      return 0.0;
    }

    final now = DateTime.now();
    final currentDay = now.day;
    final totalUsage = currentMonthUsage;

    return currentDay > 0 ? totalUsage / currentDay : 0.0;
  }

  // Get usage status based on daily average
  String get usageStatus {
    final dailyAvg = dailyAverageUsage;

    // These thresholds can be adjusted based on typical usage patterns
    if (dailyAvg >= 200) return 'High';
    if (dailyAvg >= 100) return 'Medium';
    return 'Low';
  }

  // Get usage status color
  Color get usageStatusColor {
    final status = usageStatus;
    switch (status) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // Format usage amount for display
  String formatUsage(double usage) {
    if (usage >= 1000) {
      return '${(usage / 1000).toStringAsFixed(1)}K L';
    }
    return '${usage.toStringAsFixed(0)} L';
  }

  // Get city name
  String get cityName {
    return _mainTank?.city ?? 'Unknown';
  }

  // Calculate tank volume in liters
  double get tankVolumeInLiters {
    if (_mainTank == null) return 0.0;

    // Volume = π * r² * h (in cubic meters, then convert to liters)
    final volumeM3 =
        3.14159 * (_mainTank!.radius * _mainTank!.radius) * _mainTank!.height;

    return volumeM3 * 1000; // Convert to liters
  }
}
