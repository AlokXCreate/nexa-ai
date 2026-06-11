import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/entities/prompt_template.dart';
import 'package:localmind_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/rag_documents_controller.dart'; // exposes chatRepositoryProvider

class PromptLibraryState {
  final List<PromptTemplate> templates;
  final bool isLoading;
  final String? error;

  const PromptLibraryState({
    this.templates = const [],
    this.isLoading = false,
    this.error,
  });

  PromptLibraryState copyWith({
    List<PromptTemplate>? templates,
    bool? isLoading,
    String? error,
  }) {
    return PromptLibraryState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PromptLibraryController extends StateNotifier<PromptLibraryState> {
  final ChatRepository _repository;

  PromptLibraryController(this._repository) : super(const PromptLibraryState()) {
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    state = state.copyWith(isLoading: true);
    try {
      var list = await _repository.getPromptTemplates();
      if (list.isEmpty) {
        await _prePopulateDefaultLibrary();
        list = await _repository.getPromptTemplates();
      }
      state = state.copyWith(templates: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load templates: $e');
    }
  }

  Future<void> _prePopulateDefaultLibrary() async {
    final defaults = [
      PromptTemplate(
        id: 'tpl_summarize',
        title: 'Summarize Text',
        content: 'Summarize the following text in [length] bullet points, focusing on [topic]:\n[text]',
        isFavorite: false,
        isPinned: true,
        category: 'library',
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      PromptTemplate(
        id: 'tpl_translate',
        title: 'Translate Language',
        content: 'Translate the following text into [target_language], preserving tone:\n[text]',
        isFavorite: false,
        isPinned: true,
        category: 'library',
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      PromptTemplate(
        id: 'tpl_refactor',
        title: 'Refactor Code',
        content: 'Refactor the following [language] code to improve readability and complexity:\n```[language]\n[code]\n```',
        isFavorite: false,
        isPinned: false,
        category: 'library',
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      PromptTemplate(
        id: 'tpl_email',
        title: 'Draft Email',
        content: 'Draft a professional email to [recipient] regarding [subject], requesting [action].',
        isFavorite: false,
        isPinned: false,
        category: 'library',
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];

    for (final t in defaults) {
      await _repository.savePromptTemplate(t);
    }
  }

  Future<void> addCustomTemplate(String title, String content) async {
    if (title.trim().isEmpty || content.trim().isEmpty) return;
    try {
      final t = PromptTemplate(
        id: 'tpl_cust_${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        content: content.trim(),
        isFavorite: false,
        isPinned: false,
        category: 'custom',
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _repository.savePromptTemplate(t);
      await loadTemplates();
    } catch (e) {
      state = state.copyWith(error: 'Failed to save template: $e');
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _repository.deletePromptTemplate(id);
      await loadTemplates();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete template: $e');
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final idx = state.templates.indexWhere((t) => t.id == id);
      if (idx == -1) return;
      final updated = state.templates[idx].copyWith(isFavorite: !state.templates[idx].isFavorite);
      await _repository.savePromptTemplate(updated);
      await loadTemplates();
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle favorite: $e');
    }
  }

  Future<void> togglePinned(String id) async {
    try {
      final idx = state.templates.indexWhere((t) => t.id == id);
      if (idx == -1) return;
      final updated = state.templates[idx].copyWith(isPinned: !state.templates[idx].isPinned);
      await _repository.savePromptTemplate(updated);
      await loadTemplates();
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle pin: $e');
    }
  }

  Future<void> recordPromptHistory(String content) async {
    final clean = content.trim();
    if (clean.isEmpty) return;
    
    // Don't record very long template completions or multi-line code directly as generic history
    if (clean.length > 200) return;

    try {
      final existingIdx = state.templates.indexWhere((t) => t.category == 'history' && t.content == clean);
      if (existingIdx != -1) {
        final updated = state.templates[existingIdx].copyWith(lastUsed: DateTime.now());
        await _repository.savePromptTemplate(updated);
      } else {
        // Limit history size to 20 items
        final historyItems = state.templates.where((t) => t.category == 'history').toList();
        if (historyItems.length >= 20) {
          historyItems.sort((a, b) => a.lastUsed.compareTo(b.lastUsed)); // oldest first
          await _repository.deletePromptTemplate(historyItems.first.id);
        }

        final truncatedTitle = clean.length > 30 ? '${clean.substring(0, 27)}...' : clean;
        final history = PromptTemplate(
          id: 'tpl_hist_${DateTime.now().millisecondsSinceEpoch}',
          title: truncatedTitle,
          content: clean,
          isFavorite: false,
          isPinned: false,
          category: 'history',
          lastUsed: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await _repository.savePromptTemplate(history);
      }
      await loadTemplates();
    } catch (e) {
      // Fail silently for history
    }
  }
}

final promptLibraryControllerProvider = StateNotifierProvider<PromptLibraryController, PromptLibraryState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return PromptLibraryController(repo);
});
