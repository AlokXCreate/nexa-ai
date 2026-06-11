class ToolCall {
  final String id;
  final String type; // usually 'function'
  final String functionName;
  final String functionArguments; // JSON formatted string

  const ToolCall({
    required this.id,
    required this.type,
    required this.functionName,
    required this.functionArguments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'functionName': functionName,
      'functionArguments': functionArguments,
    };
  }

  factory ToolCall.fromMap(Map<String, dynamic> map) {
    return ToolCall(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'function',
      functionName: map['functionName'] as String? ?? '',
      functionArguments: map['functionArguments'] as String? ?? '',
    );
  }
}

class ToolCallDelta {
  final int index;
  final String? id;
  final String? type;
  final String? functionName;
  final String? functionArgumentsDelta;

  const ToolCallDelta({
    required this.index,
    this.id,
    this.type,
    this.functionName,
    this.functionArgumentsDelta,
  });
}

class ProviderResponse {
  final String text;
  final List<ToolCall>? toolCalls;
  final int promptTokens;
  final int generationTokens;
  final double estimatedCost;

  const ProviderResponse({
    required this.text,
    this.toolCalls,
    this.promptTokens = 0,
    this.generationTokens = 0,
    this.estimatedCost = 0.0,
  });
}

class ProviderStreamChunk {
  final String textDelta;
  final List<ToolCallDelta>? toolCallDeltas;
  final int? promptTokens;
  final int? generationTokens;
  final double? estimatedCost;

  const ProviderStreamChunk({
    this.textDelta = '',
    this.toolCallDeltas,
    this.promptTokens,
    this.generationTokens,
    this.estimatedCost,
  });
}
