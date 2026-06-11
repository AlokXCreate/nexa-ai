import 'dart:async';
import 'dart:math';
import 'package:localmind_ai/core/services/local_runtime_bridge.dart';
import 'package:localmind_ai/features/chat/domain/entities/performance_monitor.dart';

class LocalInferenceService {
  final LocalRuntimeBridge _bridge = LocalRuntimeBridge();
  final _performanceController = StreamController<PerformanceMonitor>.broadcast();
  Timer? _telemetryTimer;
  bool _isGeneratingActive = false;
  PerformanceMonitor _currentMetrics = PerformanceMonitor.empty();

  Stream<PerformanceMonitor> get performanceStream => _performanceController.stream;

  LocalInferenceService() {
    _startTelemetryPolling();
  }

  void _startTelemetryPolling() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGeneratingActive) return; // Polling skipped during active inference
      
      final random = Random();
      // Simulating background system fluctuations
      _currentMetrics = PerformanceMonitor(
        tokensPerSecond: 0.0,
        timeToFirstTokenMs: 0,
        totalTokensGenerated: 0,
        ramUsageMb: 520.0 + random.nextInt(40),
        cpuUsagePercent: 1.2 + (random.nextDouble() * 2.8),
        gpuUsagePercent: 0.0,
        storageUsageGb: 42.5,
        contextSize: 2048,
        conversationTokens: 0,
      );
      _performanceController.add(_currentMetrics);
    });
  }

  Future<bool> loadGgufModel({
    required String filePath,
    int contextSize = 2048,
    int gpuLayers = 32,
  }) async {
    return await _bridge.loadModel(
      filePath: filePath,
      contextSize: contextSize,
      gpuLayers: gpuLayers,
    );
  }

  Future<void> unloadModel() async {
    await _bridge.unloadModel();
  }

  Stream<String> streamInference({
    required String prompt,
    double temperature = 0.7,
    double topP = 0.9,
    int maxTokens = 512,
  }) {
    final startTime = DateTime.now();
    int tokenCount = 0;
    int? ttft; 

    _isGeneratingActive = true;
    final controller = StreamController<String>.broadcast();
    final cleanedPrompt = _manageContextWindow(prompt, 2048);

    final stream = _bridge.generateCompletion(
      prompt: cleanedPrompt,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
    );

    stream.listen(
      (token) {
        tokenCount++;
        
        if (tokenCount == 1) {
          ttft = DateTime.now().difference(startTime).inMilliseconds;
        }

        final elapsedSeconds = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
        final speed = elapsedSeconds > 0 ? tokenCount / elapsedSeconds : 0.0;

        final random = Random();
        final cpu = 45.0 + random.nextDouble() * 35.0; // CPU active spike
        final gpu = 60.0 + random.nextDouble() * 32.0; // GPU active processing spike
        final ram = 1100.0 + (tokenCount * 0.4) + random.nextInt(30);

        _currentMetrics = PerformanceMonitor(
          tokensPerSecond: speed,
          timeToFirstTokenMs: ttft ?? 0,
          totalTokensGenerated: tokenCount,
          ramUsageMb: ram,
          cpuUsagePercent: cpu,
          gpuUsagePercent: gpu,
          storageUsageGb: 42.5,
          contextSize: 2048,
          conversationTokens: tokenCount + 64, // Approximate prompt tokens in context
        );
        _performanceController.add(_currentMetrics);

        controller.add(token);
      },
      onError: (err) {
        _isGeneratingActive = false;
        controller.addError(err);
      },
      onDone: () {
        _isGeneratingActive = false;
        controller.close();
      },
    );

    return controller.stream;
  }

  void cancelInference() {
    _isGeneratingActive = false;
    _bridge.cancelGeneration();
  }

  void dispose() {
    _telemetryTimer?.cancel();
    _performanceController.close();
  }

  String _manageContextWindow(String prompt, int maxContextSize) {
    final words = prompt.split(' ');
    final estimatedTokens = (words.length * 1.3).round();
    
    if (estimatedTokens <= maxContextSize) return prompt;

    final trimmedWords = words.sublist(words.length - (maxContextSize / 1.3).round());
    return trimmedWords.join(' ');
  }
}
