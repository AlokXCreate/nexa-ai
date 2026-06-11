import 'package:localmind_ai/features/benchmark/domain/entities/benchmark_result.dart';

abstract class BenchmarkRepository {
  Future<List<BenchmarkResult>> getResults();
  Future<void> saveResult(BenchmarkResult result);
  Future<void> deleteResult(String id);
  Future<void> clearAll();
}
