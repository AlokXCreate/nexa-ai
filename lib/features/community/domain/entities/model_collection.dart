class ModelCollection {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final List<String> modelIds;
  final int likesCount;
  final List<String> likedUsers;
  final bool isPublic;
  final DateTime createdAt;

  const ModelCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.modelIds,
    this.likesCount = 0,
    this.likedUsers = const [],
    this.isPublic = true,
    required this.createdAt,
  });

  ModelCollection copyWith({
    String? name,
    String? description,
    List<String>? modelIds,
    int? likesCount,
    List<String>? likedUsers,
    bool? isPublic,
  }) {
    return ModelCollection(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId,
      ownerName: ownerName,
      modelIds: modelIds ?? this.modelIds,
      likesCount: likesCount ?? this.likesCount,
      likedUsers: likedUsers ?? this.likedUsers,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'modelIds': modelIds,
      'likesCount': likesCount,
      'likedUsers': likedUsers,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ModelCollection.fromMap(Map<dynamic, dynamic> map) {
    return ModelCollection(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? 'Curator',
      modelIds: (map['modelIds'] as List?)?.cast<String>() ?? const [],
      likesCount: map['likesCount'] as int? ?? 0,
      likedUsers: (map['likedUsers'] as List?)?.cast<String>() ?? const [],
      isPublic: map['isPublic'] as bool? ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
    );
  }
}
