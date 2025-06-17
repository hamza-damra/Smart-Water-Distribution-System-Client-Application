import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/utilities/token_manager.dart';
import 'package:mytank/utilities/constants.dart';

class Tank {
  final String id;
  final String ownerId;
  final double radius;
  final double height;
  final String city;
  final List<FamilyMember> familyMembers;
  final double currentLevel;
  final Map<String, dynamic> amountPerMonth;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double monthlyCapacity;
  final double maxCapacity;
  final Map<String, dynamic> coordinates;
  final Map<String, dynamic> hardware;

  Tank({
    required this.id,
    required this.ownerId,
    required this.radius,
    required this.height,
    required this.city,
    required this.familyMembers,
    required this.currentLevel,
    required this.amountPerMonth,
    required this.createdAt,
    required this.updatedAt,
    required this.monthlyCapacity,
    required this.maxCapacity,
    required this.coordinates,
    required this.hardware,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    List<FamilyMember> members = [];
    if (json['family_members'] != null) {
      members = List<FamilyMember>.from(
        json['family_members'].map((member) => FamilyMember.fromJson(member)),
      );
    }

    // Handle city field - can be either string or object
    String cityName = '';
    if (json['city'] is Map<String, dynamic>) {
      final cityData = json['city'] as Map<String, dynamic>;
      cityName = cityData['name'] ?? '';
    } else if (json['city'] is String) {
      cityName = json['city'] ?? '';
    }

    return Tank(
      id: json['_id'] ?? json['id'] ?? '',
      ownerId: json['owner'] ?? '',
      radius: (json['radius'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      city: cityName,
      familyMembers: members,
      currentLevel: (json['current_level'] ?? 0).toDouble(),
      amountPerMonth: json['amount_per_month'] ?? {},
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      monthlyCapacity: (json['monthly_capacity'] ?? 0).toDouble(),
      maxCapacity: (json['max_capacity'] ?? 0).toDouble(),
      coordinates: json['coordinates'] ?? {},
      hardware: json['hardware'] ?? {},
    );
  }

  // Calculate water level percentage
  double get waterLevelPercentage {
    if (maxCapacity <= 0) return 0;
    return (currentLevel / maxCapacity).clamp(0.0, 1.0);
  }

  // Get current month's usage
  double getCurrentMonthUsage() {
    if (amountPerMonth.isEmpty || amountPerMonth['days'] == null) {
      return 0;
    }

    double total = 0;
    Map<String, dynamic> days = amountPerMonth['days'];
    days.forEach((day, amount) {
      total += (amount as num).toDouble();
    });

    return total;
  }

  // Get tank name or default name
  String get name {
    return 'Tank ${id.substring(id.length - 4)}';
  }
}

class FamilyMember {
  final String id;
  final String name;
  final DateTime dob;
  final String identityId;
  final String gender;

  FamilyMember({
    required this.id,
    required this.name,
    required this.dob,
    required this.identityId,
    required this.gender,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : DateTime.now(),
      identityId: json['identity_id'] ?? '',
      gender: json['gender'] ?? '',
    );
  }
}

class TankProvider with ChangeNotifier {
  List<Tank> _tanks = [];
  bool _isLoading = false;
  String? _error;
  Tank? _selectedTank;

  List<Tank> get tanks => _tanks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Tank? get selectedTank => _selectedTank;

  // Set selected tank
  void selectTank(String tankId) {
    if (_tanks.isEmpty) {
      _selectedTank = null;
    } else {
      try {
        _selectedTank = _tanks.firstWhere(
          (tank) => tank.id == tankId,
          orElse: () => _tanks.first,
        );
      } catch (e) {
        // Fallback to first tank if there's an error
        _selectedTank = _tanks.isNotEmpty ? _tanks.first : null;
      }
    }
    notifyListeners();
  }

  // Fetch tanks from API
  Future<void> fetchTanks(AuthProvider authProvider) async {
    if (authProvider.accessToken == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching tanks from API...');

      // Get token using TokenManager for consistency
      final String? token = await TokenManager.getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final apiUrl = '${Constants.apiUrl}/tank/customer-tanks';
      debugPrint('🌐 Tank API URL: $apiUrl');

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
        debugPrint('✅ Successfully received tanks data');
        final List<dynamic> tanksJson = json.decode(response.body);
        debugPrint('📄 Number of tanks received: ${tanksJson.length}');
        _tanks = tanksJson.map((json) => Tank.fromJson(json)).toList();
        debugPrint('✅ Tanks data processed successfully');

        // Set selected tank to first tank if available
        if (_tanks.isNotEmpty && _selectedTank == null) {
          _selectedTank = _tanks.first;
          debugPrint('✅ Selected first tank: ${_selectedTank?.id}');
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Authentication failed (401): ${response.body}');
        _error = 'Authentication failed: Invalid or expired token';
      } else {
        debugPrint('❌ Failed to load tanks: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        _error = 'Failed to load tanks: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ Exception while fetching tanks: $e');
      _error = 'Error fetching tanks: $e';
    } finally {
      _isLoading = false;
      debugPrint('🔄 Tanks loading completed. Success: ${_error == null}');
      notifyListeners();
    }
  }

  // Refresh tank data for a specific tank
  Future<void> refreshTankData(String tankId, AuthProvider authProvider) async {
    if (authProvider.accessToken == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, you would have an endpoint to get a specific tank
      // For now, we'll just refresh all tanks
      await fetchTanks(authProvider);

      // Update selected tank
      if (tankId.isNotEmpty) {
        selectTank(tankId);
      }
    } catch (e) {
      _error = 'Error refreshing tank data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear tanks data on logout
  void clearTanks() {
    _tanks = [];
    _selectedTank = null;
    _error = null;
    notifyListeners();
  }
}
