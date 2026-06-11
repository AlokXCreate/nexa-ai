import 'dart:convert';

class CloudProviderConfig {
  final String id; // 'openai' | 'anthropic' | 'gemini' | 'openrouter' | 'ollama' | 'custom'
  final String name;
  final String apiKeyObfuscated;
  final String baseUrl;
  final bool isEnabled;
  final int priority;
  final String defaultModelId;
  final int timeoutSeconds;
  final int maxRetries;

  const CloudProviderConfig({
    required this.id,
    required this.name,
    required this.apiKeyObfuscated,
    required this.baseUrl,
    required this.isEnabled,
    required this.priority,
    required this.defaultModelId,
    required this.timeoutSeconds,
    required this.maxRetries,
  });

  String get apiKey => deobfuscateKey(apiKeyObfuscated);

  static String obfuscateKey(String key) {
    if (key.trim().isEmpty) return '';
    final bytes = utf8.encode(key.trim());
    final obfuscated = bytes.map((b) => b ^ 88).toList(); // XOR with secret seed
    return base64.encode(obfuscated);
  }

  static String deobfuscateKey(String obfuscated) {
    if (obfuscated.trim().isEmpty) return '';
    try {
      final bytes = base64.decode(obfuscated.trim());
      final deobfuscated = bytes.map((b) => b ^ 88).toList();
      return utf8.decode(deobfuscated);
    } catch (_) {
      return '';
    }
  }

  CloudProviderConfig copyWith({
    String? apiKeyObfuscated,
    String? baseUrl,
    bool? isEnabled,
    int? priority,
    String? defaultModelId,
    int? timeoutSeconds,
    int? maxRetries,
  }) {
    return CloudProviderConfig(
      id: id,
      name: name,
      apiKeyObfuscated: apiKeyObfuscated ?? this.apiKeyObfuscated,
      baseUrl: baseUrl ?? this.baseUrl,
      isEnabled: isEnabled ?? this.isEnabled,
      priority: priority ?? this.priority,
      defaultModelId: defaultModelId ?? this.defaultModelId,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'apiKeyObfuscated': apiKeyObfuscated,
      'baseUrl': baseUrl,
      'isEnabled': isEnabled,
      'priority': priority,
      'defaultModelId': defaultModelId,
      'timeoutSeconds': timeoutSeconds,
      'maxRetries': maxRetries,
    };
  }

  factory CloudProviderConfig.fromMap(Map<dynamic, dynamic> map) {
    return CloudProviderConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      apiKeyObfuscated: map['apiKeyObfuscated'] as String? ?? '',
      baseUrl: map['baseUrl'] as String? ?? '',
      isEnabled: map['isEnabled'] as bool? ?? false,
      priority: map['priority'] as int? ?? 0,
      defaultModelId: map['defaultModelId'] as String? ?? '',
      timeoutSeconds: map['timeoutSeconds'] as int? ?? 15,
      maxRetries: map['maxRetries'] as int? ?? 2,
    );
  }
}
