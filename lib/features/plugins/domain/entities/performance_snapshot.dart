class PerformanceSnapshot {
  final DateTime timestamp;
  final double tokenSpeed;
  final double memoryUsageMb;
  final double cpuUsagePercent;
  final double gpuUsagePercent;
  final double batteryLevelPercent;
  final double storageUsageGb;
  final String modelId;
  final int promptLength;
  final int generationTimeMs;

  const PerformanceSnapshot({
    required this.timestamp,
    required this.tokenSpeed,
    required this.memoryUsageMb,
    required this.cpuUsagePercent,
    required this.gpuUsagePercent,
    required this.batteryLevelPercent,
    required this.storageUsageGb,
    required this.modelId,
    required this.promptLength,
    required this.generationTimeMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'tokenSpeed': tokenSpeed,
      'memoryUsageMb': memoryUsageMb,
      'cpuUsagePercent': cpuUsagePercent,
      'gpuUsagePercent': gpuUsagePercent,
      'batteryLevelPercent': batteryLevelPercent,
      'storageUsageGb': storageUsageGb,
      'modelId': modelId,
      'promptLength': promptLength,
      'generationTimeMs': generationTimeMs,
    };
  }

  factory PerformanceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return PerformanceSnapshot(
      timestamp: DateTime.parse(map['timestamp'] as String),
      tokenSpeed: (map['tokenSpeed'] as num).toDouble(),
      memoryUsageMb: (map['memoryUsageMb'] as num).toDouble(),
      cpuUsagePercent: (map['cpuUsagePercent'] as num).toDouble(),
      gpuUsagePercent: (map['gpuUsagePercent'] as num).toDouble(),
      batteryLevelPercent: (map['batteryLevelPercent'] as num).toDouble(),
      storageUsageGb: (map['storageUsageGb'] as num).toDouble(),
      modelId: map['modelId'] as String? ?? 'llama_3_2_3b',
      promptLength: map['promptLength'] as int? ?? 120,
      generationTimeMs: map['generationTimeMs'] as int? ?? 1200,
    );
  }
}
