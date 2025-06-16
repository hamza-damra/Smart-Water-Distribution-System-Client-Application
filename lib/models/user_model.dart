class User {
  final String id;
  final String identityNumber;
  final String name;
  final String email;
  final String phone;
  final List<String> tanks;
  final List<String> bills;
  final List<dynamic> notifications;
  final String createdAt;
  final String updatedAt;
  final String? avatarUrl;
  final String? address;
  final String? city;
  final String? postalCode;

  User({
    required this.id,
    required this.identityNumber,
    required this.name,
    required this.email,
    required this.phone,
    required this.tanks,
    required this.bills,
    required this.notifications,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.address,
    this.city,
    this.postalCode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      identityNumber: json['identity_number'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      tanks: List<String>.from(json['tanks'] ?? []),
      bills: List<String>.from(json['bills'] ?? []),
      notifications: List<dynamic>.from(json['notifications'] ?? []),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      avatarUrl: json['avatar_url'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'],
    );
  }

  // Helper method to format the join date
  String getFormattedJoinDate() {
    try {
      final DateTime date = DateTime.parse(createdAt);
      final List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return 'Joined: ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Joined: Unknown';
    }
  }
}
