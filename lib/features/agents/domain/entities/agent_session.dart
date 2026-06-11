class AgentSession {
  final String id;
  final String agentId;
  final String chatSessionId;
  final String? activeModelOverride;

  AgentSession({
    required this.id,
    required this.agentId,
    required this.chatSessionId,
    this.activeModelOverride,
  });

  AgentSession copyWith({
    String? activeModelOverride,
  }) {
    return AgentSession(
      id: id,
      agentId: agentId,
      chatSessionId: chatSessionId,
      activeModelOverride: activeModelOverride ?? this.activeModelOverride,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agentId': agentId,
      'chatSessionId': chatSessionId,
      'activeModelOverride': activeModelOverride,
    };
  }

  factory AgentSession.fromMap(Map<dynamic, dynamic> map) {
    return AgentSession(
      id: map['id'] as String,
      agentId: map['agentId'] as String,
      chatSessionId: map['chatSessionId'] as String,
      activeModelOverride: map['activeModelOverride'] as String?,
    );
  }
}
