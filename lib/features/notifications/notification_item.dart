class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: (json['is_read'] ?? false) == true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
