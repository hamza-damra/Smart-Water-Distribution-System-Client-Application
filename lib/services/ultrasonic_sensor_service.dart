// ultrasonic_sensor_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/ultrasonic_sensor_model.dart';
import '../providers/auth_provider.dart';
import '../utilities/constants.dart';

class UltrasonicSensorService {
  /// Fetch ultrasonic sensor data for a specific tank
  ///
  /// [tankId] - The ID of the tank to fetch sensor data for
  /// [authProvider] - The authentication provider containing the access token
  ///
  /// Returns [UltrasonicSensorData] if successful, throws exception if failed
  static Future<UltrasonicSensorData> fetchTankSensorData({
    required String tankId,
    required AuthProvider authProvider,
  }) async {
    if (authProvider.accessToken == null) {
      throw Exception('Authentication token not available');
    }

    if (tankId.isEmpty) {
      throw Exception('Tank ID cannot be empty');
    }

    try {
      debugPrint('🔍 Fetching ultrasonic sensor data for tank: $tankId');

      final apiUrl =
          '${Constants.baseUrl}/api/tank/tank-value-ultrasonic/$tankId';
      debugPrint('🌐 Sensor API URL: $apiUrl');

      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'access_token=${authProvider.accessToken}',
      };

      debugPrint('📤 Headers: ${headers.toString()}');

      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout - please check your internet connection',
              );
            },
          );

      debugPrint('📥 Response status code: ${response.statusCode}');
      debugPrint('📥 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        debugPrint('📥 Response body: ${response.body}');

        final Map<String, dynamic> responseData = json.decode(response.body);
        final sensorData = UltrasonicSensorData.fromJson(responseData);

        debugPrint('✅ Sensor data parsed successfully');
        debugPrint('📄 Average Distance: ${sensorData.averageDistanceCm} cm');
        debugPrint(
          '📄 Estimated Volume: ${sensorData.estimatedVolumeLiters} L',
        );
        debugPrint('📄 Water Height: ${sensorData.waterHeightCm} cm');
        debugPrint('📄 Readings Count: ${sensorData.readings.length}');

        return sensorData;
      } else if (response.statusCode == 401) {
        debugPrint('❌ Authentication failed (401): ${response.body}');
        throw Exception('Authentication failed: Invalid or expired token');
      } else if (response.statusCode == 404) {
        debugPrint('❌ Tank not found (404): ${response.body}');
        throw Exception('Tank not found or no sensor data available');
      } else if (response.statusCode >= 500) {
        debugPrint('❌ Server error (${response.statusCode}): ${response.body}');
        throw Exception('Server error: Please try again later');
      } else {
        debugPrint('❌ Failed to fetch sensor data: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        throw Exception(
          'Failed to fetch sensor data: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Exception while fetching sensor data: $e');

      // Re-throw known exceptions
      if (e is Exception) {
        rethrow;
      }

      // Wrap unknown errors
      throw Exception('Error fetching sensor data: $e');
    }
  }

  /// Fetch sensor data with retry mechanism
  ///
  /// [tankId] - The ID of the tank to fetch sensor data for
  /// [authProvider] - The authentication provider containing the access token
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [retryDelay] - Delay between retry attempts (default: 2 seconds)
  ///
  /// Returns [UltrasonicSensorData] if successful, throws exception if all retries fail
  static Future<UltrasonicSensorData> fetchTankSensorDataWithRetry({
    required String tankId,
    required AuthProvider authProvider,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Attempt $attempt/$maxRetries to fetch sensor data');

        return await fetchTankSensorData(
          tankId: tankId,
          authProvider: authProvider,
        );
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        debugPrint('❌ Attempt $attempt failed: $e');

        // Don't retry on authentication or client errors
        if (e.toString().contains('Authentication failed') ||
            e.toString().contains('Tank not found') ||
            e.toString().contains('Tank ID cannot be empty')) {
          debugPrint('🚫 Not retrying due to client error');
          rethrow;
        }

        // Wait before retrying (except on last attempt)
        if (attempt < maxRetries) {
          debugPrint('⏳ Waiting ${retryDelay.inSeconds}s before retry...');
          await Future.delayed(retryDelay);
        }
      }
    }

    // All retries failed
    debugPrint('❌ All $maxRetries attempts failed');
    throw lastException ??
        Exception('Failed to fetch sensor data after $maxRetries attempts');
  }

  /// Check if the sensor service is available
  ///
  /// [authProvider] - The authentication provider containing the access token
  ///
  /// Returns true if the service is available, false otherwise
  static Future<bool> isServiceAvailable(AuthProvider authProvider) async {
    try {
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}/api/health'),
            headers: {
              'Content-Type': 'application/json',
              'Cookie': 'access_token=${authProvider.accessToken}',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Service availability check failed: $e');
      return false;
    }
  }
}
