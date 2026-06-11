import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/entities/rag_chunk.dart';
import 'package:localmind_ai/features/chat/domain/entities/rag_document.dart';
import 'package:localmind_ai/features/chat/domain/entities/rag_folder.dart';
import 'package:localmind_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:localmind_ai/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:localmind_ai/features/chat/data/repositories/chat_repository_sync_decorator.dart';
import 'package:localmind_ai/features/chat/data/services/document_parser.dart';
import 'package:localmind_ai/features/chat/data/services/rag_service.dart';

class RagDocumentsState {
  final List<RagFolder> folders;
  final List<RagDocument> documents;
  final bool isImporting;
  final double importProgress;
  final String? error;

  const RagDocumentsState({
    this.folders = const [],
    this.documents = const [],
    this.isImporting = false,
    this.importProgress = 0.0,
    this.error,
  });

  RagDocumentsState copyWith({
    List<RagFolder>? folders,
    List<RagDocument>? documents,
    bool? isImporting,
    double? importProgress,
    String? error,
    bool clearError = false,
  }) {
    return RagDocumentsState(
      folders: folders ?? this.folders,
      documents: documents ?? this.documents,
      isImporting: isImporting ?? this.isImporting,
      importProgress: importProgress ?? this.importProgress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RagDocumentsController extends StateNotifier<RagDocumentsState> {
  final ChatRepository _repository;
  final DocumentParser _parser = DocumentParser();
  final RagService _ragService = RagService();

  RagDocumentsController(this._repository) : super(const RagDocumentsState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      final folders = await _repository.getFolders();
      final docs = await _repository.getDocuments();

      // Seed default help files if first launch
      if (docs.isEmpty && folders.isEmpty) {
        await _seedDefaultDocuments();
        return;
      }

      state = state.copyWith(folders: folders, documents: docs);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load Knowledge Base: $e');
    }
  }

  Future<void> _seedDefaultDocuments() async {
    state = state.copyWith(isImporting: true, importProgress: 0.1);
    try {
      // Create a default folder
      final defaultFolder = RagFolder(
        id: 'default_ref_folder',
        name: 'Reference Guides',
        createdAt: DateTime.now(),
      );
      await _repository.saveFolder(defaultFolder);

      // Seed Guide 1 (Llama Info)
      final doc1Id = 'ref_llama3_guide';
      const doc1Text = 'Llama 3.2 (3B) is a local Large Language Model developed by Meta. '
          'It is optimized for on-device deployment and supports a context length of 128,000 tokens. '
          'The model operates using a GGUF container which loads weights directly into CPU memory '
          'or offloads layers into GPU VRAM (using FFI-based F16 or Q4 quantization).';
      
      final doc1Chunks = _ragService.chunkText(doc1Text);
      final List<RagChunk> chunkEntities1 = [];
      for (var i = 0; i < doc1Chunks.length; i++) {
        chunkEntities1.add(
          RagChunk(
            id: '${doc1Id}_$i',
            documentId: doc1Id,
            text: doc1Chunks[i],
            index: i,
            termVectors: _ragService.generateTermVectors(doc1Chunks[i]),
          ),
        );
      }
      
      final doc1 = RagDocument(
        id: doc1Id,
        name: 'Llama 3.2 Reference Guide.pdf',
        filePath: '/localmind/kb/Llama3_Guide.pdf',
        fileType: 'pdf',
        folderId: defaultFolder.id,
        sizeBytes: doc1Text.length,
        chunkCount: chunkEntities1.length,
        uploadedAt: DateTime.now(),
        isActive: true,
      );
      await _repository.saveDocument(doc1, chunkEntities1);

      // Seed Guide 2 (RAG Info)
      final doc2Id = 'ref_rag_primer';
      const doc2Text = 'Retrieval-Augmented Generation (RAG) is a technique that merges LLM text generation '
          'with real-time semantic document search. By retrieving paragraphs relevant to a user\'s query, '
          'RAG injects factual context into the system prompt, resolving LLM hallucination issues. '
          'LocalMind\'s RAG system runs completely offline. It chunks documents into 150-word blocks, '
          'indexes them using TF-IDF term weights and 3-character n-gram overlap vectors, and calculates Cosine Similarity.';
      
      final doc2Chunks = _ragService.chunkText(doc2Text);
      final List<RagChunk> chunkEntities2 = [];
      for (var i = 0; i < doc2Chunks.length; i++) {
        chunkEntities2.add(
          RagChunk(
            id: '${doc2Id}_$i',
            documentId: doc2Id,
            text: doc2Chunks[i],
            index: i,
            termVectors: _ragService.generateTermVectors(doc2Chunks[i]),
          ),
        );
      }

      final doc2 = RagDocument(
        id: doc2Id,
        name: 'Offline RAG Integration.md',
        filePath: '/localmind/kb/RAG_Integration.md',
        fileType: 'md',
        folderId: defaultFolder.id,
        sizeBytes: doc2Text.length,
        chunkCount: chunkEntities2.length,
        uploadedAt: DateTime.now(),
        isActive: true,
      );
      await _repository.saveDocument(doc2, chunkEntities2);

      // Reload
      final folders = await _repository.getFolders();
      final docs = await _repository.getDocuments();
      state = state.copyWith(
        folders: folders,
        documents: docs,
        isImporting: false,
        importProgress: 0.0,
      );
    } catch (e) {
      state = state.copyWith(isImporting: false, error: 'Failed to seed reference docs: $e');
    }
  }

  Future<void> createFolder(String name) async {
    try {
      final folder = RagFolder(
        id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        createdAt: DateTime.now(),
      );
      await _repository.saveFolder(folder);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create folder: $e');
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      await _repository.deleteFolder(id);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete folder: $e');
    }
  }

  Future<void> importDocument({
    required String filePath,
    required String fileType,
    String? folderId,
  }) async {
    state = state.copyWith(isImporting: true, importProgress: 0.1, clearError: true);
    try {
      // 1. Text Extraction
      state = state.copyWith(importProgress: 0.3);
      final rawText = await _parser.parseFile(filePath, fileType);
      
      if (rawText.trim().isEmpty) {
        throw Exception('Extracted document content is empty.');
      }

      // 2. Text Segmentation
      state = state.copyWith(importProgress: 0.5);
      final chunks = _ragService.chunkText(rawText);

      // 3. Vector Generation
      state = state.copyWith(importProgress: 0.7);
      final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
      final List<RagChunk> chunkEntities = [];
      for (var i = 0; i < chunks.length; i++) {
        chunkEntities.add(
          RagChunk(
            id: '${docId}_$i',
            documentId: docId,
            text: chunks[i],
            index: i,
            termVectors: _ragService.generateTermVectors(chunks[i]),
          ),
        );
      }

      // 4. Persistence
      state = state.copyWith(importProgress: 0.9);
      final filename = filePath.split(Platform.pathSeparator).last;
      
      final doc = RagDocument(
        id: docId,
        name: filename,
        filePath: filePath,
        fileType: fileType,
        folderId: folderId,
        sizeBytes: rawText.length,
        chunkCount: chunkEntities.length,
        uploadedAt: DateTime.now(),
        isActive: true,
      );

      await _repository.saveDocument(doc, chunkEntities);
      
      state = state.copyWith(importProgress: 1.0);
      await loadAll();
      state = state.copyWith(isImporting: false, importProgress: 0.0);
    } catch (e) {
      state = state.copyWith(isImporting: false, importProgress: 0.0, error: 'Import failed: ${e.toString()}');
    }
  }

  Future<void> toggleDocumentActive(String docId, bool isActive) async {
    try {
      final docIndex = state.documents.indexWhere((d) => d.id == docId);
      if (docIndex == -1) return;

      final updatedDoc = state.documents[docIndex].copyWith(isActive: isActive);
      // Fetch chunks for document to save again
      final chunks = await _repository.getChunks(docId);
      await _repository.saveDocument(updatedDoc, chunks);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle document: $e');
    }
  }

  Future<void> renameDocument(String docId, String newName) async {
    try {
      final docIndex = state.documents.indexWhere((d) => d.id == docId);
      if (docIndex == -1) return;

      final updatedDoc = state.documents[docIndex].copyWith(name: newName);
      final chunks = await _repository.getChunks(docId);
      await _repository.saveDocument(updatedDoc, chunks);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to rename document: $e');
    }
  }

  Future<void> moveDocumentToFolder(String docId, String? folderId) async {
    try {
      final docIndex = state.documents.indexWhere((d) => d.id == docId);
      if (docIndex == -1) return;

      final updatedDoc = state.documents[docIndex].copyWith(
        folderId: folderId,
        clearFolder: folderId == null,
      );
      final chunks = await _repository.getChunks(docId);
      await _repository.saveDocument(updatedDoc, chunks);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to move document: $e');
    }
  }

  Future<void> deleteDocument(String docId) async {
    try {
      await _repository.deleteDocument(docId);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete document: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final impl = ChatRepositoryImpl();
  return ChatRepositorySyncDecorator(impl, ref);
});

final ragDocumentsControllerProvider =
    StateNotifierProvider<RagDocumentsController, RagDocumentsState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return RagDocumentsController(repo);
});
