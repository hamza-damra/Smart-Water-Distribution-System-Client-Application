// ultrasonic_sensor_model.dart
class UltrasonicSensorData {
  final double averageDistanceCm;
  final double estimatedVolumeLiters;
  final List<double> readings;
  final double waterHeightCm;

  UltrasonicSensorData({
    required this.averageDistanceCm,
    required this.estimatedVolumeLiters,
    required this.readings,
    required this.waterHeightCm,
  });

  factory UltrasonicSensorData.fromJson(Map<String, dynamic> json) {
    // Parse readings array safely
    List<double> readingsList = [];
    if (json['readings'] != null && json['readings'] is List) {
      readingsList = (json['readings'] as List)
          .map((reading) => (reading is num) ? reading.toDouble() : 0.0)
          .toList();
    }

    return UltrasonicSensorData(
      averageDistanceCm: (json['average_distance_cm'] ?? 0.0).toDouble(),
      estimatedVolumeLiters: (json['estimated_volume_liters'] ?? 0.0).toDouble(),
      readings: readingsList,
      waterHeightCm: (json['water_height_cm'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_distance_cm': averageDistanceCm,
      'estimated_volume_liters': estimatedVolumeLiters,
      'readings': readings,
      'water_height_cm': waterHeightCm,
    };
  }

  // Helper method to get the latest reading
  double get latestReading {
    if (readings.isEmpty) return 0.0;
    return readings.last;
  }

  // Helper method to get minimum reading
  double get minReading {
    if (readings.isEmpty) return 0.0;
    return readings.reduce((a, b) => a < b ? a : b);
  }

  // Helper method to get maximum reading
  double get maxReading {
    if (readings.isEmpty) return 0.0;
    return readings.reduce((a, b) => a > b ? a : b);
  }

  // Helper method to check if readings are stable (low variance)
  bool get isStable {
    if (readings.length < 2) return true;
    
    double sum = readings.reduce((a, b) => a + b);
    double mean = sum / readings.length;
    
    double variance = readings
        .map((reading) => (reading - mean) * (reading - mean))
        .reduce((a, b) => a + b) / readings.length;
    
    // Consider stable if variance is less than 1.0 cm²
    return variance < 1.0;
  }

  // Helper method to format volume for display
  String get formattedVolume {
    if (estimatedVolumeLiters >= 1000) {
      return '${(estimatedVolumeLiters / 1000).toStringAsFixed(1)}K L';
    }
    return '${estimatedVolumeLiters.toStringAsFixed(1)} L';
  }

  // Helper method to format distance for display
  String get formattedDistance {
    return '${averageDistanceCm.toStringAsFixed(1)} cm';
  }

  // Helper method to format water height for display
  String get formattedWaterHeight {
    return '${waterHeightCm.toStringAsFixed(1)} cm';
  }

  @override
  String toString() {
    return 'UltrasonicSensorData(averageDistanceCm: $averageDistanceCm, estimatedVolumeLiters: $estimatedVolumeLiters, readings: $readings, waterHeightCm: $waterHeightCm)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UltrasonicSensorData &&
        other.averageDistanceCm == averageDistanceCm &&
        other.estimatedVolumeLiters == estimatedVolumeLiters &&
        other.waterHeightCm == waterHeightCm &&
        _listEquals(other.readings, readings);
  }

  @override
  int get hashCode {
    return averageDistanceCm.hashCode ^
        estimatedVolumeLiters.hashCode ^
        waterHeightCm.hashCode ^
        readings.hashCode;
  }

  // Helper method to compare lists
  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
