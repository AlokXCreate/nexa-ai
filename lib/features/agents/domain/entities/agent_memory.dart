class AgentMemory {
  final String id;
  final String agentId;
  final String key;
  final String value;
  final DateTime createdAt;

  AgentMemory({
    required this.id,
    required this.agentId,
    required this.key,
    required this.value,
    required this.createdAt,
  });

  AgentMemory copyWith({
    String? key,
    String? value,
  }) {
    return AgentMemory(
      id: id,
      agentId: agentId,
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agentId': agentId,
      'key': key,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AgentMemory.fromMap(Map<dynamic, dynamic> map) {
    return AgentMemory(
      id: map['id'] as String,
      agentId: map['agentId'] as String,
      key: map['key'] as String,
      value: map['value'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
