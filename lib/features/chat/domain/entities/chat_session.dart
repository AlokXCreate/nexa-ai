class ChatSession {
  final String id;
  final String title;
  final String modelId;
  final bool isPinned;
  final DateTime createdTime;
  final DateTime lastActiveTime;
  final String? folderId;
  final List<String> tags;
  
  // Custom generation parameter overrides
  final String? systemPrompt;
  final double? temperature;
  final double? topP;
  final int? maxTokens;
  final bool? useRag;

  const ChatSession({
    required this.id,
    required this.title,
    required this.modelId,
    required this.isPinned,
    required this.createdTime,
    required this.lastActiveTime,
    this.folderId,
    this.tags = const [],
    this.systemPrompt,
    this.temperature,
    this.topP,
    this.maxTokens,
    this.useRag,
  });

  ChatSession copyWith({
    String? title,
    bool? isPinned,
    DateTime? lastActiveTime,
    String? folderId,
    List<String>? tags,
    String? systemPrompt,
    double? temperature,
    double? topP,
    int? maxTokens,
    bool? useRag,
    bool clearSystemPrompt = false,
    bool clearFolder = false,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      modelId: modelId,
      isPinned: isPinned ?? this.isPinned,
      createdTime: createdTime,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      tags: tags ?? this.tags,
      systemPrompt: clearSystemPrompt ? null : (systemPrompt ?? this.systemPrompt),
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      useRag: useRag ?? this.useRag,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'modelId': modelId,
      'isPinned': isPinned,
      'createdTime': createdTime.toIso8601String(),
      'lastActiveTime': lastActiveTime.toIso8601String(),
      'folderId': folderId,
      'tags': tags,
      'systemPrompt': systemPrompt,
      'temperature': temperature,
      'topP': topP,
      'maxTokens': maxTokens,
      'useRag': useRag,
    };
  }

  factory ChatSession.fromMap(Map<dynamic, dynamic> map) {
    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String,
      modelId: map['modelId'] as String,
      isPinned: map['isPinned'] as bool,
      createdTime: DateTime.parse(map['createdTime'] as String),
      lastActiveTime: DateTime.parse(map['lastActiveTime'] as String),
      folderId: map['folderId'] as String?,
      tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      systemPrompt: map['systemPrompt'] as String?,
      temperature: (map['temperature'] as num?)?.toDouble(),
      topP: (map['topP'] as num?)?.toDouble(),
      maxTokens: map['maxTokens'] as int?,
      useRag: map['useRag'] as bool?,
    );
  }
}
