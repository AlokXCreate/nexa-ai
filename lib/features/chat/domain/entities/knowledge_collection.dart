class KnowledgeCollection {
  final String id;
  final String name;
  final DateTime createdAt;

  const KnowledgeCollection({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  KnowledgeCollection copyWith({
    String? name,
  }) {
    return KnowledgeCollection(
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

  factory KnowledgeCollection.fromMap(Map<dynamic, dynamic> map) {
    return KnowledgeCollection(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
