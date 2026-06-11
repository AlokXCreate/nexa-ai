import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/entities/compare_session.dart';
import 'package:localmind_ai/features/chat/domain/entities/compare_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/model_response.dart';
import 'package:localmind_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/rag_documents_controller.dart'; // exposes chatRepositoryProvider
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';
import 'package:localmind_ai/features/chat/data/services/local_inference_service.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/chat/domain/entities/performance_monitor.dart';

class MultiModelState {
  final List<CompareSession> compareSessions;
  final String? activeSessionId;
  final List<CompareMessage> messages;
  final bool isLoading;
  final List<String> selectedModelIds;
  final bool isComparing;
  final String? error;

  const MultiModelState({
    this.compareSessions = const [],
    this.activeSessionId,
    this.messages = const [],
    this.isLoading = false,
    this.selectedModelIds = const [],
    this.isComparing = false,
    this.error,
  });

  MultiModelState copyWith({
    List<CompareSession>? compareSessions,
    String? activeSessionId,
    List<CompareMessage>? messages,
    bool? isLoading,
    List<String>? selectedModelIds,
    bool? isComparing,
    String? error,
    bool clearError = false,
  }) {
    return MultiModelState(
      compareSessions: compareSessions ?? this.compareSessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      selectedModelIds: selectedModelIds ?? this.selectedModelIds,
      isComparing: isComparing ?? this.isComparing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MultiModelController extends StateNotifier<MultiModelState> {
  final ChatRepository _repository;
  final Ref _ref;
  StreamSubscription? _performanceSubscription;
  StreamSubscription? _inferenceSubscription;
  bool _isCancelled = false;

  MultiModelController(this._repository, this._ref) : super(const MultiModelState()) {
    loadCompareSessions();
  }

  LocalInferenceService get _inferenceService => _ref.read(localInferenceServiceProvider);

  Future<void> loadCompareSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessions = await _repository.getCompareSessions();
      sessions.sort((a, b) => b.lastActiveTime.compareTo(a.lastActiveTime));
      state = state.copyWith(compareSessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load comparison sessions: $e');
    }
  }

  Future<void> selectCompareSession(String sessionId) async {
    state = state.copyWith(isLoading: true, activeSessionId: sessionId, clearError: true);
    try {
      final sessionIndex = state.compareSessions.indexWhere((s) => s.id == sessionId);
      List<String> selectedModels = [];
      if (sessionIndex != -1) {
        selectedModels = state.compareSessions[sessionIndex].modelIds;
        
        // Update last active time
        final updatedSession = state.compareSessions[sessionIndex].copyWith(lastActiveTime: DateTime.now());
        await _repository.saveCompareSession(updatedSession);
        
        // Refresh sessions list
        final updatedSessions = List<CompareSession>.from(state.compareSessions);
        updatedSessions[sessionIndex] = updatedSession;
        updatedSessions.sort((a, b) => b.lastActiveTime.compareTo(a.lastActiveTime));
        state = state.copyWith(compareSessions: updatedSessions);
      }

      final msgs = await _repository.getCompareMessages(sessionId);
      state = state.copyWith(
        messages: msgs,
        selectedModelIds: selectedModels,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to select session: $e');
    }
  }

  Future<void> createCompareSession(List<String> modelIds, {String? title}) async {
    if (modelIds.isEmpty) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final installedState = _ref.read(installedModelsControllerProvider);
      final modelNames = modelIds.map((id) {
        final m = installedState.installedModels.firstWhere((element) => element.id == id);
        return m.localName;
      }).join(' + ');

      final session = CompareSession(
        id: 'cmp_sess_${DateTime.now().millisecondsSinceEpoch}',
        title: title ?? 'Compare: $modelNames',
        modelIds: modelIds,
        createdAt: DateTime.now(),
        lastActiveTime: DateTime.now(),
      );

      await _repository.saveCompareSession(session);
      
      final updatedSessions = [session, ...state.compareSessions];
      state = state.copyWith(
        compareSessions: updatedSessions,
        activeSessionId: session.id,
        selectedModelIds: modelIds,
        messages: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to create session: $e');
    }
  }

  Future<void> deleteCompareSession(String sessionId) async {
    try {
      await _repository.deleteCompareSession(sessionId);
      final updatedSessions = state.compareSessions.where((s) => s.id != sessionId).toList();
      
      String? nextActiveSessionId = state.activeSessionId;
      List<CompareMessage> nextMessages = state.messages;
      List<String> nextSelectedModels = state.selectedModelIds;

      if (state.activeSessionId == sessionId) {
        if (updatedSessions.isNotEmpty) {
          nextActiveSessionId = updatedSessions.first.id;
          nextMessages = await _repository.getCompareMessages(nextActiveSessionId);
          nextSelectedModels = updatedSessions.first.modelIds;
        } else {
          nextActiveSessionId = null;
          nextMessages = [];
          nextSelectedModels = [];
        }
      }

      state = state.copyWith(
        compareSessions: updatedSessions,
        activeSessionId: nextActiveSessionId,
        messages: nextMessages,
        selectedModelIds: nextSelectedModels,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete session: $e');
    }
  }

  void toggleModelSelection(String modelId) {
    final list = List<String>.from(state.selectedModelIds);
    if (list.contains(modelId)) {
      list.remove(modelId);
    } else {
      list.add(modelId);
    }
    state = state.copyWith(selectedModelIds: list);
  }

  void selectModels(List<String> modelIds) {
    state = state.copyWith(selectedModelIds: modelIds);
  }

  Future<void> sendComparePrompt(String promptContent) async {
    if (state.isComparing) return;
    
    // Ensure we have a valid compare session
    String? sessionId = state.activeSessionId;
    if (sessionId == null) {
      if (state.selectedModelIds.isEmpty) {
        state = state.copyWith(error: 'Please select at least one model to compare.');
        return;
      }
      await createCompareSession(state.selectedModelIds);
      sessionId = state.activeSessionId;
      if (sessionId == null) return;
    }

    final session = state.compareSessions.firstWhere((s) => s.id == sessionId);
    _isCancelled = false;

    // 1. Initialize empty responses for selected models
    final Map<String, ModelResponse> responses = {};
    for (final modelId in session.modelIds) {
      responses[modelId] = ModelResponse.empty(modelId);
    }

    final compareMessage = CompareMessage(
      id: 'cmp_msg_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      prompt: promptContent,
      modelResponses: responses,
      timestamp: DateTime.now(),
    );

    // Add prompt message to UI
    state = state.copyWith(
      messages: [...state.messages, compareMessage],
      isComparing: true,
      clearError: true,
    );

    // 2. Unload any model currently active in standard runtime
    try {
      await _ref.read(localRuntimeControllerProvider.notifier).unloadActiveModel();
    } catch (_) {}

    // 3. Sequentially run inference on each selected model
    for (final modelId in session.modelIds) {
      if (_isCancelled) break;

      final installedState = _ref.read(installedModelsControllerProvider);
      final modelIndex = installedState.installedModels.indexWhere((m) => m.id == modelId);

      if (modelIndex == -1) {
        // Model not downloaded
        _updateMessageResponse(
          compareMessage.id,
          modelId,
          responses[modelId]!.copyWith(
            content: 'Error: Model is not downloaded on this device.',
            isQueued: false,
            isGenerating: false,
          ),
        );
        continue;
      }

      final installedModel = installedState.installedModels[modelIndex];

      // Mark model as active/generating
      _updateMessageResponse(
        compareMessage.id,
        modelId,
        responses[modelId]!.copyWith(
          isQueued: false,
          isGenerating: true,
        ),
      );

      // Load model file
      final loadSuccess = await _inferenceService.loadGgufModel(
        filePath: installedModel.filePath,
        contextSize: 2048,
        gpuLayers: 32,
      );

      if (!loadSuccess) {
        _updateMessageResponse(
          compareMessage.id,
          modelId,
          responses[modelId]!.copyWith(
            content: 'Error: Failed to load GGUF model into local RAM.',
            isQueued: false,
            isGenerating: false,
          ),
        );
        continue;
      }

      if (_isCancelled) {
        await _inferenceService.unloadModel();
        break;
      }

      // Stream generation
      final completer = Completer<void>();
      
      // Listen to performance metrics
      _performanceSubscription = _inferenceService.performanceStream.listen((metrics) {
        final currentMsgIndex = state.messages.indexWhere((m) => m.id == compareMessage.id);
        if (currentMsgIndex != -1) {
          final currentResp = state.messages[currentMsgIndex].modelResponses[modelId]!;
          _updateMessageResponse(
            compareMessage.id,
            modelId,
            currentResp.copyWith(
              tokensPerSecond: metrics.tokensPerSecond,
              timeToFirstTokenMs: metrics.timeToFirstTokenMs,
              totalTokens: metrics.totalTokensGenerated,
              ramUsageMb: metrics.ramUsageMb,
            ),
          );
        }
      });

      final inferenceStream = _inferenceService.streamInference(prompt: promptContent);
      _inferenceSubscription = inferenceStream.listen(
        (token) {
          final currentMsgIndex = state.messages.indexWhere((m) => m.id == compareMessage.id);
          if (currentMsgIndex != -1) {
            final currentResp = state.messages[currentMsgIndex].modelResponses[modelId]!;
            _updateMessageResponse(
              compareMessage.id,
              modelId,
              currentResp.copyWith(
                content: currentResp.content + token,
              ),
            );
          }
        },
        onError: (err) {
          final currentMsgIndex = state.messages.indexWhere((m) => m.id == compareMessage.id);
          if (currentMsgIndex != -1) {
            final currentResp = state.messages[currentMsgIndex].modelResponses[modelId]!;
            _updateMessageResponse(
              compareMessage.id,
              modelId,
              currentResp.copyWith(
                content: currentResp.content + '\n[Generation Error: $err]',
                isGenerating: false,
              ),
            );
          }
          _cleanupSubscriptions();
          completer.complete();
        },
        onDone: () {
          final currentMsgIndex = state.messages.indexWhere((m) => m.id == compareMessage.id);
          if (currentMsgIndex != -1) {
            final currentResp = state.messages[currentMsgIndex].modelResponses[modelId]!;
            _updateMessageResponse(
              compareMessage.id,
              modelId,
              currentResp.copyWith(
                isGenerating: false,
              ),
            );
          }
          _cleanupSubscriptions();
          completer.complete();
        },
      );

      await completer.future;
      await _inferenceService.unloadModel();
    }

    // Finished comparison
    state = state.copyWith(isComparing: false);
    
    // Save final message state to Hive database
    final finalMsgIndex = state.messages.indexWhere((m) => m.id == compareMessage.id);
    if (finalMsgIndex != -1) {
      await _repository.saveCompareMessage(sessionId, state.messages[finalMsgIndex]);
    }
  }

  void stopComparison() {
    _isCancelled = true;
    _inferenceService.cancelInference();
    _cleanupSubscriptions();
    
    // Find active generating responses and stop them
    if (state.messages.isNotEmpty) {
      final lastMsg = state.messages.last;
      final updatedResponses = Map<String, ModelResponse>.from(lastMsg.modelResponses);
      var modified = false;

      updatedResponses.forEach((modelId, response) {
        if (response.isGenerating || response.isQueued) {
          updatedResponses[modelId] = response.copyWith(
            isGenerating: false,
            isQueued: false,
            content: response.content + (response.isGenerating ? '\n[Cancelled by user]' : '\n[Queued generation cancelled]'),
          );
          modified = true;
        }
      });

      if (modified) {
        final updatedMsg = lastMsg.copyWith(modelResponses: updatedResponses);
        state = state.copyWith(
          messages: [...state.messages.sublist(0, state.messages.length - 1), updatedMsg],
        );
        _repository.saveCompareMessage(state.activeSessionId!, updatedMsg);
      }
    }
    
    state = state.copyWith(isComparing: false);
  }

  void _updateMessageResponse(String msgId, String modelId, ModelResponse response) {
    final index = state.messages.indexWhere((m) => m.id == msgId);
    if (index == -1) return;

    final msg = state.messages[index];
    final updatedResponses = Map<String, ModelResponse>.from(msg.modelResponses);
    updatedResponses[modelId] = response;

    final updatedMsg = msg.copyWith(modelResponses: updatedResponses);
    final updatedList = List<CompareMessage>.from(state.messages);
    updatedList[index] = updatedMsg;

    state = state.copyWith(messages: updatedList);
  }

  void _cleanupSubscriptions() {
    _performanceSubscription?.cancel();
    _performanceSubscription = null;
    _inferenceSubscription?.cancel();
    _inferenceSubscription = null;
  }

  String exportComparison(CompareMessage message, String format) {
    final installedState = _ref.read(installedModelsControllerProvider);
    
    // Helper to get human readable name
    String getModelName(String modelId) {
      final idx = installedState.installedModels.indexWhere((m) => m.id == modelId);
      if (idx != -1) {
        return installedState.installedModels[idx].localName;
      }
      return modelId;
    }

    if (format.toLowerCase() == 'csv') {
      final buffer = StringBuffer();
      buffer.writeln('Model,Tokens Per Second,TTFT (ms),RAM Usage (MB),Response');
      message.modelResponses.forEach((modelId, response) {
        final name = getModelName(modelId);
        final cleanContent = response.content.replaceAll('"', '""');
        buffer.writeln('"$name",${response.tokensPerSecond.toStringAsFixed(1)},${response.timeToFirstTokenMs},${response.ramUsageMb.toStringAsFixed(0)},"$cleanContent"');
      });
      return buffer.toString();
    } else {
      // Default to markdown
      final buffer = StringBuffer();
      buffer.writeln('### Multi-Model Comparison: "${message.prompt}"\n');
      buffer.writeln('| Model | Speed | Latency (TTFT) | Memory (RAM) | Response |');
      buffer.writeln('| --- | --- | --- | --- | --- |');
      message.modelResponses.forEach((modelId, response) {
        final name = getModelName(modelId);
        final cleanContent = response.content.replaceAll('\n', ' ');
        buffer.writeln('| **$name** | ${response.tokensPerSecond.toStringAsFixed(1)} tok/s | ${response.timeToFirstTokenMs} ms | ${response.ramUsageMb.toStringAsFixed(0)} MB | $cleanContent |');
      });
      return buffer.toString();
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _cleanupSubscriptions();
    super.dispose();
  }
}

final multiModelControllerProvider = StateNotifierProvider<MultiModelController, MultiModelState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return MultiModelController(repo, ref);
});
