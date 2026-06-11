import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:localmind_ai/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:localmind_ai/features/benchmark/data/repositories/benchmark_repository_impl.dart';
import 'package:localmind_ai/features/benchmark/data/services/benchmark_engine.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';
import 'package:path_provider/path_provider.dart';

class BenchmarkState {
  final List<BenchmarkResult> results;
  final bool isBenchmarking;
  final String? activeModelId;
  final double progress;
  final BenchmarkResult? activeRunMetrics;
  final bool isLoading;
  final String? error;
  final String? lastExportPath;

  const BenchmarkState({
    this.results = const [],
    this.isBenchmarking = false,
    this.activeModelId,
    this.progress = 0.0,
    this.activeRunMetrics,
    this.isLoading = false,
    this.error,
    this.lastExportPath,
  });

  BenchmarkState copyWith({
    List<BenchmarkResult>? results,
    bool? isBenchmarking,
    String? activeModelId,
    double? progress,
    BenchmarkResult? activeRunMetrics,
    bool? isLoading,
    String? error,
    String? lastExportPath,
    bool clearError = false,
    bool clearExportPath = false,
  }) {
    return BenchmarkState(
      results: results ?? this.results,
      isBenchmarking: isBenchmarking ?? this.isBenchmarking,
      activeModelId: activeModelId ?? this.activeModelId,
      progress: progress ?? this.progress,
      activeRunMetrics: activeRunMetrics ?? this.activeRunMetrics,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastExportPath: clearExportPath ? null : (lastExportPath ?? this.lastExportPath),
    );
  }
}

class BenchmarkController extends StateNotifier<BenchmarkState> {
  final BenchmarkRepository _repository;
  final BenchmarkEngine _engine = BenchmarkEngine();
  final Ref _ref;

  BenchmarkController(this._repository, this._ref) : super(const BenchmarkState()) {
    loadResults();
  }

  Future<void> loadResults() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await _repository.getResults();
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load benchmark history: $e');
    }
  }

  Future<void> runBenchmark(String modelId) async {
    if (state.isBenchmarking) return;

    // Get model details
    final installedState = _ref.read(installedModelsControllerProvider);
    final installedIndex = installedState.installedModels.indexWhere((m) => m.id == modelId);
    final modelName = installedIndex != -1 
        ? installedState.installedModels[installedIndex].localName 
        : modelId.replaceAll('_', ' ');
    final installedModel = installedIndex != -1 ? installedState.installedModels[installedIndex] : null;

    state = state.copyWith(
      isBenchmarking: true,
      activeModelId: modelId,
      progress: 0.0,
      activeRunMetrics: null,
      clearError: true,
    );

    int tickCount = 0;
    const maxTicks = 20;

    final benchmarkStream = _engine.runModelBenchmark(
      modelId: modelId,
      modelName: modelName,
      installedModel: installedModel,
    );

    benchmarkStream.listen(
      (metrics) async {
        tickCount++;
        final currentProgress = tickCount / maxTicks;
        
        state = state.copyWith(
          progress: currentProgress > 1.0 ? 1.0 : currentProgress,
          activeRunMetrics: metrics,
        );

        if (metrics.isCompleted) {
          await _repository.saveResult(metrics);
          await loadResults();
          state = state.copyWith(
            isBenchmarking: false,
            activeModelId: null,
            activeRunMetrics: null,
            progress: 1.0,
          );
        }
      },
      onError: (err) {
        state = state.copyWith(
          isBenchmarking: false,
          activeModelId: null,
          activeRunMetrics: null,
          progress: 0.0,
          error: 'Benchmark failed: $err',
        );
      },
    );
  }

  Future<void> deleteResult(String id) async {
    try {
      await _repository.deleteResult(id);
      await loadResults();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete record: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearAll();
      await loadResults();
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear history: $e');
    }
  }

  Future<String?> exportResultsCsv() async {
    state = state.copyWith(clearExportPath: true);
    try {
      final buffer = StringBuffer();
      // Write header
      buffer.writeln('ID,Model ID,Model Name,Timestamp,TokensPerSec,FirstTokenLatencyMs,RAMUsageMb,CPUUsagePercent,GPUUsagePercent,BatteryImpactPercent,StorageUsageGb,PerformanceScore');
      
      for (final r in state.results) {
        buffer.writeln(
          '${r.id},${r.modelId},"${r.modelName}",${r.timestamp.toIso8601String()},${r.tokensPerSecond.toStringAsFixed(2)},${r.firstTokenLatencyMs},${r.ramUsageMb.toStringAsFixed(1)},${r.cpuUsagePercent.toStringAsFixed(1)},${r.gpuUsagePercent.toStringAsFixed(1)},${r.batteryImpactPercent.toStringAsFixed(2)},${r.storageUsageGb.toStringAsFixed(2)},${r.performanceScore.toStringAsFixed(1)}'
        );
      }

      final csvContent = buffer.toString();
      final path = await _writeExportFile(csvContent, 'csv');
      state = state.copyWith(lastExportPath: path);
      return path;
    } catch (e) {
      state = state.copyWith(error: 'CSV export failed: $e');
      return null;
    }
  }

  Future<String?> exportResultsJson() async {
    state = state.copyWith(clearExportPath: true);
    try {
      final list = state.results.map((r) => r.toMap()).toList();
      final jsonContent = const JsonEncoder.withIndent('  ').convert(list);
      final path = await _writeExportFile(jsonContent, 'json');
      state = state.copyWith(lastExportPath: path);
      return path;
    } catch (e) {
      state = state.copyWith(error: 'JSON export failed: $e');
      return null;
    }
  }

  Future<String> _writeExportFile(String content, String extension) async {
    final settings = _ref.read(settingsControllerProvider).settings;
    String dirPath = settings.downloadLocation;
    
    // Fallback if settings path is not writable or is empty/mock
    if (dirPath.isEmpty || dirPath == '/localmind/models') {
      final appDir = await getApplicationDocumentsDirectory();
      dirPath = '${appDir.path}/localmind/exports';
    }

    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('$dirPath/nexa_benchmark_results_$timestamp.$extension');
    await file.writeAsString(content);
    return file.path;
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final benchmarkRepositoryProvider = Provider<BenchmarkRepository>((ref) {
  return BenchmarkRepositoryImpl();
});

final benchmarkControllerProvider = StateNotifierProvider<BenchmarkController, BenchmarkState>((ref) {
  final repo = ref.watch(benchmarkRepositoryProvider);
  return BenchmarkController(repo, ref);
});
