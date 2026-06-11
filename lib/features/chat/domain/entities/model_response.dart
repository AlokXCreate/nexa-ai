class ModelResponse {
  final String modelId;
  final String content;
  final double tokensPerSecond;
  final int timeToFirstTokenMs;
  final int totalTokens;
  final double ramUsageMb;
  final bool isGenerating;
  final bool isQueued;

  const ModelResponse({
    required this.modelId,
    required this.content,
    required this.tokensPerSecond,
    required this.timeToFirstTokenMs,
    required this.totalTokens,
    required this.ramUsageMb,
    required this.isGenerating,
    required this.isQueued,
  });

  factory ModelResponse.empty(String modelId) {
    return ModelResponse(
      modelId: modelId,
      content: '',
      tokensPerSecond: 0.0,
      timeToFirstTokenMs: 0,
      totalTokens: 0,
      ramUsageMb: 0.0,
      isGenerating: false,
      isQueued: true,
    );
  }

  ModelResponse copyWith({
    String? content,
    double? tokensPerSecond,
    int? timeToFirstTokenMs,
    int? totalTokens,
    double? ramUsageMb,
    bool? isGenerating,
    bool? isQueued,
  }) {
    return ModelResponse(
      modelId: modelId,
      content: content ?? this.content,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      timeToFirstTokenMs: timeToFirstTokenMs ?? this.timeToFirstTokenMs,
      totalTokens: totalTokens ?? this.totalTokens,
      ramUsageMb: ramUsageMb ?? this.ramUsageMb,
      isGenerating: isGenerating ?? this.isGenerating,
      isQueued: isQueued ?? this.isQueued,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modelId': modelId,
      'content': content,
      'tokensPerSecond': tokensPerSecond,
      'timeToFirstTokenMs': timeToFirstTokenMs,
      'totalTokens': totalTokens,
      'ramUsageMb': ramUsageMb,
      'isGenerating': isGenerating,
      'isQueued': isQueued,
    };
  }

  factory ModelResponse.fromMap(Map<dynamic, dynamic> map) {
    return ModelResponse(
      modelId: map['modelId'] as String,
      content: map['content'] as String,
      tokensPerSecond: (map['tokensPerSecond'] as num).toDouble(),
      timeToFirstTokenMs: map['timeToFirstTokenMs'] as int,
      totalTokens: map['totalTokens'] as int,
      ramUsageMb: (map['ramUsageMb'] as num).toDouble(),
      isGenerating: map['isGenerating'] as bool,
      isQueued: map['isQueued'] as bool,
    );
  }
}
