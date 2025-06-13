class NotificationModel {
  final String id;
  final String message;
  final String createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] ?? '',
      isRead: false, // Default to unread since API doesn't provide this
    );
  }

  // Create a copy with updated read status
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  // Helper method to format the creation date
  String getFormattedDate() {
    try {
      final DateTime date = DateTime.parse(createdAt);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays > 0) {
        if (difference.inDays == 1) {
          return '1 day ago';
        } else if (difference.inDays < 7) {
          return '${difference.inDays} days ago';
        } else {
          final List<String> months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          return '${date.day} ${months[date.month - 1]} ${date.year}';
        }
      } else if (difference.inHours > 0) {
        return difference.inHours == 1 
            ? '1 hour ago' 
            : '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return difference.inMinutes == 1 
            ? '1 minute ago' 
            : '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  // Helper method to get relative time for display
  String getRelativeTime() {
    try {
      final DateTime date = DateTime.parse(createdAt);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }
}
