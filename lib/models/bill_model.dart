// bill_model.dart
class Bill {
  final String id;
  final String customer;
  final dynamic tank; 
  final double amount;
  final String status;
  final int year;
  final int month;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double fees;
  final double priceForLetters;
  final double totalPrice;
  final DateTime? paymentDate;
  final DateTime? dueDate;

  Bill({
    required this.id,
    required this.customer,
    required this.tank,
    required this.amount,
    required this.status,
    required this.year,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
    required this.fees,
    required this.priceForLetters,
    required this.totalPrice,
    this.paymentDate,
    this.dueDate,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] ?? json['id'] ?? '',
      customer: json['customer'] ?? '',
      tank: json['tank'], 
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unknown',
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      fees: (json['fees'] ?? 0).toDouble(),
      priceForLetters: (json['price_for_letters'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      paymentDate:
          json['payment_date'] != null
              ? DateTime.parse(json['payment_date'])
              : null,
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    );
  }

  // Get month name from month number
  String get monthName {
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
    return months[month - 1];
  }

  // Get city name from tank data
  String? get cityName {
    if (tank is Map<String, dynamic>) {
      final tankData = tank as Map<String, dynamic>;
      final cityData = tankData['city'];
      if (cityData is Map<String, dynamic>) {
        return cityData['name'] as String?;
      } else if (cityData is String) {
        return cityData;
      }
    }
    return null;
  }

  // Get tank ID (for backward compatibility)
  String? get tankId {
    if (tank is String) {
      return tank as String;
    } else if (tank is Map<String, dynamic>) {
      final tankData = tank as Map<String, dynamic>;
      return tankData['_id'] ?? tankData['id'];
    }
    return null;
  }
}
