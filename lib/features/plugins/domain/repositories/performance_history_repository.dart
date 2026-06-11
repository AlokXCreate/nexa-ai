import 'package:localmind_ai/features/plugins/domain/entities/performance_snapshot.dart';

abstract class PerformanceHistoryRepository {
  Future<void> saveSnapshot(PerformanceSnapshot snapshot);
  Future<List<PerformanceSnapshot>> getHistory();
  Future<void> clearHistory();
}
