class PerformanceMonitor {
  final double tokensPerSecond;
  final int timeToFirstTokenMs;
  final int totalTokensGenerated;
  final double ramUsageMb;
  final double cpuUsagePercent;
  final double gpuUsagePercent;
  final double storageUsageGb;
  final int contextSize;
  final int conversationTokens;

  const PerformanceMonitor({
    required this.tokensPerSecond,
    required this.timeToFirstTokenMs,
    required this.totalTokensGenerated,
    required this.ramUsageMb,
    required this.cpuUsagePercent,
    required this.gpuUsagePercent,
    required this.storageUsageGb,
    required this.contextSize,
    required this.conversationTokens,
  });

  factory PerformanceMonitor.empty() {
    return const PerformanceMonitor(
      tokensPerSecond: 0.0,
      timeToFirstTokenMs: 0,
      totalTokensGenerated: 0,
      ramUsageMb: 0.0,
      cpuUsagePercent: 0.0,
      gpuUsagePercent: 0.0,
      storageUsageGb: 0.0,
      contextSize: 2048,
      conversationTokens: 0,
    );
  }

  PerformanceMonitor copyWith({
    double? tokensPerSecond,
    int? timeToFirstTokenMs,
    int? totalTokensGenerated,
    double? ramUsageMb,
    double? cpuUsagePercent,
    double? gpuUsagePercent,
    double? storageUsageGb,
    int? contextSize,
    int? conversationTokens,
  }) {
    return PerformanceMonitor(
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      timeToFirstTokenMs: timeToFirstTokenMs ?? this.timeToFirstTokenMs,
      totalTokensGenerated: totalTokensGenerated ?? this.totalTokensGenerated,
      ramUsageMb: ramUsageMb ?? this.ramUsageMb,
      cpuUsagePercent: cpuUsagePercent ?? this.cpuUsagePercent,
      gpuUsagePercent: gpuUsagePercent ?? this.gpuUsagePercent,
      storageUsageGb: storageUsageGb ?? this.storageUsageGb,
      contextSize: contextSize ?? this.contextSize,
      conversationTokens: conversationTokens ?? this.conversationTokens,
    );
  }
}
