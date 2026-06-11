class BenchmarkResult {
  final String id;
  final String modelId;
  final String modelName;
  final DateTime timestamp;
  final double tokensPerSecond;
  final int firstTokenLatencyMs;
  final double ramUsageMb;
  final double cpuUsagePercent;
  final double gpuUsagePercent;
  final double batteryImpactPercent; // Relative drain score (e.g. estimated % per hour)
  final double storageUsageGb;
  final int contextLength;
  final double inferenceSpeed; // General speed metric (tokens/sec or words/sec)
  final bool isCompleted;
  final String? error;

  const BenchmarkResult({
    required this.id,
    required this.modelId,
    required this.modelName,
    required this.timestamp,
    this.tokensPerSecond = 0.0,
    this.firstTokenLatencyMs = 0,
    this.ramUsageMb = 0.0,
    this.cpuUsagePercent = 0.0,
    this.gpuUsagePercent = 0.0,
    this.batteryImpactPercent = 0.0,
    this.storageUsageGb = 0.0,
    this.contextLength = 2048,
    this.inferenceSpeed = 0.0,
    this.isCompleted = false,
    this.error,
  });

  double get performanceScore {
    if (!isCompleted || error != null) return 0.0;
    
    // Tokens per second contributes most to the speed score
    final speedComponent = tokensPerSecond * 15.0;
    
    // Latency (lower is better, base reference is 2000ms)
    final latencySec = firstTokenLatencyMs / 1000.0;
    final latencyComponent = latencySec > 0 ? (10.0 / latencySec) * 5.0 : 0.0;
    
    // RAM efficiency (lower RAM is better, base reference is 8GB/8192MB)
    final ramGb = ramUsageMb / 1024.0;
    final ramComponent = ramGb > 0 ? (8.0 / ramGb) * 20.0 : 0.0;

    // CPU/GPU utilization efficiency
    final loadComponent = (100.0 - cpuUsagePercent) * 0.1;

    return speedComponent + latencyComponent + ramComponent + loadComponent;
  }

  BenchmarkResult copyWith({
    double? tokensPerSecond,
    int? firstTokenLatencyMs,
    double? ramUsageMb,
    double? cpuUsagePercent,
    double? gpuUsagePercent,
    double? batteryImpactPercent,
    double? storageUsageGb,
    int? contextLength,
    double? inferenceSpeed,
    bool? isCompleted,
    String? error,
  }) {
    return BenchmarkResult(
      id: id,
      modelId: modelId,
      modelName: modelName,
      timestamp: timestamp,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      firstTokenLatencyMs: firstTokenLatencyMs ?? this.firstTokenLatencyMs,
      ramUsageMb: ramUsageMb ?? this.ramUsageMb,
      cpuUsagePercent: cpuUsagePercent ?? this.cpuUsagePercent,
      gpuUsagePercent: gpuUsagePercent ?? this.gpuUsagePercent,
      batteryImpactPercent: batteryImpactPercent ?? this.batteryImpactPercent,
      storageUsageGb: storageUsageGb ?? this.storageUsageGb,
      contextLength: contextLength ?? this.contextLength,
      inferenceSpeed: inferenceSpeed ?? this.inferenceSpeed,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modelId': modelId,
      'modelName': modelName,
      'timestamp': timestamp.toIso8601String(),
      'tokensPerSecond': tokensPerSecond,
      'firstTokenLatencyMs': firstTokenLatencyMs,
      'ramUsageMb': ramUsageMb,
      'cpuUsagePercent': cpuUsagePercent,
      'gpuUsagePercent': gpuUsagePercent,
      'batteryImpactPercent': batteryImpactPercent,
      'storageUsageGb': storageUsageGb,
      'contextLength': contextLength,
      'inferenceSpeed': inferenceSpeed,
      'isCompleted': isCompleted,
      'error': error,
    };
  }

  factory BenchmarkResult.fromMap(Map<dynamic, dynamic> map) {
    return BenchmarkResult(
      id: map['id'] as String,
      modelId: map['modelId'] as String,
      modelName: map['modelName'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      tokensPerSecond: (map['tokensPerSecond'] as num?)?.toDouble() ?? 0.0,
      firstTokenLatencyMs: (map['firstTokenLatencyMs'] as num?)?.toInt() ?? 0,
      ramUsageMb: (map['ramUsageMb'] as num?)?.toDouble() ?? 0.0,
      cpuUsagePercent: (map['cpuUsagePercent'] as num?)?.toDouble() ?? 0.0,
      gpuUsagePercent: (map['gpuUsagePercent'] as num?)?.toDouble() ?? 0.0,
      batteryImpactPercent: (map['batteryImpactPercent'] as num?)?.toDouble() ?? 0.0,
      storageUsageGb: (map['storageUsageGb'] as num?)?.toDouble() ?? 0.0,
      contextLength: (map['contextLength'] as num?)?.toInt() ?? 2048,
      inferenceSpeed: (map['inferenceSpeed'] as num?)?.toDouble() ?? 0.0,
      isCompleted: map['isCompleted'] as bool? ?? false,
      error: map['error'] as String?,
    );
  }
}
