class CompareSession {
  final String id;
  final String title;
  final List<String> modelIds;
  final DateTime createdAt;
  final DateTime lastActiveTime;

  const CompareSession({
    required this.id,
    required this.title,
    required this.modelIds,
    required this.createdAt,
    required this.lastActiveTime,
  });

  CompareSession copyWith({
    String? title,
    List<String>? modelIds,
    DateTime? lastActiveTime,
  }) {
    return CompareSession(
      id: id,
      title: title ?? this.title,
      modelIds: modelIds ?? this.modelIds,
      createdAt: createdAt,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'modelIds': modelIds,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveTime': lastActiveTime.toIso8601String(),
    };
  }

  factory CompareSession.fromMap(Map<dynamic, dynamic> map) {
    return CompareSession(
      id: map['id'] as String,
      title: map['title'] as String,
      modelIds: (map['modelIds'] as List).cast<String>(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastActiveTime: DateTime.parse(map['lastActiveTime'] as String),
    );
  }
}
