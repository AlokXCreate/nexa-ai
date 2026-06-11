class CloudUsageStats {
  final DateTime timestamp;
  final String providerId;
  final String modelId;
  final int promptTokens;
  final int generationTokens;
  final double estimatedCost;

  const CloudUsageStats({
    required this.timestamp,
    required this.providerId,
    required this.modelId,
    required this.promptTokens,
    required this.generationTokens,
    required this.estimatedCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'providerId': providerId,
      'modelId': modelId,
      'promptTokens': promptTokens,
      'generationTokens': generationTokens,
      'estimatedCost': estimatedCost,
    };
  }

  factory CloudUsageStats.fromMap(Map<dynamic, dynamic> map) {
    return CloudUsageStats(
      timestamp: DateTime.parse(map['timestamp'] as String),
      providerId: map['providerId'] as String,
      modelId: map['modelId'] as String,
      promptTokens: map['promptTokens'] as int? ?? 0,
      generationTokens: map['generationTokens'] as int? ?? 0,
      estimatedCost: (map['estimatedCost'] as num? ?? 0.0).toDouble(),
    );
  }
}
