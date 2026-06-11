import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_session.dart';
import 'package:localmind_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/rag_documents_controller.dart'; // exposes chatRepositoryProvider

class ChatSessionsState {
  final List<ChatSession> sessions;
  final String? activeSessionId;
  final bool isLoading;
  final String? error;
  
  // Filters & Search
  final String searchQuery;
  final String? selectedTag;
  final Set<String>? messageSearchMatches;

  const ChatSessionsState({
    this.sessions = const [],
    this.activeSessionId,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedTag,
    this.messageSearchMatches,
  });

  ChatSessionsState copyWith({
    List<ChatSession>? sessions,
    String? activeSessionId,
    bool? isLoading,
    String? error,
    bool clearActiveSession = false,
    String? searchQuery,
    String? selectedTag,
    Set<String>? messageSearchMatches,
    bool clearSelectedTag = false,
    bool clearMessageSearchMatches = false,
  }) {
    return ChatSessionsState(
      sessions: sessions ?? this.sessions,
      activeSessionId: clearActiveSession ? null : (activeSessionId ?? this.activeSessionId),
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      messageSearchMatches: clearMessageSearchMatches ? null : (messageSearchMatches ?? this.messageSearchMatches),
    );
  }

  // Helper getter to list sessions filtered by search and tag
  List<ChatSession> get filteredSessions {
    var list = sessions;

    // Filter by Selected Tag
    if (selectedTag != null) {
      list = list.where((s) => s.tags.contains(selectedTag!)).toList();
    }

    // Filter by Search Query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((s) {
        final matchesTitle = s.title.toLowerCase().contains(q);
        final matchesTag = s.tags.any((t) => t.toLowerCase().contains(q));
        final matchesMessage = messageSearchMatches?.contains(s.id) ?? false;
        return matchesTitle || matchesTag || matchesMessage;
      }).toList();
    }

    return list;
  }
}

class ChatSessionsController extends StateNotifier<ChatSessionsState> {
  final ChatRepository _repository;

  ChatSessionsController(this._repository) : super(const ChatSessionsState()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true);
    try {
      final sessions = await _repository.getSessions();
      
      // Sort sessions: pinned first, then lastActiveTime descending
      sessions.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.lastActiveTime.compareTo(a.lastActiveTime);
      });

      state = state.copyWith(
        sessions: sessions,
        isLoading: false,
      );

      // Re-trigger text search on reload if query active
      if (state.searchQuery.isNotEmpty) {
        setSearchQuery(state.searchQuery);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load chat sessions: $e',
      );
    }
  }

  Future<String> createSession(String modelId, {String? title, String? folderId}) async {
    try {
      final id = 'session_${DateTime.now().millisecondsSinceEpoch}';
      final newSession = ChatSession(
        id: id,
        title: title ?? 'New Session',
        modelId: modelId,
        isPinned: false,
        createdTime: DateTime.now(),
        lastActiveTime: DateTime.now(),
        folderId: folderId,
        useRag: true, // Enable RAG by default
      );

      await _repository.saveSession(newSession);
      await loadSessions();
      
      state = state.copyWith(activeSessionId: id);
      return id;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create session: $e');
      rethrow;
    }
  }

  Future<void> createCustomSession(ChatSession session) async {
    try {
      await _repository.saveSession(session);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create custom session: $e');
    }
  }

  Future<void> updateSessionModel(String sessionId, String modelId) async {
    try {
      final idx = state.sessions.indexWhere((s) => s.id == sessionId);
      if (idx == -1) return;

      final session = state.sessions[idx];
      // Re-create the session since modelId is not in copyWith
      final updated = ChatSession(
        id: session.id,
        title: session.title,
        modelId: modelId,
        isPinned: session.isPinned,
        createdTime: session.createdTime,
        lastActiveTime: session.lastActiveTime,
        folderId: session.folderId,
        tags: session.tags,
        systemPrompt: session.systemPrompt,
        temperature: session.temperature,
        topP: session.topP,
        maxTokens: session.maxTokens,
        useRag: session.useRag,
      );

      await _repository.saveSession(updated);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update session model: $e');
    }
  }

  Future<void> selectSession(String? sessionId) async {
    state = state.copyWith(activeSessionId: sessionId);
    if (sessionId != null) {
      final idx = state.sessions.indexWhere((s) => s.id == sessionId);
      if (idx != -1) {
        final updated = state.sessions[idx].copyWith(lastActiveTime: DateTime.now());
        await _repository.saveSession(updated);
        await loadSessions();
      }
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _repository.deleteSession(sessionId);
      
      final nextActiveId = state.activeSessionId == sessionId
          ? (state.sessions.where((s) => s.id != sessionId).isNotEmpty
              ? state.sessions.firstWhere((s) => s.id != sessionId).id
              : null)
          : state.activeSessionId;

      await loadSessions();
      state = state.copyWith(
        activeSessionId: nextActiveId,
        clearActiveSession: nextActiveId == null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete session: $e');
    }
  }

  Future<void> pinSession(String sessionId, bool pin) async {
    try {
      final idx = state.sessions.indexWhere((s) => s.id == sessionId);
      if (idx == -1) return;

      final updated = state.sessions[idx].copyWith(isPinned: pin, lastActiveTime: DateTime.now());
      await _repository.saveSession(updated);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle pin: $e');
    }
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    try {
      final idx = state.sessions.indexWhere((s) => s.id == sessionId);
      if (idx == -1) return;

      final updated = state.sessions[idx].copyWith(title: newTitle);
      await _repository.saveSession(updated);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to rename session: $e');
    }
  }

  Future<void> moveSessionToFolder(String sessionId, String? folderId) async {
    try {
      final idx = state.sessions.indexWhere((s) => s.id == sessionId);
      if (idx == -1) return;

      final updated = state.sessions[idx].copyWith(
        folderId: folderId,
        clearFolder: folderId == null,
      );
      await _repository.saveSession(updated);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to move session: $e');
    }
  }

  Future<void> addTagToSession(String sessionId, String tag) async {
    final cleanTag = tag.trim().toLowerCase();
    if (cleanTag.isEmpty) return;

    try {
      final idx = state.sessions.indexWhere((s) => s.id == sessionId);
      if (idx == -1) return;

      final session = state.sessions[idx];
      if (session.tags.contains(cleanTag)) return;

      final updated = session.copyWith(tags: [...session.tags, cleanTag]);
      await _repository.saveSession(updated);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add tag: $e');
    }
  }

  Future<void> removeTagFromSession(String sessionId, String tag) async {
    try {
      final idx = state.sessions.indexWhere((s) => s.id == sessionId);
      if (idx == -1) return;

      final session = state.sessions[idx];
      final updatedTags = session.tags.where((t) => t != tag).toList();

      final updated = session.copyWith(tags: updatedTags);
      await _repository.saveSession(updated);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove tag: $e');
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _performFullTextSearch(query);
  }

  void setSelectedTag(String? tag) {
    if (tag == null) {
      state = state.copyWith(clearSelectedTag: true);
    } else {
      state = state.copyWith(selectedTag: tag);
    }
  }

  Future<void> _performFullTextSearch(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(clearMessageSearchMatches: true);
      return;
    }

    final matches = <String>{};
    final q = query.toLowerCase();
    
    for (final session in state.sessions) {
      try {
        final messages = await _repository.getMessages(session.id);
        if (messages.any((m) => m.content.toLowerCase().contains(q))) {
          matches.add(session.id);
        }
      } catch (_) {
        // Fail silently for search
      }
    }

    state = state.copyWith(messageSearchMatches: matches);
  }

  Future<void> updateSessionParams(
    String sessionId, {
    String? systemPrompt,
    double? temperature,
    double? topP,
    int? maxTokens,
    bool? useRag,
    bool clearSystemPrompt = false,
  }) async {
    try {
      final idx = state.sessions.indexWhere((s) => s.id == sessionId);
      if (idx == -1) return;

      final updated = state.sessions[idx].copyWith(
        systemPrompt: systemPrompt,
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
        useRag: useRag,
        clearSystemPrompt: clearSystemPrompt,
      );
      
      await _repository.saveSession(updated);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update parameters: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final chatSessionsControllerProvider =
    StateNotifierProvider<ChatSessionsController, ChatSessionsState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatSessionsController(repo);
});
