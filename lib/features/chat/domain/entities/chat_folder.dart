class ChatFolder {
  final String id;
  final String name;
  final DateTime createdAt;

  const ChatFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  ChatFolder copyWith({
    String? name,
  }) {
    return ChatFolder(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatFolder.fromMap(Map<dynamic, dynamic> map) {
    return ChatFolder(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
