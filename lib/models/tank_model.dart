// tank_model.dart
class Tank {
  final String id;
  final double currentLevel;
  final double maxCapacity;
  final double monthlyCapacity;

  Tank({
    required this.id,
    required this.currentLevel,
    required this.maxCapacity,
    required this.monthlyCapacity,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      id: json['_id'] as String,
      currentLevel: (json['current_level'] as num).toDouble(),
      maxCapacity: (json['max_capacity'] as num).toDouble(),
      monthlyCapacity: (json['monthly_capacity'] as num).toDouble(),
    );
  }


  double get fillPercentage => (currentLevel / maxCapacity) * 100;
}
