import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_session.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_sessions_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_messages_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_profile.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_memory.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_session.dart';
import 'package:localmind_ai/features/agents/domain/repositories/agent_repository.dart';
import 'package:localmind_ai/features/agents/data/repositories/agent_repository_impl.dart';
import 'package:localmind_ai/features/agents/data/repositories/agent_repository_sync_decorator.dart';
import 'package:localmind_ai/features/agents/data/services/agent_tool_service.dart';

class AgentsState {
  final List<AgentProfile> profiles;
  final List<AgentMemory> activeMemory;
  final List<AgentSession> sessions;
  final AgentProfile? activeProfile;
  final AgentSession? activeSession;
  final String? runningToolId;
  final bool isLoading;
  final String? error;

  const AgentsState({
    this.profiles = const [],
    this.activeMemory = const [],
    this.sessions = const [],
    this.activeProfile,
    this.activeSession,
    this.runningToolId,
    this.isLoading = false,
    this.error,
  });

  AgentsState copyWith({
    List<AgentProfile>? profiles,
    List<AgentMemory>? activeMemory,
    List<AgentSession>? sessions,
    AgentProfile? activeProfile,
    AgentSession? activeSession,
    String? runningToolId,
    bool? isLoading,
    String? error,
    bool clearActiveSession = false,
    bool clearActiveProfile = false,
    bool clearRunningTool = false,
    bool clearError = false,
  }) {
    return AgentsState(
      profiles: profiles ?? this.profiles,
      activeMemory: activeMemory ?? this.activeMemory,
      sessions: sessions ?? this.sessions,
      activeProfile: clearActiveProfile ? null : (activeProfile ?? this.activeProfile),
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      runningToolId: clearRunningTool ? null : (runningToolId ?? this.runningToolId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AgentsController extends StateNotifier<AgentsState> {
  final AgentRepository _repository;
  final AgentToolService _toolService = AgentToolService();
  final Ref _ref;

  AgentsController(this._repository, this._ref) : super(const AgentsState()) {
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    state = state.copyWith(isLoading: true);
    try {
      final profilesList = await _repository.getProfiles();
      final sessionsList = await _repository.getAgentSessions();
      state = state.copyWith(
        profiles: profilesList,
        sessions: sessionsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load Agent profiles: $e');
    }
  }

  /// Sets the active agent and creates/retrieves their chat session.
  Future<void> startAgentSession(String agentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = state.profiles.firstWhere((p) => p.id == agentId);
      state = state.copyWith(activeProfile: profile);

      // Load memory facts
      await refreshMemory(agentId);

      // Check for existing AgentSession linking this profile
      final existing = state.sessions.firstWhere(
        (s) => s.agentId == agentId,
        orElse: () => AgentSession(id: '', agentId: '', chatSessionId: ''),
      );

      if (existing.id.isNotEmpty) {
        state = state.copyWith(activeSession: existing, isLoading: false);
        // Set standard Chat active session ID
        _ref.read(chatSessionsControllerProvider.notifier).selectSession(existing.chatSessionId);
      } else {
        // Create standard Chat Session
        final chatSessionsNotifier = _ref.read(chatSessionsControllerProvider.notifier);
        final newChatId = 'chat_agent_${agentId}_${DateTime.now().millisecondsSinceEpoch}';
        
        final newChatSession = ChatSession(
          id: newChatId,
          title: '${profile.name} Chat',
          modelId: profile.defaultModelId,
          isPinned: false,
          createdTime: DateTime.now(),
          lastActiveTime: DateTime.now(),
          systemPrompt: _buildSystemPromptWithMemory(profile.systemPrompt),
          tags: ['Agent', profile.name],
          temperature: profile.temperature,
        );

        // Add to main chat repository
        await chatSessionsNotifier.createCustomSession(newChatSession);

        // Create and save AgentSession link
        final agentSession = AgentSession(
          id: 'session_${agentId}_${DateTime.now().millisecondsSinceEpoch}',
          agentId: agentId,
          chatSessionId: newChatId,
          activeModelOverride: profile.defaultModelId,
        );

        await _repository.saveAgentSession(agentSession);
        
        final updatedSessions = [...state.sessions, agentSession];
        state = state.copyWith(
          sessions: updatedSessions,
          activeSession: agentSession,
          isLoading: false,
        );

        chatSessionsNotifier.selectSession(newChatId);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to start agent session: $e');
    }
  }

  /// Refreshes and loads active memory facts list for the agent.
  Future<void> refreshMemory(String agentId) async {
    final memory = await _repository.getMemoryForAgent(agentId);
    state = state.copyWith(activeMemory: memory);
  }

  /// Adds a fact to the agent's memory database.
  Future<void> addMemoryFact(String key, String value) async {
    final active = state.activeProfile;
    if (active == null) return;

    final newMemory = AgentMemory(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      agentId: active.id,
      key: key,
      value: value,
      createdAt: DateTime.now(),
    );

    await _repository.saveMemory(newMemory);
    await refreshMemory(active.id);
    await _updateSystemPromptWithCurrentMemory();
  }

  /// Deletes a fact from the agent's memory database.
  Future<void> deleteMemoryFact(String memoryId) async {
    final active = state.activeProfile;
    if (active == null) return;

    await _repository.deleteMemory(memoryId);
    await refreshMemory(active.id);
    await _updateSystemPromptWithCurrentMemory();
  }

  String _buildSystemPromptWithMemory(String basePrompt) {
    if (state.activeMemory.isEmpty) return basePrompt;

    final buffer = StringBuffer(basePrompt);
    buffer.writeln('\n\nUser Context / Long-term Memory Facts:');
    for (final m in state.activeMemory) {
      buffer.writeln('- ${m.key}: ${m.value}');
    }
    return buffer.toString();
  }

  Future<void> _updateSystemPromptWithCurrentMemory() async {
    final activeProf = state.activeProfile;
    final activeSess = state.activeSession;
    if (activeProf == null || activeSess == null) return;

    final newPrompt = _buildSystemPromptWithMemory(activeProf.systemPrompt);
    await _ref.read(chatSessionsControllerProvider.notifier).updateSessionParams(
      activeSess.chatSessionId,
      systemPrompt: newPrompt,
    );
  }

  /// Changes the active local GGUF model override for the agent.
  Future<void> switchAgentModel(String modelId) async {
    final activeSess = state.activeSession;
    if (activeSess == null) return;

    final updatedSession = activeSess.copyWith(activeModelOverride: modelId);
    await _repository.saveAgentSession(updatedSession);

    // Update standard chat session model
    await _ref.read(chatSessionsControllerProvider.notifier).updateSessionModel(
      activeSess.chatSessionId,
      modelId,
    );

    // If the model was loaded, trigger unload in runtime
    await _ref.read(localRuntimeControllerProvider.notifier).unloadActiveModel();

    final index = state.sessions.indexWhere((s) => s.id == activeSess.id);
    if (index != -1) {
      final updatedList = [...state.sessions];
      updatedList[index] = updatedSession;
      state = state.copyWith(
        sessions: updatedList,
        activeSession: updatedSession,
      );
    }
  }

  /// Sends a prompt to the active agent session, managing auto tool detection.
  Future<void> sendAgentMessage(String prompt) async {
    final activeProf = state.activeProfile;
    final activeSess = state.activeSession;
    if (activeProf == null || activeSess == null) return;

    // Detect if user query automatically triggers an agent tool
    final triggeredToolId = _toolService.detectAutoToolTrigger(activeProf.id, prompt);
    if (triggeredToolId != null) {
      // Trigger tool automatically
      final tool = AgentToolService.availableTools.firstWhere((t) => t.id == triggeredToolId);
      final inputs = <String, String>{};
      
      // Basic parameter extraction from prompt
      for (final param in tool.parameters) {
        inputs[param] = prompt;
      }
      
      await executeAgentTool(triggeredToolId, inputs, prompt);
    } else {
      // Standard message send
      await _ref.read(chatMessagesControllerProvider.notifier).sendMessage(prompt);
    }
  }

  /// Explicitly runs a tool and injects outputs.
  Future<void> executeAgentTool(String toolId, Map<String, String> inputs, String originalQuery) async {
    final activeSess = state.activeSession;
    if (activeSess == null) return;

    state = state.copyWith(runningToolId: toolId);
    try {
      final tool = AgentToolService.availableTools.firstWhere((t) => t.id == toolId);
      final output = await _toolService.executeTool(toolId, inputs);

      // 1. Save tool execution output as a structured User Message
      final messagesController = _ref.read(chatMessagesControllerProvider.notifier);
      
      final toolHeader = '🛠️ **Tool Executed: ${tool.name}**\n\n$output';
      
      // Inject tool output and original query into prompt context for LLM
      final contextPrompt = 'Here is the results of executing the "${tool.name}" tool:\n\n'
          '$output\n\n'
          'Using this data, answer the user\'s query: "$originalQuery"';

      // Submit prompt to local runtime
      await messagesController.sendMessage(contextPrompt);

      // Log tool output
      state = state.copyWith(clearRunningTool: true);
    } catch (e) {
      state = state.copyWith(clearRunningTool: true, error: 'Tool execution failed: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Riverpod Providers
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  final impl = AgentRepositoryImpl();
  return AgentRepositorySyncDecorator(impl, ref);
});

final agentsControllerProvider = StateNotifierProvider<AgentsController, AgentsState>((ref) {
  final repo = ref.watch(agentRepositoryProvider);
  return AgentsController(repo, ref);
});
