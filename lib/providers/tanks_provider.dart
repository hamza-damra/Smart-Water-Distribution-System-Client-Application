// tanks_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/tank_model.dart';
import '../utilities/constants.dart';

class TanksProvider with ChangeNotifier {
  List<Tank> _tanks = [];
  List<Tank> get tanks => _tanks;

  Future<void> fetchTanks(BuildContext context) async {
    final url = '${Constants.apiUrl}/tank/customer-tanks';

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

  Future<void> fetchTankDetails(String tankId) async {
    try {
      // Find the tank in the current list to get the context
      final tankIndex = _tanks.indexWhere((tank) => tank.id == tankId);
      if (tankIndex == -1) {
        throw Exception('Tank not found in current list');
      }

      // For now, we'll use a simple approach - just refresh all tanks
      // In a real implementation, you might want to fetch specific tank details
      // and update only that tank in the list

      // Since the API structure might not have a specific endpoint for individual tank details,
      // we'll simulate this by just ensuring the tank data is up to date
      debugPrint('Fetching details for tank: $tankId');

      // The tank details are already loaded when we fetch all tanks
      // This method can be used for future enhancements when a specific
      // tank details endpoint becomes available

      notifyListeners();
    } catch (error) {
      debugPrint('Error in fetchTankDetails(): $error');
      rethrow;
    }
  }

  // Update tank current level from real-time data
  void updateTankLevel(String tankId, double newLevel) {
    try {
      debugPrint('🌊 Updating tank level in TanksProvider:');
      debugPrint('   🏷️ Tank ID: $tankId');
      debugPrint('   📊 New Level: $newLevel L');

      // Find the tank in the list and update it
      final tankIndex = _tanks.indexWhere((tank) => tank.id == tankId);
      if (tankIndex != -1) {
        final oldTank = _tanks[tankIndex];

        // Create updated tank with new current level
        final updatedTank = Tank(
          id: oldTank.id,
          owner: oldTank.owner,
          radius: oldTank.radius,
          height: oldTank.height,
          city: oldTank.city,
          familyMembers: oldTank.familyMembers,
          currentLevel: newLevel, // Update the current level
          amountPerMonth: oldTank.amountPerMonth,
          maxCapacity: oldTank.maxCapacity,
          monthlyCapacity: oldTank.monthlyCapacity,
          coordinates: oldTank.coordinates,
          hardware: oldTank.hardware,
          createdAt: oldTank.createdAt,
          updatedAt: DateTime.now(), // Update the timestamp
        );

        // Replace the tank in the list
        _tanks[tankIndex] = updatedTank;

        // Notify listeners to update UI
        notifyListeners();

        debugPrint('✅ Tank level updated successfully in TanksProvider');
        debugPrint('   📊 New Level: ${updatedTank.currentLevel} L');
        debugPrint(
          '   📊 Fill Percentage: ${updatedTank.fillPercentage.toStringAsFixed(1)}%',
        );
      } else {
        debugPrint('ℹ️ Tank with ID $tankId not found in TanksProvider');
      }
    } catch (e) {
      debugPrint('❌ Error updating tank level in TanksProvider: $e');
    }
  }
}
