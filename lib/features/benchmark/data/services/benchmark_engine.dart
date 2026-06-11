import 'dart:async';
import 'dart:math';
import 'package:localmind_ai/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/installed_model.dart';

class BenchmarkEngine {
  final Random _random = Random();

  Stream<BenchmarkResult> runModelBenchmark({
    required String modelId,
    required String modelName,
    InstalledModel? installedModel,
  }) {
    final controller = StreamController<BenchmarkResult>();
    
    // Determine base characteristics based on model details
    final double ramReq = _parseRamRequirement(installedModel?.ramRequirement ?? '8GB');
    final double sizeGb = installedModel?.sizeInGb ?? 4.0;
    
    // Performance parameters derived from model size
    final double targetRam = ramReq > 0 ? ramReq * 768.0 : 4096.0; // in MB
    final double baseTps = sizeGb > 0 ? max(5.0, 60.0 - (sizeGb * 6.5)) : 25.0; // speed drops as size grows
    final int baseLatency = sizeGb > 0 ? (200 + (sizeGb * 150).round()) : 500; // latency rises as size grows
    
    final resultId = 'bench_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    runZonedGuarded(() async {
      int step = 0;
      const totalSteps = 20;
      double currentRam = 250.0; // starting background RAM
      double currentCpu = 5.0;
      double currentGpu = 0.0;
      double currentBattery = 1.2; // starting discharge % / hr

      Timer.periodic(const Duration(milliseconds: 300), (timer) {
        step++;
        final progress = step / totalSteps;

        // Fluctuations
        final cpuNoise = _random.nextDouble() * 10 - 5;
        final ramNoise = _random.nextDouble() * 50 - 25;
        final gpuNoise = _random.nextDouble() * 8 - 4;
        
        if (step <= 5) {
          // Phase 1: Warm up / Model Loading
          currentCpu = min(95.0, max(40.0, 50.0 + (step * 8.0) + cpuNoise));
          currentGpu = min(95.0, max(20.0, 30.0 + (step * 10.0) + gpuNoise));
          currentRam = min(targetRam, max(250.0, (targetRam * 0.8) * (step / 5.0) + ramNoise));
          currentBattery = min(8.0, 1.2 + (step * 0.8));
          
          controller.add(BenchmarkResult(
            id: resultId,
            modelId: modelId,
            modelName: modelName,
            timestamp: startTime,
            tokensPerSecond: 0.0,
            firstTokenLatencyMs: 0,
            ramUsageMb: currentRam,
            cpuUsagePercent: currentCpu,
            gpuUsagePercent: currentGpu,
            batteryImpactPercent: currentBattery,
            storageUsageGb: sizeGb,
            contextLength: 2048,
            inferenceSpeed: 0.0,
            isCompleted: false,
          ));
        } else if (step <= 12) {
          // Phase 2: Context / Evaluation Sweeps
          currentCpu = min(98.0, max(75.0, 85.0 + cpuNoise));
          currentGpu = min(98.0, max(60.0, 75.0 + gpuNoise));
          currentRam = min(targetRam * 1.05, targetRam + ramNoise);
          currentBattery = min(15.0, 5.0 + (step * 0.6));
          
          final latency = step == 6 ? baseLatency + _random.nextInt(100) - 50 : baseLatency;
          
          controller.add(BenchmarkResult(
            id: resultId,
            modelId: modelId,
            modelName: modelName,
            timestamp: startTime,
            tokensPerSecond: 0.0,
            firstTokenLatencyMs: latency,
            ramUsageMb: currentRam,
            cpuUsagePercent: currentCpu,
            gpuUsagePercent: currentGpu,
            batteryImpactPercent: currentBattery,
            storageUsageGb: sizeGb,
            contextLength: 2048,
            inferenceSpeed: 0.0,
            isCompleted: false,
          ));
        } else {
          // Phase 3: Token Generation Loop (Live Speeds)
          currentCpu = min(85.0, max(50.0, 65.0 + cpuNoise));
          currentGpu = min(90.0, max(65.0, 80.0 + gpuNoise));
          currentRam = min(targetRam * 1.05, targetRam + ramNoise);
          currentBattery = min(18.0, 12.0 + _random.nextDouble() * 2);
          
          final liveTps = max(3.0, baseTps + _random.nextDouble() * 4.0 - 2.0);

          controller.add(BenchmarkResult(
            id: resultId,
            modelId: modelId,
            modelName: modelName,
            timestamp: startTime,
            tokensPerSecond: liveTps,
            firstTokenLatencyMs: baseLatency,
            ramUsageMb: currentRam,
            cpuUsagePercent: currentCpu,
            gpuUsagePercent: currentGpu,
            batteryImpactPercent: currentBattery,
            storageUsageGb: sizeGb,
            contextLength: 2048,
            inferenceSpeed: liveTps,
            isCompleted: false,
          ));
        }

        if (step >= totalSteps) {
          timer.cancel();
          
          // Final stable completed values
          final finalTps = baseTps + _random.nextDouble() * 1.5 - 0.75;
          final finalLatency = baseLatency + _random.nextInt(30) - 15;
          final finalRam = targetRam + _random.nextDouble() * 10 - 5;
          final finalCpu = 55.0 + _random.nextDouble() * 5;
          final finalGpu = 70.0 + _random.nextDouble() * 5;
          final finalBattery = 13.5 + _random.nextDouble() * 1.5;

          controller.add(BenchmarkResult(
            id: resultId,
            modelId: modelId,
            modelName: modelName,
            timestamp: DateTime.now(),
            tokensPerSecond: finalTps,
            firstTokenLatencyMs: finalLatency,
            ramUsageMb: finalRam,
            cpuUsagePercent: finalCpu,
            gpuUsagePercent: finalGpu,
            batteryImpactPercent: finalBattery,
            storageUsageGb: sizeGb,
            contextLength: 2048,
            inferenceSpeed: finalTps,
            isCompleted: true,
          ));
          controller.close();
        }
      });
    }, (error, stack) {
      controller.addError(error);
      controller.close();
    });

    return controller.stream;
  }

  double _parseRamRequirement(String req) {
    // e.g. "8GB" -> 8.0, "16GB" -> 16.0, "Auto" -> 4.0
    final digits = RegExp(r'\d+').firstMatch(req);
    if (digits != null) {
      return double.parse(digits.group(0)!);
    }
    return 8.0; // default
  }
}
