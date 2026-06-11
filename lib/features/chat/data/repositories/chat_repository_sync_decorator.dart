import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/database/sync_operation.dart';
import 'package:localmind_ai/core/database/firestore_sync_service.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_session.dart';
import 'package:localmind_ai/features/chat/domain/entities/rag_folder.dart';
import 'package:localmind_ai/features/chat/domain/entities/rag_document.dart';
import 'package:localmind_ai/features/chat/domain/entities/rag_chunk.dart';
import 'package:localmind_ai/features/chat/domain/entities/knowledge_note.dart';
import 'package:localmind_ai/features/chat/domain/entities/knowledge_collection.dart';
import 'package:localmind_ai/features/chat/domain/entities/compare_session.dart';
import 'package:localmind_ai/features/chat/domain/entities/compare_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_folder.dart';
import 'package:localmind_ai/features/chat/domain/entities/prompt_template.dart';
import 'package:localmind_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';

class ChatRepositorySyncDecorator implements ChatRepository {
  final ChatRepository _delegate;
  final Ref _ref;

  ChatRepositorySyncDecorator(this._delegate, this._ref);

  FirestoreSyncService get _syncService => _ref.read(firestoreSyncServiceProvider);

  bool _isIncognito() {
    try {
      return _ref.read(securityControllerProvider).config.isIncognitoActive;
    } catch (_) {
      return false;
    }
  }

  bool _isSessionPrivate(String sessionId) {
    try {
      final config = _ref.read(securityControllerProvider).config;
      return config.isIncognitoActive || config.privateSessionIds.contains(sessionId);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveSession(ChatSession session) async {
    await _delegate.saveSession(session);
    if (!_isSessionPrivate(session.id)) {
      await _syncService.queueOperation(
        collectionName: 'sessions',
        documentId: session.id,
        actionType: SyncActionType.save,
        data: session.toMap(),
      );
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _delegate.deleteSession(sessionId);
    if (!_isSessionPrivate(sessionId)) {
      await _syncService.queueOperation(
        collectionName: 'sessions',
        documentId: sessionId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<ChatSession>> getSessions() => _delegate.getSessions();

  @override
  Future<void> saveMessage(String sessionId, ChatMessage message) async {
    await _delegate.saveMessage(sessionId, message);
    if (!_isSessionPrivate(sessionId)) {
      await _syncService.queueOperation(
        collectionName: 'sessions/$sessionId/messages',
        documentId: message.id,
        actionType: SyncActionType.save,
        data: message.toMap(),
      );
    }
  }

  @override
  Future<void> deleteMessage(String sessionId, String messageId) async {
    await _delegate.deleteMessage(sessionId, messageId);
    if (!_isSessionPrivate(sessionId)) {
      await _syncService.queueOperation(
        collectionName: 'sessions/$sessionId/messages',
        documentId: messageId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) => _delegate.getMessages(sessionId);

  @override
  Future<void> saveFolder(RagFolder folder) async {
    await _delegate.saveFolder(folder);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'folders',
        documentId: folder.id,
        actionType: SyncActionType.save,
        data: folder.toMap(),
      );
    }
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    await _delegate.deleteFolder(folderId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'folders',
        documentId: folderId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<RagFolder>> getFolders() => _delegate.getFolders();

  @override
  Future<void> saveDocument(RagDocument doc, List<RagChunk> chunks) async {
    await _delegate.saveDocument(doc, chunks);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'documents',
        documentId: doc.id,
        actionType: SyncActionType.save,
        data: doc.toMap(),
      );
      for (final chunk in chunks) {
        await _syncService.queueOperation(
          collectionName: 'documents/${doc.id}/chunks',
          documentId: chunk.id,
          actionType: SyncActionType.save,
          data: chunk.toMap(),
        );
      }
    }
  }

  @override
  Future<void> deleteDocument(String docId) async {
    await _delegate.deleteDocument(docId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'documents',
        documentId: docId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<RagDocument>> getDocuments() => _delegate.getDocuments();

  @override
  Future<List<RagChunk>> getChunks(String docId) => _delegate.getChunks(docId);

  @override
  Future<List<RagChunk>> getActiveChunks() => _delegate.getActiveChunks();

  @override
  Future<void> saveNote(KnowledgeNote note) async {
    await _delegate.saveNote(note);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'notes',
        documentId: note.id,
        actionType: SyncActionType.save,
        data: note.toMap(),
      );
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _delegate.deleteNote(noteId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'notes',
        documentId: noteId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<KnowledgeNote>> getNotes() => _delegate.getNotes();

  @override
  Future<void> saveCollection(KnowledgeCollection col) async {
    await _delegate.saveCollection(col);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'collections',
        documentId: col.id,
        actionType: SyncActionType.save,
        data: col.toMap(),
      );
    }
  }

  @override
  Future<void> deleteCollection(String colId) async {
    await _delegate.deleteCollection(colId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'collections',
        documentId: colId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<KnowledgeCollection>> getCollections() => _delegate.getCollections();

  @override
  Future<void> saveCompareSession(CompareSession session) async {
    await _delegate.saveCompareSession(session);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'compare_sessions',
        documentId: session.id,
        actionType: SyncActionType.save,
        data: session.toMap(),
      );
    }
  }

  @override
  Future<void> deleteCompareSession(String sessionId) async {
    await _delegate.deleteCompareSession(sessionId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'compare_sessions',
        documentId: sessionId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<CompareSession>> getCompareSessions() => _delegate.getCompareSessions();

  @override
  Future<void> saveCompareMessage(String sessionId, CompareMessage message) async {
    await _delegate.saveCompareMessage(sessionId, message);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'compare_sessions/$sessionId/messages',
        documentId: message.id,
        actionType: SyncActionType.save,
        data: message.toMap(),
      );
    }
  }

  @override
  Future<void> deleteCompareMessage(String sessionId, String messageId) async {
    await _delegate.deleteCompareMessage(sessionId, messageId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'compare_sessions/$sessionId/messages',
        documentId: messageId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<CompareMessage>> getCompareMessages(String sessionId) => _delegate.getCompareMessages(sessionId);

  @override
  Future<void> saveChatFolder(ChatFolder folder) async {
    await _delegate.saveChatFolder(folder);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'chat_folders',
        documentId: folder.id,
        actionType: SyncActionType.save,
        data: folder.toMap(),
      );
    }
  }

  @override
  Future<void> deleteChatFolder(String folderId) async {
    await _delegate.deleteChatFolder(folderId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'chat_folders',
        documentId: folderId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<ChatFolder>> getChatFolders() => _delegate.getChatFolders();

  @override
  Future<void> savePromptTemplate(PromptTemplate template) async {
    await _delegate.savePromptTemplate(template);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'prompt_templates',
        documentId: template.id,
        actionType: SyncActionType.save,
        data: template.toMap(),
      );
    }
  }

  @override
  Future<void> deletePromptTemplate(String templateId) async {
    await _delegate.deletePromptTemplate(templateId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'prompt_templates',
        documentId: templateId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<PromptTemplate>> getPromptTemplates() => _delegate.getPromptTemplates();
}
