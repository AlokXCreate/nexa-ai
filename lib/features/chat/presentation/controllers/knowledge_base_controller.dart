import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/entities/knowledge_note.dart';
import 'package:localmind_ai/features/chat/domain/entities/knowledge_collection.dart';
import 'package:localmind_ai/features/chat/domain/entities/rag_chunk.dart';
import 'package:localmind_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/rag_documents_controller.dart'; // exposes chatRepositoryProvider
import 'package:localmind_ai/features/chat/data/services/rag_service.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';

class KnowledgeBaseState {
  final List<KnowledgeNote> notes;
  final List<KnowledgeCollection> collections;
  final List<KnowledgeNote> filteredNotes;
  final String? selectedNoteId;
  final String? selectedCollectionId;
  final String searchQuery;
  final bool isSemanticSearch;
  final String? selectedTag;
  final String? selectedCategory;
  final bool showPinnedOnly;
  final bool showFavoritesOnly;
  final bool isGeneratingAi;
  final String aiOutput;
  final bool isLoading;
  final String? error;

  const KnowledgeBaseState({
    this.notes = const [],
    this.collections = const [],
    this.filteredNotes = const [],
    this.selectedNoteId,
    this.selectedCollectionId,
    this.searchQuery = '',
    this.isSemanticSearch = false,
    this.selectedTag,
    this.selectedCategory,
    this.showPinnedOnly = false,
    this.showFavoritesOnly = false,
    this.isGeneratingAi = false,
    this.aiOutput = '',
    this.isLoading = false,
    this.error,
  });

  KnowledgeBaseState copyWith({
    List<KnowledgeNote>? notes,
    List<KnowledgeCollection>? collections,
    List<KnowledgeNote>? filteredNotes,
    String? selectedNoteId,
    String? selectedCollectionId,
    String? searchQuery,
    bool? isSemanticSearch,
    String? selectedTag,
    String? selectedCategory,
    bool? showPinnedOnly,
    bool? showFavoritesOnly,
    bool? isGeneratingAi,
    String? aiOutput,
    bool? isLoading,
    String? error,
    bool clearSelectedNote = false,
    bool clearSelectedCollection = false,
    bool clearSelectedTag = false,
    bool clearSelectedCategory = false,
    bool clearError = false,
  }) {
    return KnowledgeBaseState(
      notes: notes ?? this.notes,
      collections: collections ?? this.collections,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      selectedNoteId: clearSelectedNote ? null : (selectedNoteId ?? this.selectedNoteId),
      selectedCollectionId: clearSelectedCollection ? null : (selectedCollectionId ?? this.selectedCollectionId),
      searchQuery: searchQuery ?? this.searchQuery,
      isSemanticSearch: isSemanticSearch ?? this.isSemanticSearch,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      showPinnedOnly: showPinnedOnly ?? this.showPinnedOnly,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      isGeneratingAi: isGeneratingAi ?? this.isGeneratingAi,
      aiOutput: aiOutput ?? this.aiOutput,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class KnowledgeBaseController extends StateNotifier<KnowledgeBaseState> {
  final ChatRepository _repository;
  final RagService _ragService = RagService();
  final Ref _ref;
  StreamSubscription<String>? _aiSubscription;

  KnowledgeBaseController(this._repository, this._ref) : super(const KnowledgeBaseState()) {
    loadAll();
  }

  @override
  void dispose() {
    _aiSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notes = await _repository.getNotes();
      final collections = await _repository.getCollections();

      // Seed default notes if everything is empty
      if (notes.isEmpty && collections.isEmpty) {
        await _seedDefaultNotes();
        return;
      }

      state = state.copyWith(
        notes: notes,
        collections: collections,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load Knowledge Base: $e',
      );
    }
  }

  Future<void> _seedDefaultNotes() async {
    try {
      final col1 = KnowledgeCollection(
        id: 'col_welcome',
        name: 'Welcome Guide',
        createdAt: DateTime.now(),
      );
      await _repository.saveCollection(col1);

      final note1 = KnowledgeNote(
        id: 'note_intro',
        title: 'Getting Started with LocalMind',
        content: '# Getting Started with LocalMind AI\n\n'
            'Welcome to your personal, offline AI-powered Knowledge Base! Here is what you can do:\n\n'
            '- **Markdown Editing**: Type naturally in markdown. We render headers, lists, links, and code blocks.\n'
            '- **Collections & Folders**: Organize your notes into folder collections using the sidebar.\n'
            '- **Tags & Categories**: Add custom category tags to notes for quick sorting and filtering.\n'
            '- **Offline AI Summarization**: Use the active local model to summarize long notes with one click.\n'
            '- **Local Note Q&A**: Chat directly with your note to extract facts offline.\n\n'
            'Enjoy full privacy, with 0% cloud data leaks!',
        collectionId: col1.id,
        category: 'Guide',
        tags: ['welcome', 'localmind', 'tutorial'],
        isPinned: true,
        isFavorite: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.saveNote(note1);

      final note2 = KnowledgeNote(
        id: 'note_rag_primer',
        title: 'What is RAG?',
        content: '# Retrieval-Augmented Generation (RAG)\n\n'
            'Retrieval-Augmented Generation is a technique that bridges semantic search and LLM completion.\n\n'
            '## How it Works Locally:\n'
            '1. **Chunking**: Large text documents are broken down into smaller paragraphs.\n'
            '2. **Indexing**: Term occurrences are indexed using TF-IDF weights.\n'
            '3. **Cosine Similarity**: User questions are matched against chunk vectors.\n'
            '4. **Context Injection**: Relevant text is added directly into the prompt context.\n'
            '5. **Model Answer**: The LLM answers using the provided context, reducing hallucinations.',
        collectionId: col1.id,
        category: 'Learning',
        tags: ['rag', 'ai', 'offline'],
        isPinned: false,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.saveNote(note2);

      final notes = await _repository.getNotes();
      final collections = await _repository.getCollections();

      state = state.copyWith(
        notes: notes,
        collections: collections,
        selectedNoteId: note1.id,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to seed default notes: $e',
      );
    }
  }

  // --- CRUD Note ---
  Future<void> createNote({
    required String title,
    required String content,
    String? collectionId,
    String? category,
    List<String> tags = const [],
  }) async {
    try {
      final note = KnowledgeNote(
        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        collectionId: collectionId,
        category: category,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.saveNote(note);
      await loadAll();
      state = state.copyWith(selectedNoteId: note.id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create note: $e');
    }
  }

  Future<void> updateNote(KnowledgeNote note) async {
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _repository.saveNote(updatedNote);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update note: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
      final nextNotes = state.notes.where((n) => n.id != noteId).toList();
      final nextSelected = state.selectedNoteId == noteId
          ? (nextNotes.isNotEmpty ? nextNotes.first.id : null)
          : state.selectedNoteId;

      state = state.copyWith(
        selectedNoteId: nextSelected,
        clearSelectedNote: nextSelected == null,
      );
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete note: $e');
    }
  }

  Future<void> togglePin(String noteId) async {
    final idx = state.notes.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final note = state.notes[idx];
    await updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  Future<void> toggleFavorite(String noteId) async {
    final idx = state.notes.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final note = state.notes[idx];
    await updateNote(note.copyWith(isFavorite: !note.isFavorite));
  }

  // --- CRUD Collection ---
  Future<void> createCollection(String name) async {
    try {
      final col = KnowledgeCollection(
        id: 'col_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        createdAt: DateTime.now(),
      );
      await _repository.saveCollection(col);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create folder: $e');
    }
  }

  Future<void> renameCollection(String id, String newName) async {
    try {
      final idx = state.collections.indexWhere((c) => c.id == id);
      if (idx == -1) return;
      final updated = state.collections[idx].copyWith(name: newName);
      await _repository.saveCollection(updated);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to rename collection: $e');
    }
  }

  Future<void> deleteCollection(String id) async {
    try {
      await _repository.deleteCollection(id);
      if (state.selectedCollectionId == id) {
        state = state.copyWith(clearSelectedCollection: true);
      }
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete folder: $e');
    }
  }

  // --- Selections & Filters ---
  void selectNote(String? id) {
    state = state.copyWith(
      selectedNoteId: id,
      clearSelectedNote: id == null,
      aiOutput: '', // clear AI workspace output when changing notes
    );
  }

  void selectCollection(String? id) {
    if (state.selectedCollectionId == id) {
      // Toggle off
      state = state.copyWith(clearSelectedCollection: true);
    } else {
      state = state.copyWith(
        selectedCollectionId: id,
        clearSelectedCollection: id == null,
      );
    }
    _applyFilters();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void toggleSemanticSearch(bool val) {
    state = state.copyWith(isSemanticSearch: val);
    _applyFilters();
  }

  void setSelectedTag(String? tag) {
    if (state.selectedTag == tag) {
      state = state.copyWith(clearSelectedTag: true);
    } else {
      state = state.copyWith(selectedTag: tag);
    }
    _applyFilters();
  }

  void setSelectedCategory(String? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
    _applyFilters();
  }

  void togglePinnedOnly() {
    state = state.copyWith(showPinnedOnly: !state.showPinnedOnly);
    _applyFilters();
  }

  void toggleFavoritesOnly() {
    state = state.copyWith(showFavoritesOnly: !state.showFavoritesOnly);
    _applyFilters();
  }

  // Helper getters computed dynamically
  List<String> get allTags {
    final Set<String> tags = {};
    for (final note in state.notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  List<String> get allCategories {
    final Set<String> categories = {};
    for (final note in state.notes) {
      if (note.category != null && note.category!.trim().isNotEmpty) {
        categories.add(note.category!.trim());
      }
    }
    return categories.toList()..sort();
  }

  // Apply filters and searches locally
  void _applyFilters() {
    var list = List<KnowledgeNote>.from(state.notes);

    // 1. Folder filter
    if (state.selectedCollectionId != null) {
      list = list.where((n) => n.collectionId == state.selectedCollectionId).toList();
    }

    // 2. Favorite filter
    if (state.showFavoritesOnly) {
      list = list.where((n) => n.isFavorite).toList();
    }

    // 3. Pin filter
    if (state.showPinnedOnly) {
      list = list.where((n) => n.isPinned).toList();
    }

    // 4. Category filter
    if (state.selectedCategory != null) {
      list = list.where((n) => n.category == state.selectedCategory).toList();
    }

    // 5. Tag filter
    if (state.selectedTag != null) {
      list = list.where((n) => n.tags.contains(state.selectedTag!)).toList();
    }

    // 6. Search query
    final query = state.searchQuery.trim();
    if (query.isNotEmpty) {
      if (state.isSemanticSearch) {
        // Run Hybrid Cosine similarity scoring on the fly
        final List<RagChunk> virtualChunks = [];
        final Map<String, String> docNames = {};

        for (final note in list) {
          docNames[note.id] = note.title;
          final chunks = _ragService.chunkText(note.content, size: 100, overlap: 20);
          for (var i = 0; i < chunks.length; i++) {
            virtualChunks.add(
              RagChunk(
                id: '${note.id}_c_$i',
                documentId: note.id,
                text: chunks[i],
                index: i,
                termVectors: _ragService.generateTermVectors(chunks[i]),
              ),
            );
          }
        }

        final matches = _ragService.retrieveRelevantChunks(
          query: query,
          allChunks: virtualChunks,
          docNames: docNames,
          topK: 10,
        );

        // Map note scores based on highest matching chunk
        final Map<String, double> noteScores = {};
        for (final match in matches) {
          final noteId = match.chunk.documentId;
          noteScores[noteId] = (noteScores[noteId] ?? 0.0) > match.score 
              ? noteScores[noteId]! 
              : match.score;
        }

        // Keep notes that matched and sort by semantic score
        list = list.where((n) => noteScores.containsKey(n.id)).toList();
        list.sort((a, b) {
          final scoreA = noteScores[a.id] ?? 0.0;
          final scoreB = noteScores[b.id] ?? 0.0;
          return scoreB.compareTo(scoreA); // Highest semantic score first
        });
      } else {
        // Simple case-insensitive keyword search on title + content
        final qLower = query.toLowerCase();
        list = list.where((n) =>
            n.title.toLowerCase().contains(qLower) ||
            n.content.toLowerCase().contains(qLower) ||
            n.tags.any((t) => t.toLowerCase().contains(qLower)) ||
            (n.category?.toLowerCase().contains(qLower) ?? false)).toList();
        
        // Sort: pins first, then updatedAt descending
        _sortNotes(list);
      }
    } else {
      // Sort: pins first, then updatedAt descending
      _sortNotes(list);
    }

    state = state.copyWith(filteredNotes: list);
  }

  void _sortNotes(List<KnowledgeNote> list) {
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  // --- Local LLM AI Actions ---
  Future<void> summarizeNote(String noteId) async {
    _aiSubscription?.cancel();
    state = state.copyWith(isGeneratingAi: true, aiOutput: '', clearError: true);

    final runtimeState = _ref.read(localRuntimeControllerProvider);
    if (!runtimeState.isModelLoaded) {
      state = state.copyWith(
        isGeneratingAi: false,
        error: 'No local model loaded. Please load a model in the chat or model screen first.',
      );
      return;
    }

    final noteIndex = state.notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      state = state.copyWith(isGeneratingAi: false, error: 'Note not found.');
      return;
    }
    final note = state.notes[noteIndex];

    final prompt = 'System: You are an expert assistant. Summarize the following note clearly using bullet points. Focus on key themes and action items.\n\n'
        'Note Title: ${note.title}\n'
        'Note Content:\n${note.content}\n\n'
        'Summary:';

    final inferenceService = _ref.read(localInferenceServiceProvider);
    
    try {
      final tokenStream = inferenceService.streamInference(prompt: prompt, maxTokens: 400);
      _aiSubscription = tokenStream.listen(
        (token) {
          state = state.copyWith(aiOutput: state.aiOutput + token);
        },
        onError: (err) {
          state = state.copyWith(isGeneratingAi: false, error: 'LLM Error: $err');
        },
        onDone: () {
          state = state.copyWith(isGeneratingAi: false);
        },
      );
    } catch (e) {
      state = state.copyWith(isGeneratingAi: false, error: 'Summarization failed: $e');
    }
  }

  Future<void> askNoteQuestion(String noteId, String question) async {
    if (question.trim().isEmpty) return;
    
    _aiSubscription?.cancel();
    state = state.copyWith(isGeneratingAi: true, aiOutput: '', clearError: true);

    final runtimeState = _ref.read(localRuntimeControllerProvider);
    if (!runtimeState.isModelLoaded) {
      state = state.copyWith(
        isGeneratingAi: false,
        error: 'No local model loaded. Please load a model in the chat or model screen first.',
      );
      return;
    }

    final noteIndex = state.notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      state = state.copyWith(isGeneratingAi: false, error: 'Note not found.');
      return;
    }
    final note = state.notes[noteIndex];

    final prompt = 'System: You are a helpful assistant. Use the following note contents to answer the question. Be factual, concise, and direct.\n\n'
        'Note Title: ${note.title}\n'
        'Note Content:\n${note.content}\n\n'
        'Question: $question\n'
        'Answer:';

    final inferenceService = _ref.read(localInferenceServiceProvider);

    try {
      final tokenStream = inferenceService.streamInference(prompt: prompt, maxTokens: 300);
      _aiSubscription = tokenStream.listen(
        (token) {
          state = state.copyWith(aiOutput: state.aiOutput + token);
        },
        onError: (err) {
          state = state.copyWith(isGeneratingAi: false, error: 'LLM Error: $err');
        },
        onDone: () {
          state = state.copyWith(isGeneratingAi: false);
        },
      );
    } catch (e) {
      state = state.copyWith(isGeneratingAi: false, error: 'Question answering failed: $e');
    }
  }

  void stopAiGeneration() {
    _ref.read(localRuntimeControllerProvider.notifier).stopGeneration();
    state = state.copyWith(isGeneratingAi: false);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider setup
final knowledgeBaseControllerProvider =
    StateNotifierProvider<KnowledgeBaseController, KnowledgeBaseState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return KnowledgeBaseController(repo, ref);
});
