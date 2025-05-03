// bill_model.dart
class Bill {
  final String id;
  final String customer;
  final String tank;
  final double amount;
  final String status;
  final int year;
  final int month;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double fees;
  final double priceForLetters;
  final double totalPrice;

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
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] ?? json['id'] ?? '',
      customer: json['customer'] ?? '',
      tank: json['tank'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unknown',
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      fees: (json['fees'] ?? 0).toDouble(),
      priceForLetters: (json['price_for_letters'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
    );
  }

  // Get month name from month number
  String get monthName {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
