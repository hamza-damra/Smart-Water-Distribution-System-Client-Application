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
      owner: json['owner'] ?? '',
      radius: (json['radius'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      city: cityName,
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

  // Get usage history data for the last 7 days
  List<double> getUsageHistoryData() {
    if (amountPerMonth.isEmpty || amountPerMonth['days'] == null) {
      return List.filled(7, 0.0);
    }

    Map<String, dynamic> days = amountPerMonth['days'];
    List<double> usageData = [];

    // Get current day
    final now = DateTime.now();
    final currentDay = now.day;

    // Calculate the start day (we want to show the last 7 days with data)
    int startDay = currentDay - 6;
    if (startDay < 1) startDay = 1;

    // Get data for the last 7 days
    for (int day = startDay; day <= currentDay; day++) {
      final dayStr = day.toString();
      final usage = days[dayStr];
      usageData.add(usage != null && usage is num ? usage.toDouble() : 0.0);
    }

    // If we have fewer than 7 days (early in the month), pad with zeros at the beginning
    while (usageData.length < 7) {
      usageData.insert(0, 0.0);
    }

    return usageData;
  }

  // Get all daily usage data for the entire month (30 days)
  List<double> getAllDailyUsageData() {
    if (amountPerMonth.isEmpty || amountPerMonth['days'] == null) {
      return List.filled(30, 0.0);
    }

    Map<String, dynamic> days = amountPerMonth['days'];
    List<double> usageData = [];

    // Get data for all 30 days of the month
    for (int day = 1; day <= 30; day++) {
      final dayStr = day.toString();
      final usage = days[dayStr];
      usageData.add(usage != null && usage is num ? usage.toDouble() : 0.0);
    }

    return usageData;
  }

  // Get day labels for the chart
  List<String> getUsageHistoryLabels() {
    final now = DateTime.now();
    final currentDay = now.day;
    final monthName = getCurrentMonthName().substring(
      0,
      3,
    ); // First 3 letters of month name
    List<String> labels = [];

    // Calculate the start day (we want to show the last 7 days with data)
    int startDay = currentDay - 6;
    if (startDay < 1) startDay = 1;

    // Get labels for the last 7 days
    for (int day = startDay; day <= currentDay; day++) {
      labels.add("$day $monthName");
    }

    // If we have fewer than 7 days (early in the month), pad with empty strings at the beginning
    while (labels.length < 7) {
      labels.insert(0, "");
    }

    return labels;
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
