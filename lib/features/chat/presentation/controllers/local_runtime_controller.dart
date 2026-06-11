import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/data/services/local_inference_service.dart';
import 'package:localmind_ai/features/chat/data/services/fallback_inference_manager.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/provider_response.dart';
import 'package:localmind_ai/features/chat/domain/entities/performance_monitor.dart';

class LocalRuntimeState {
  final bool isModelLoaded;
  final String? activeModelId;
  final bool isGenerating;
  final String currentGenerationText;
  final PerformanceMonitor performanceMetrics;
  final String? error;
  final bool isLoading;

  const LocalRuntimeState({
    this.isModelLoaded = false,
    this.activeModelId,
    this.isGenerating = false,
    this.currentGenerationText = '',
    this.performanceMetrics = PerformanceMonitor.empty(),
    this.error,
    this.isLoading = false,
  });

  LocalRuntimeState copyWith({
    bool? isModelLoaded,
    String? activeModelId,
    bool? isGenerating,
    String? currentGenerationText,
    PerformanceMonitor? performanceMetrics,
    String? error,
    bool? isLoading,
    bool clearError = false,
    bool clearModel = false,
  }) {
    return LocalRuntimeState(
      isModelLoaded: clearModel ? false : (isModelLoaded ?? this.isModelLoaded),
      activeModelId: clearModel ? null : (activeModelId ?? this.activeModelId),
      isGenerating: isGenerating ?? this.isGenerating,
      currentGenerationText: currentGenerationText ?? this.currentGenerationText,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocalRuntimeController extends StateNotifier<LocalRuntimeState> {
  final LocalInferenceService _service;
  final FallbackInferenceManager _fallbackManager;

  LocalRuntimeController(this._service, this._fallbackManager) : super(const LocalRuntimeState()) {
    _init();
  }

  void _init() {
    _fallbackManager.performanceStream.listen((metrics) {
      state = state.copyWith(performanceMetrics: metrics);
    });
  }

  Future<void> loadModel(String modelId, String filePath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    final success = await _service.loadGgufModel(
      filePath: filePath,
      contextSize: 2048,
      gpuLayers: 32, 
    );

    if (success) {
      state = state.copyWith(
        isModelLoaded: true,
        activeModelId: modelId,
        isGenerating: false,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isModelLoaded: false,
        isLoading: false,
        error: 'Failed to initialize GGUF model runtime on device.',
      );
    }
  }

  Future<void> unloadActiveModel() async {
    await _service.unloadModel();
    state = state.copyWith(clearModel: true);
  }

  void generateText(String prompt, String modelId, List<ChatMessage> history) async {
    final isCloud = await _fallbackManager.isCloudModel(modelId);
    if (!isCloud && !state.isModelLoaded) {
      state = state.copyWith(error: 'No local model initialized.');
      return;
    }

    state = state.copyWith(
      isGenerating: true,
      currentGenerationText: '',
      activeModelId: modelId,
    );
    
    final tokenStream = _fallbackManager.streamInference(
      prompt: prompt,
      history: history,
      modelId: modelId,
    );
    
    tokenStream.listen(
      (chunk) {
        state = state.copyWith(
          currentGenerationText: state.currentGenerationText + chunk.textDelta,
        );
      },
      onError: (err) {
        state = state.copyWith(isGenerating: false, error: err.toString());
      },
      onDone: () {
        state = state.copyWith(isGenerating: false);
      },
    );
  }

  void stopGeneration() {
    _service.cancelInference();
    state = state.copyWith(isGenerating: false);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final localInferenceServiceProvider = Provider<LocalInferenceService>((ref) {
  return LocalInferenceService();
});

final localRuntimeControllerProvider = StateNotifierProvider<LocalRuntimeController, LocalRuntimeState>((ref) {
  final service = ref.watch(localInferenceServiceProvider);
  final fallback = ref.watch(fallbackInferenceManagerProvider);
  return LocalRuntimeController(service, fallback);
});
