enum MessageSender {
  user,
  ai,
}

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final bool isEdited;
  final List<String>? sources;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isEdited = false,
    this.sources,
  });

  ChatMessage copyWith({
    String? content,
    bool? isEdited,
    List<String>? sources,
  }) {
    return ChatMessage(
      id: id,
      sender: sender,
      content: content ?? this.content,
      timestamp: timestamp,
      isEdited: isEdited ?? this.isEdited,
      sources: sources ?? this.sources,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender.index,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isEdited': isEdited,
      'sources': sources,
    };
  }

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      sender: MessageSender.values[map['sender'] as int],
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isEdited: map['isEdited'] as bool? ?? false,
      sources: (map['sources'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}
