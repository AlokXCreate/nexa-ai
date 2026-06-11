class RagFolder {
  final String id;
  final String name;
  final DateTime createdAt;

  const RagFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  RagFolder copyWith({
    String? name,
  }) {
    return RagFolder(
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

  factory RagFolder.fromMap(Map<dynamic, dynamic> map) {
    return RagFolder(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
