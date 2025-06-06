class MainTank {
  final String id;
  final double radius;
  final double height;
  final String city;
  final double currentLevel;
  final double maxCapacity;
  final Map<String, dynamic> coordinates;
  final Map<String, dynamic> amountPerMonth;
  final DateTime createdAt;
  final DateTime updatedAt;

  MainTank({
    required this.id,
    required this.radius,
    required this.height,
    required this.city,
    required this.currentLevel,
    required this.maxCapacity,
    required this.coordinates,
    required this.amountPerMonth,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MainTank.fromJson(Map<String, dynamic> json) {
    return MainTank(
      id: json['id'] ?? json['_id'] ?? '',
      radius: (json['radius'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      city: json['city'] is Map 
          ? json['city']['name'] ?? 'Unknown'
          : json['city']?.toString() ?? 'Unknown',
      currentLevel: (json['current_level'] ?? 0).toDouble(),
      maxCapacity: (json['max_capacity'] ?? 0).toDouble(),
      coordinates: json['coordinates'] ?? {},
      amountPerMonth: json['amount_per_month'] ?? {},
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'radius': radius,
      'height': height,
      'city': city,
      'current_level': currentLevel,
      'max_capacity': maxCapacity,
      'coordinates': coordinates,
      'amount_per_month': amountPerMonth,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Calculate water level percentage
  double get waterLevelPercentage {
    if (maxCapacity <= 0) return 0.0;
    return (currentLevel / maxCapacity).clamp(0.0, 1.0);
  }

  // Get status based on water level
  String get status {
    final percentage = waterLevelPercentage;
    if (percentage >= 0.75) return 'High';
    if (percentage >= 0.25) return 'Medium';
    return 'Low';
  }

  // Calculate tank volume in liters
  double get volumeInLiters {
    // Volume = π * r² * h (in cubic meters, then convert to liters)
    final volumeM3 = 3.14159 * (radius * radius) * height;
    return volumeM3 * 1000; // Convert to liters
  }

  // Get current water amount in liters
  double get currentWaterInLiters {
    return volumeInLiters * waterLevelPercentage;
  }

  // Get latitude from coordinates
  double get latitude {
    return (coordinates['latitude'] ?? 0).toDouble();
  }

  // Get longitude from coordinates
  double get longitude {
    return (coordinates['longitude'] ?? 0).toDouble();
  }
}
