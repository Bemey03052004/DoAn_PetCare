class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String?,
      isRead: (json['isRead'] ?? false) as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}


