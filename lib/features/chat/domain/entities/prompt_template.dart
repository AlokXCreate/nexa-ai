class PromptTemplate {
  final String id;
  final String title;
  final String content;
  final bool isFavorite;
  final bool isPinned;
  final String category; // 'library', 'history', 'custom'
  final DateTime lastUsed;
  final DateTime createdAt;

  const PromptTemplate({
    required this.id,
    required this.title,
    required this.content,
    required this.isFavorite,
    required this.isPinned,
    required this.category,
    required this.lastUsed,
    required this.createdAt,
  });

  // Extract placeholder keys inside brackets, e.g. [language], [topic]
  List<String> get placeholders {
    final regExp = RegExp(r'\[([^\]]+)\]');
    final matches = regExp.allMatches(content);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }

  PromptTemplate copyWith({
    String? title,
    String? content,
    bool? isFavorite,
    bool? isPinned,
    String? category,
    DateTime? lastUsed,
  }) {
    return PromptTemplate(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isFavorite': isFavorite,
      'isPinned': isPinned,
      'category': category,
      'lastUsed': lastUsed.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PromptTemplate.fromMap(Map<dynamic, dynamic> map) {
    return PromptTemplate(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      isFavorite: map['isFavorite'] as bool,
      isPinned: map['isPinned'] as bool,
      category: map['category'] as String,
      lastUsed: DateTime.parse(map['lastUsed'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
