import 'package:localmind_ai/features/chat/domain/entities/model_response.dart';

class CompareMessage {
  final String id;
  final String sessionId;
  final String prompt;
  final Map<String, ModelResponse> modelResponses;
  final DateTime timestamp;

  const CompareMessage({
    required this.id,
    required this.sessionId,
    required this.prompt,
    required this.modelResponses,
    required this.timestamp,
  });

  CompareMessage copyWith({
    String? prompt,
    Map<String, ModelResponse>? modelResponses,
    DateTime? timestamp,
  }) {
    return CompareMessage(
      id: id,
      sessionId: sessionId,
      prompt: prompt ?? this.prompt,
      modelResponses: modelResponses ?? this.modelResponses,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'prompt': prompt,
      'modelResponses': modelResponses.map((key, value) => MapEntry(key, value.toMap())),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CompareMessage.fromMap(Map<dynamic, dynamic> map) {
    final rawResponses = map['modelResponses'] as Map<dynamic, dynamic>;
    final modelResponses = rawResponses.map((key, value) {
      return MapEntry(
        key as String,
        ModelResponse.fromMap(value as Map<dynamic, dynamic>),
      );
    });

    return CompareMessage(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String,
      prompt: map['prompt'] as String,
      modelResponses: modelResponses,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
