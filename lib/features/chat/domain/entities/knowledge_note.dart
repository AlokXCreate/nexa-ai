class KnowledgeNote {
  final String id;
  final String title;
  final String content;
  final String? collectionId;
  final String? category;
  final List<String> tags;
  final bool isPinned;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KnowledgeNote({
    required this.id,
    required this.title,
    required this.content,
    this.collectionId,
    this.category,
    this.tags = const [],
    this.isPinned = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  KnowledgeNote copyWith({
    String? title,
    String? content,
    String? collectionId,
    String? category,
    List<String>? tags,
    bool? isPinned,
    bool? isFavorite,
    DateTime? updatedAt,
    bool clearCollectionId = false,
    bool clearCategory = false,
  }) {
    return KnowledgeNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      collectionId: clearCollectionId ? null : (collectionId ?? this.collectionId),
      category: clearCategory ? null : (category ?? this.category),
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'collectionId': collectionId,
      'category': category,
      'tags': tags,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory KnowledgeNote.fromMap(Map<dynamic, dynamic> map) {
    final rawTags = map['tags'] as List?;
    final List<String> castedTags = rawTags != null 
        ? rawTags.map((e) => e.toString()).toList() 
        : const [];

    return KnowledgeNote(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      collectionId: map['collectionId'] as String?,
      category: map['category'] as String?,
      tags: castedTags,
      isPinned: map['isPinned'] as bool? ?? false,
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
