// tank_model.dart
class Tank {
  final String id;
  final String owner;
  final double radius;
  final double height;
  final String city;
  final List<FamilyMember> familyMembers;
  final double currentLevel;
  final Map<String, dynamic> amountPerMonth;
  final double maxCapacity;
  final double monthlyCapacity;
  final Map<String, dynamic> coordinates;
  final Map<String, dynamic> hardware;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tank({
    required this.id,
    required this.owner,
    required this.radius,
    required this.height,
    required this.city,
    required this.familyMembers,
    required this.currentLevel,
    required this.amountPerMonth,
    required this.maxCapacity,
    required this.monthlyCapacity,
    required this.coordinates,
    required this.hardware,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    // Parse family members
    List<FamilyMember> members = [];
    if (json['family_members'] != null) {
      members = List<FamilyMember>.from(
        json['family_members'].map((member) => FamilyMember.fromJson(member)),
      );
    }

    return Tank(
      id: json['_id'] ?? json['id'] ?? '',
      owner: json['owner'] ?? '',
      radius: (json['radius'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      city: json['city'] ?? '',
      familyMembers: members,
      currentLevel: (json['current_level'] ?? 0).toDouble(),
      amountPerMonth: json['amount_per_month'] ?? {},
      maxCapacity: (json['max_capacity'] ?? 0).toDouble(),
      monthlyCapacity: (json['monthly_capacity'] ?? 0).toDouble(),
      coordinates: json['coordinates'] ?? {},
      hardware: json['hardware'] ?? {},
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
    );
  }

  // Calculate fill percentage
  double get fillPercentage => (currentLevel / maxCapacity) * 100;

  // Get current month's usage
  double getCurrentMonthUsage() {
    if (amountPerMonth.isEmpty || amountPerMonth['days'] == null) {
      return 0;
    }

    double total = 0;
    Map<String, dynamic> days = amountPerMonth['days'];
    days.forEach((day, amount) {
      total += (amount is num) ? amount.toDouble() : 0.0;
    });

    return total;
  }

  // Get water inflow (water added to the tank)
  double getWaterInflow() {
    if (amountPerMonth.isEmpty || amountPerMonth['days'] == null) {
      return 0;
    }

    // For this example, we'll consider inflow as the sum of all positive values
    // In a real system, you might have separate inflow/outflow measurements
    double inflow = 0;
    Map<String, dynamic> days = amountPerMonth['days'];
    days.forEach((day, amount) {
      if (amount is num && amount > 0) {
        inflow += amount.toDouble();
      }
    });

    return inflow;
  }

  // Get water outflow (water used from the tank)
  double getWaterOutflow() {
    // In this example, outflow is the same as total usage
    // In a real system, you might calculate this differently
    return getCurrentMonthUsage();
  }

  // Get current month name
  String getCurrentMonthName() {
    if (amountPerMonth.isEmpty || amountPerMonth['month'] == null) {
      return 'Unknown';
    }

    final monthNumber = amountPerMonth['month'] as int;
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (monthNumber >= 1 && monthNumber <= 12) {
      return months[monthNumber - 1];
    } else {
      return 'Unknown';
    }
  }

  // Get tank name or default name
  String get name {
    return 'Tank ${id.substring(id.length - 6)}';
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
