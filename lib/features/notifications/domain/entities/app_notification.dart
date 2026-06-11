enum NotificationType {
  model_update,
  plugin_update,
  download_complete,
  backup_reminder,
  weekly_report,
  storage_warning,
  new_model_recommended,
  trending_models,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime timestamp;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.payload = const {},
    this.isRead = false,
    required this.timestamp,
  });

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      payload: payload,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'payload': payload,
      'isRead': isRead,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<dynamic, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationType.values.byName(map['type'] as String? ?? 'model_update'),
      payload: (map['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      isRead: map['isRead'] as bool? ?? false,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp'] as String) : DateTime.now(),
    );
  }
}
