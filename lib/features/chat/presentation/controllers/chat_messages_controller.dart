import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_session.dart';
import 'package:localmind_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:localmind_ai/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:localmind_ai/features/chat/data/services/rag_service.dart';
import 'package:localmind_ai/features/chat/data/services/fallback_inference_manager.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_sessions_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';

class ChatMessagesState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? activeSessionId;
  final String? error;

  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.activeSessionId,
    this.error,
  });

  ChatMessagesState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? activeSessionId,
    String? error,
    bool clearError = false,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatMessagesController extends StateNotifier<ChatMessagesState> {
  final ChatRepository _repository;
  final RagService _ragService = RagService();
  final Ref _ref;

  // Track temporary parameters for a stream capture
  List<String>? _activeGenSources;

  ChatMessagesController(this._repository, this._ref) : super(const ChatMessagesState()) {
    // Listen to active session changes
    _ref.listen<ChatSessionsState>(chatSessionsControllerProvider, (prev, next) {
      if (next.activeSessionId != state.activeSessionId) {
        state = state.copyWith(activeSessionId: next.activeSessionId);
        if (next.activeSessionId != null) {
          loadMessages(next.activeSessionId!);
        } else {
          state = state.copyWith(messages: []);
        }
      }
    });

    // Listen to LLM runtime generation completion
    _ref.listen<LocalRuntimeState>(localRuntimeControllerProvider, (prev, next) {
      if (prev != null && prev.isGenerating && !next.isGenerating && state.activeSessionId != null) {
        // Model finished generation, finalize saving message to Hive
        _saveGeneratedMessage(next.currentGenerationText);
      }
    });
  }

  Future<void> loadMessages(String sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getMessages(sessionId);
      state = state.copyWith(messages: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load messages: $e');
    }
  }

  Future<void> sendMessage(String content) async {
    final sessionId = state.activeSessionId;
    if (sessionId == null) return;

    // Get active session configurations
    final sessionsState = _ref.read(chatSessionsControllerProvider);
    final session = sessionsState.sessions.firstWhere((s) => s.id == sessionId);

    // 1. Create and save User Message
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      content: content,
      timestamp: DateTime.now(),
    );
    final isIncognito = _ref.read(securityControllerProvider).config.isIncognitoActive;
    if (!isIncognito) {
      await _repository.saveMessage(sessionId, userMsg);
    }
    
    // Copy the history before appending the new message
    final history = List<ChatMessage>.from(state.messages);

    // Optimistic UI update
    state = state.copyWith(messages: [...state.messages, userMsg]);

    await _generateResponse(
      prompt: content,
      history: history,
      session: session,
    );
  }

  Future<void> editMessage(String messageId, String newContent) async {
    final sessionId = state.activeSessionId;
    if (sessionId == null) return;

    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    // Remove all subsequent messages in UI list and database
    final keptMessages = state.messages.sublist(0, index + 1);
    final deletedMessages = state.messages.sublist(index + 1);

    final isIncognito = _ref.read(securityControllerProvider).config.isIncognitoActive;
    if (!isIncognito) {
      for (final m in deletedMessages) {
        await _repository.deleteMessage(sessionId, m.id);
      }
    }

    // Update the message content
    final originalMsg = state.messages[index];
    final updatedMsg = originalMsg.copyWith(content: newContent, isEdited: true);
    if (!isIncognito) {
      await _repository.saveMessage(sessionId, updatedMsg);
    }

    // History is all messages prior to the edited message
    final history = state.messages.sublist(0, index);

    state = state.copyWith(messages: [...history, updatedMsg]);

    final sessionsState = _ref.read(chatSessionsControllerProvider);
    final session = sessionsState.sessions.firstWhere((s) => s.id == sessionId);

    await _generateResponse(
      prompt: newContent,
      history: history,
      session: session,
    );
  }

  Future<void> _generateResponse({
    required String prompt,
    required List<ChatMessage> history,
    required ChatSession session,
  }) async {
    // 2. Run RAG Pipeline (Retrieve Context)
    _activeGenSources = null;
    String finalPrompt = prompt;
    final useRag = session.useRag ?? true;

    if (useRag) {
      final activeChunks = await _repository.getActiveChunks();
      if (activeChunks.isNotEmpty) {
        final docs = await _repository.getDocuments();
        final Map<String, String> docNames = {for (var d in docs) d.id: d.name};

        final matches = _ragService.retrieveRelevantChunks(
          query: prompt,
          allChunks: activeChunks,
          docNames: docNames,
          topK: 3,
        );

        if (matches.isNotEmpty) {
          _activeGenSources = matches.map((m) => '${m.documentName} (Match Score: ${(m.score * 100).toStringAsFixed(0)}%)\n"${m.chunk.text}"').toList();
          
          final systemPromptOverride = session.systemPrompt ?? 'You are a helpful, local AI assistant.';
          finalPrompt = _ragService.buildRagPrompt(
            systemPrompt: systemPromptOverride,
            matches: matches,
            userQuery: prompt,
          );
        }
      }
    }

    // 3. Ensure GGUF model is loaded in local runtime (skip if Cloud model)
    final fallbackManager = _ref.read(fallbackInferenceManagerProvider);
    final isCloud = await fallbackManager.isCloudModel(session.modelId);

    if (isCloud) {
      // Trigger cloud/fallback inference streaming
      _ref.read(localRuntimeControllerProvider.notifier).generateText(finalPrompt, session.modelId, history);
    } else {
      final installedState = _ref.read(installedModelsControllerProvider);
      final installedIndex = installedState.installedModels.indexWhere((m) => m.id == session.modelId);
      if (installedIndex == -1) {
        state = state.copyWith(error: 'Active model is not downloaded on this device.');
        return;
      }

      final installedModel = installedState.installedModels[installedIndex];
      final runtimeState = _ref.read(localRuntimeControllerProvider);

      if (!runtimeState.isModelLoaded || runtimeState.activeModelId != session.modelId) {
        // Trigger load model
        await _ref.read(localRuntimeControllerProvider.notifier).loadModel(session.modelId, installedModel.filePath);
      }

      // Trigger local inference streaming
      _ref.read(localRuntimeControllerProvider.notifier).generateText(finalPrompt, session.modelId, history);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final sessionId = state.activeSessionId;
    if (sessionId == null) return;

    try {
      final isIncognito = _ref.read(securityControllerProvider).config.isIncognitoActive;
      if (!isIncognito) {
        await _repository.deleteMessage(sessionId, messageId);
      }
      final updatedList = state.messages.where((m) => m.id != messageId).toList();
      state = state.copyWith(messages: updatedList);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete message: $e');
    }
  }

  Future<void> _saveGeneratedMessage(String responseContent) async {
    final sessionId = state.activeSessionId;
    if (sessionId == null) return;

    final aiMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.ai,
      content: responseContent,
      timestamp: DateTime.now(),
      sources: _activeGenSources,
    );

    final isIncognito = _ref.read(securityControllerProvider).config.isIncognitoActive;
    if (!isIncognito) {
      await _repository.saveMessage(sessionId, aiMsg);
    }
    
    // Add to list and clear generation sources references cache
    state = state.copyWith(messages: [...state.messages, aiMsg]);
    _activeGenSources = null;
    
    // Refresh sessions last active timestamp
    _ref.read(chatSessionsControllerProvider.notifier).selectSession(sessionId);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final chatMessagesControllerProvider =
    StateNotifierProvider<ChatMessagesController, ChatMessagesState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatMessagesController(repo, ref);
});
