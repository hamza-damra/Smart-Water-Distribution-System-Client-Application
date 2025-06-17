import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../models/main_tank_model.dart';
import '../models/ultrasonic_sensor_model.dart';
import '../services/ultrasonic_sensor_service.dart';
import '../utilities/constants.dart';

class MainTankProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isSensorLoading = false;
  String? _errorMessage;
  String? _sensorErrorMessage;
  MainTank? _mainTank;
  UltrasonicSensorData? _sensorData;

  bool get isLoading => _isLoading;
  bool get isSensorLoading => _isSensorLoading;
  String? get errorMessage => _errorMessage;
  String? get sensorErrorMessage => _sensorErrorMessage;
  MainTank? get mainTank => _mainTank;
  UltrasonicSensorData? get sensorData => _sensorData;

  // Check if there's an error
  bool get hasError => _errorMessage != null;

  // Check if user has no tank data (not an error, just no data available)
  bool get hasNoTankData =>
      !_isLoading && _errorMessage == null && _mainTank == null;

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

      final apiUrl = '${Constants.apiUrl}/customer/current-user';
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

  // Fetch ultrasonic sensor data for the main tank
  Future<void> fetchSensorData(AuthProvider authProvider) async {
    if (_mainTank == null) {
      _sensorErrorMessage = 'No tank data available';
      notifyListeners();
      return;
    }

    _isSensorLoading = true;
    _sensorErrorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching sensor data for tank: ${_mainTank!.id}');

      final sensorData =
          await UltrasonicSensorService.fetchTankSensorDataWithRetry(
            tankId: _mainTank!.id,
            authProvider: authProvider,
          );

      _sensorData = sensorData;
      debugPrint('✅ Sensor data fetched successfully');
      debugPrint('📄 Estimated Volume: ${sensorData.estimatedVolumeLiters} L');
    } catch (e) {
      debugPrint('❌ Failed to fetch sensor data: $e');
      _sensorErrorMessage = e.toString();
    } finally {
      _isSensorLoading = false;
      notifyListeners();
    }
  }

  // Refresh main tank data
  Future<void> refreshMainTankData(AuthProvider authProvider) async {
    await fetchMainTankData(authProvider);
  }

  // Refresh both main tank and sensor data
  Future<void> refreshAllData(AuthProvider authProvider) async {
    await fetchMainTankData(authProvider);
    if (_mainTank != null) {
      await fetchSensorData(authProvider);
    }
  }

  // Clear main tank data on logout
  void clearMainTankData() {
    _mainTank = null;
    _sensorData = null;
    _errorMessage = null;
    _sensorErrorMessage = null;
    notifyListeners();
  }

  // Get water level as percentage (0.0 to 1.0)
  // Uses sensor data if available, otherwise falls back to tank data
  double get waterLevelPercentage {
    if (_mainTank == null || _mainTank!.maxCapacity <= 0) return 0.0;

    // Use sensor data if available and valid
    if (_sensorData != null && _sensorData!.estimatedVolumeLiters > 0) {
      return (_sensorData!.estimatedVolumeLiters / _mainTank!.maxCapacity)
          .clamp(0.0, 1.0);
    }

    // Fallback to tank current level
    return (_mainTank!.currentLevel / _mainTank!.maxCapacity).clamp(0.0, 1.0);
  }

  // Get current water volume in liters
  // Uses sensor data if available, otherwise falls back to tank data
  double get currentWaterVolume {
    if (_sensorData != null && _sensorData!.estimatedVolumeLiters > 0) {
      return _sensorData!.estimatedVolumeLiters;
    }
    return _mainTank?.currentLevel ?? 0.0;
  }

  // Check if sensor data is available and being used
  bool get isUsingSensorData {
    return _sensorData != null && _sensorData!.estimatedVolumeLiters > 0;
  }

  // Get data source indicator
  String get dataSource {
    return isUsingSensorData ? 'Live Sensor' : 'Tank Data';
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

  // Format current water volume for display
  String get formattedCurrentVolume {
    final volume = currentWaterVolume;
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K L';
    }
    return '${volume.toStringAsFixed(1)} L';
  }

  // Get sensor status text
  String get sensorStatus {
    if (_isSensorLoading) return 'Reading...';
    if (_sensorErrorMessage != null) return 'Sensor Error';
    if (_sensorData == null) return 'No Sensor Data';
    if (_sensorData!.isStable) return 'Stable';
    return 'Reading';
  }

  // Get sensor status color
  Color get sensorStatusColor {
    if (_isSensorLoading) return Colors.blue;
    if (_sensorErrorMessage != null) return Colors.red;
    if (_sensorData == null) return Colors.grey;
    if (_sensorData!.isStable) return Colors.green;
    return Colors.orange;
  }

  // Check if any loading is in progress
  bool get isAnyLoading => _isLoading || _isSensorLoading;

  // Check if sensor data has errors
  bool get hasSensorError => _sensorErrorMessage != null;

  // Get combined error message
  String? get combinedErrorMessage {
    if (_errorMessage != null && _sensorErrorMessage != null) {
      return '$_errorMessage\nSensor: $_sensorErrorMessage';
    }
    return _errorMessage ?? _sensorErrorMessage;
  }
}
