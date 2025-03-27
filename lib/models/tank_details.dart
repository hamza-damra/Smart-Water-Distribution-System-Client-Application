import 'day_usage.dart';

class TankDetail {
  final String id;
  final double currentLevel;
  final double maxCapacity;
  final List<DayUsage> dailyUsage;

  TankDetail({
    required this.id,
    required this.currentLevel,
    required this.maxCapacity,
    required this.dailyUsage,
  });

  factory TankDetail.fromJson(Map<String, dynamic> json) {
    final usageMap = json['amount_per_month']?['days'] as Map<String, dynamic>? ?? {};
    final usage = usageMap.entries.map((entry) {
      return DayUsage(int.parse(entry.key), (entry.value as num).toDouble());
    }).toList();
    return TankDetail(
      id: json['_id'] ?? json['id'],
      currentLevel: (json['current_level'] as num).toDouble(),
      maxCapacity: (json['max_capacity'] as num).toDouble(),
      dailyUsage: usage,
    );
  }
}