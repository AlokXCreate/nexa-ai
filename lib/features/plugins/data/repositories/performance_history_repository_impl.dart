import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/plugins/domain/entities/performance_snapshot.dart';
import 'package:localmind_ai/features/plugins/domain/repositories/performance_history_repository.dart';

class PerformanceHistoryRepositoryImpl implements PerformanceHistoryRepository {
  static const String boxName = 'performanceHistoryBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  @override
  Future<void> saveSnapshot(PerformanceSnapshot snapshot) async {
    final box = await _getBox();
    await box.add(snapshot.toMap());
  }

  @override
  Future<void> clearHistory() async {
    final box = await _getBox();
    await box.clear();
  }

  @override
  Future<List<PerformanceSnapshot>> getHistory() async {
    final box = await _getBox();
    if (box.isEmpty) {
      await _preseedHistory(box);
    }
    return box.values.map((map) => PerformanceSnapshot.fromMap(map as Map)).toList();
  }

  Future<void> _preseedHistory(Box box) async {
    final now = DateTime.now();
    final list = [
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 6, hours: 2)),
        tokenSpeed: 28.5,
        memoryUsageMb: 950.0,
        cpuUsagePercent: 35.0,
        gpuUsagePercent: 0.0,
        batteryLevelPercent: 88.0,
        storageUsageGb: 42.5,
        modelId: 'llama_3_2_3b',
        promptLength: 120,
        generationTimeMs: 1500,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 5, hours: 4)),
        tokenSpeed: 30.2,
        memoryUsageMb: 960.0,
        cpuUsagePercent: 42.0,
        gpuUsagePercent: 0.0,
        batteryLevelPercent: 85.0,
        storageUsageGb: 42.5,
        modelId: 'llama_3_2_3b',
        promptLength: 180,
        generationTimeMs: 2200,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 5, hours: 1)),
        tokenSpeed: 45.4,
        memoryUsageMb: 1250.0,
        cpuUsagePercent: 65.0,
        gpuUsagePercent: 70.0,
        batteryLevelPercent: 81.0,
        storageUsageGb: 42.5,
        modelId: 'deepseek_coder',
        promptLength: 250,
        generationTimeMs: 1800,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 4, hours: 6)),
        tokenSpeed: 29.8,
        memoryUsageMb: 955.0,
        cpuUsagePercent: 38.0,
        gpuUsagePercent: 0.0,
        batteryLevelPercent: 78.0,
        storageUsageGb: 42.5,
        modelId: 'llama_3_2_3b',
        promptLength: 90,
        generationTimeMs: 1200,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 4, hours: 3)),
        tokenSpeed: 46.8,
        memoryUsageMb: 1240.0,
        cpuUsagePercent: 68.0,
        gpuUsagePercent: 72.0,
        batteryLevelPercent: 74.0,
        storageUsageGb: 42.5,
        modelId: 'deepseek_coder',
        promptLength: 320,
        generationTimeMs: 2500,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 3, hours: 5)),
        tokenSpeed: 31.0,
        memoryUsageMb: 970.0,
        cpuUsagePercent: 40.0,
        gpuUsagePercent: 0.0,
        batteryLevelPercent: 69.0,
        storageUsageGb: 42.5,
        modelId: 'llama_3_2_3b',
        promptLength: 140,
        generationTimeMs: 1600,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 3, hours: 2)),
        tokenSpeed: 44.2,
        memoryUsageMb: 1260.0,
        cpuUsagePercent: 62.0,
        gpuUsagePercent: 74.0,
        batteryLevelPercent: 65.0,
        storageUsageGb: 42.5,
        modelId: 'deepseek_coder',
        promptLength: 400,
        generationTimeMs: 3100,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 2, hours: 4)),
        tokenSpeed: 32.5,
        memoryUsageMb: 980.0,
        cpuUsagePercent: 44.0,
        gpuUsagePercent: 0.0,
        batteryLevelPercent: 92.0, // Charged
        storageUsageGb: 42.5,
        modelId: 'llama_3_2_3b',
        promptLength: 210,
        generationTimeMs: 2400,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 2, hours: 1)),
        tokenSpeed: 47.5,
        memoryUsageMb: 1280.0,
        cpuUsagePercent: 70.0,
        gpuUsagePercent: 78.0,
        batteryLevelPercent: 87.0,
        storageUsageGb: 42.5,
        modelId: 'deepseek_coder',
        promptLength: 150,
        generationTimeMs: 1100,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 1, hours: 6)),
        tokenSpeed: 33.1,
        memoryUsageMb: 985.0,
        cpuUsagePercent: 41.0,
        gpuUsagePercent: 0.0,
        batteryLevelPercent: 82.0,
        storageUsageGb: 42.5,
        modelId: 'llama_3_2_3b',
        promptLength: 110,
        generationTimeMs: 1400,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        tokenSpeed: 48.2,
        memoryUsageMb: 1290.0,
        cpuUsagePercent: 72.0,
        gpuUsagePercent: 80.0,
        batteryLevelPercent: 77.0,
        storageUsageGb: 42.5,
        modelId: 'deepseek_coder',
        promptLength: 280,
        generationTimeMs: 2100,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(hours: 8)),
        tokenSpeed: 34.0,
        memoryUsageMb: 990.0,
        cpuUsagePercent: 45.0,
        gpuUsagePercent: 0.0,
        batteryLevelPercent: 71.0,
        storageUsageGb: 42.5,
        modelId: 'llama_3_2_3b',
        promptLength: 160,
        generationTimeMs: 1900,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(hours: 5)),
        tokenSpeed: 49.0,
        memoryUsageMb: 1300.0,
        cpuUsagePercent: 74.0,
        gpuUsagePercent: 82.0,
        batteryLevelPercent: 66.0,
        storageUsageGb: 42.5,
        modelId: 'deepseek_coder',
        promptLength: 350,
        generationTimeMs: 2600,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(hours: 2)),
        tokenSpeed: 35.2,
        memoryUsageMb: 995.0,
        cpuUsagePercent: 43.0,
        gpuUsagePercent: 0.0,
        batteryLevelPercent: 61.0,
        storageUsageGb: 42.5,
        modelId: 'llama_3_2_3b',
        promptLength: 130,
        generationTimeMs: 1500,
      ),
      PerformanceSnapshot(
        timestamp: now.subtract(const Duration(minutes: 30)),
        tokenSpeed: 50.5,
        memoryUsageMb: 1320.0,
        cpuUsagePercent: 76.0,
        gpuUsagePercent: 85.0,
        batteryLevelPercent: 55.0,
        storageUsageGb: 42.5,
        modelId: 'deepseek_coder',
        promptLength: 220,
        generationTimeMs: 1600,
      ),
    ];

    for (final snapshot in list) {
      await box.add(snapshot.toMap());
    }
  }
}
