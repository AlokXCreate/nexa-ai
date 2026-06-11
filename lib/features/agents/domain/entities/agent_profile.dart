class AgentProfile {
  final String id;
  final String name;
  final String role;
  final String description;
  final String systemPrompt;
  final String iconName;
  final List<String> tools;
  final String defaultModelId;
  final double temperature;

  AgentProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    required this.systemPrompt,
    required this.iconName,
    required this.tools,
    required this.defaultModelId,
    this.temperature = 0.7,
  });

  AgentProfile copyWith({
    String? name,
    String? role,
    String? description,
    String? systemPrompt,
    String? iconName,
    List<String>? tools,
    String? defaultModelId,
    double? temperature,
  }) {
    return AgentProfile(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      iconName: iconName ?? this.iconName,
      tools: tools ?? this.tools,
      defaultModelId: defaultModelId ?? this.defaultModelId,
      temperature: temperature ?? this.temperature,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'description': description,
      'systemPrompt': systemPrompt,
      'iconName': iconName,
      'tools': tools,
      'defaultModelId': defaultModelId,
      'temperature': temperature,
    };
  }

  factory AgentProfile.fromMap(Map<dynamic, dynamic> map) {
    return AgentProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      description: map['description'] as String,
      systemPrompt: map['systemPrompt'] as String,
      iconName: map['iconName'] as String,
      tools: (map['tools'] as List?)?.cast<String>() ?? const [],
      defaultModelId: map['defaultModelId'] as String? ?? 'llama_3_2_3b',
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
    );
  }
}
