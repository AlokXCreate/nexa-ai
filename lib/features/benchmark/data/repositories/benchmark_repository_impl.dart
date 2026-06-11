import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:localmind_ai/features/benchmark/domain/repositories/benchmark_repository.dart';

class BenchmarkRepositoryImpl implements BenchmarkRepository {
  static const String boxName = 'benchmarksBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  @override
  Future<List<BenchmarkResult>> getResults() async {
    final box = await _getBox();
    final list = <BenchmarkResult>[];
    for (final key in box.keys) {
      final val = box.get(key);
      if (val is Map) {
        try {
          list.add(BenchmarkResult.fromMap(val));
        } catch (_) {}
      }
    }
    // Sort chronologically (latest first)
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<void> saveResult(BenchmarkResult result) async {
    final box = await _getBox();
    await box.put(result.id, result.toMap());
  }

  @override
  Future<void> deleteResult(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
}
