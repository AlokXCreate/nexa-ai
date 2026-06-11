import 'package:hive_flutter/hive_flutter.dart';
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

class ChatRepositoryImpl implements ChatRepository {
  static const String sessionBoxName = 'chatSessionsBox';
  static const String foldersBoxName = 'ragFoldersBox';
  static const String documentsBoxName = 'ragDocumentsBox';
  static const String notesBoxName = 'knowledgeNotesBox';
  static const String collectionsBoxName = 'knowledgeCollectionsBox';
  static const String compareSessionBoxName = 'multiModelSessionsBox';
  static const String chatFoldersBoxName = 'chatFoldersBox';
  static const String promptTemplatesBoxName = 'promptTemplatesBox';

  String _getMessageBoxName(String sessionId) => 'messagesBox_$sessionId';
  String _getChunksBoxName(String docId) => 'ragChunksBox_$docId';
  String _getCompareMessageBoxName(String sessionId) => 'multiModelMessagesBox_$sessionId';

  Future<Box> _getNotesBox() async {
    if (!Hive.isBoxOpen(notesBoxName)) {
      return await Hive.openBox(notesBoxName);
    }
    return Hive.box(notesBoxName);
  }

  Future<Box> _getCollectionsBox() async {
    if (!Hive.isBoxOpen(collectionsBoxName)) {
      return await Hive.openBox(collectionsBoxName);
    }
    return Hive.box(collectionsBoxName);
  }

  Future<Box> _getSessionBox() async {
    if (!Hive.isBoxOpen(sessionBoxName)) {
      return await Hive.openBox(sessionBoxName);
    }
    return Hive.box(sessionBoxName);
  }

  Future<Box> _getFoldersBox() async {
    if (!Hive.isBoxOpen(foldersBoxName)) {
      return await Hive.openBox(foldersBoxName);
    }
    return Hive.box(foldersBoxName);
  }

  Future<Box> _getDocumentsBox() async {
    if (!Hive.isBoxOpen(documentsBoxName)) {
      return await Hive.openBox(documentsBoxName);
    }
    return Hive.box(documentsBoxName);
  }

  Future<Box> _getMessageBox(String sessionId) async {
    final boxName = _getMessageBoxName(sessionId);
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<Box> _getChunksBox(String docId) async {
    final boxName = _getChunksBoxName(docId);
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<Box> _getChatFoldersBox() async {
    if (!Hive.isBoxOpen(chatFoldersBoxName)) {
      return await Hive.openBox(chatFoldersBoxName);
    }
    return Hive.box(chatFoldersBoxName);
  }

  Future<Box> _getPromptTemplatesBox() async {
    if (!Hive.isBoxOpen(promptTemplatesBoxName)) {
      return await Hive.openBox(promptTemplatesBoxName);
    }
    return Hive.box(promptTemplatesBoxName);
  }

  Future<Box> _getCompareSessionBox() async {
    if (!Hive.isBoxOpen(compareSessionBoxName)) {
      return await Hive.openBox(compareSessionBoxName);
    }
    return Hive.box(compareSessionBoxName);
  }

  Future<Box> _getCompareMessageBox(String sessionId) async {
    final boxName = _getCompareMessageBoxName(sessionId);
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  @override
  Future<void> saveSession(ChatSession session) async {
    final box = await _getSessionBox();
    await box.put(session.id, session.toMap());
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final box = await _getSessionBox();
    await box.delete(sessionId);
    
    final msgBox = await _getMessageBox(sessionId);
    await msgBox.clear();
    await msgBox.close();
  }

  @override
  Future<List<ChatSession>> getSessions() async {
    final box = await _getSessionBox();
    return box.values.map((map) => ChatSession.fromMap(map as Map)).toList();
  }

  @override
  Future<void> saveMessage(String sessionId, ChatMessage message) async {
    final box = await _getMessageBox(sessionId);
    await box.put(message.id, message.toMap());
  }

  @override
  Future<void> deleteMessage(String sessionId, String messageId) async {
    final box = await _getMessageBox(sessionId);
    await box.delete(messageId);
  }

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final box = await _getMessageBox(sessionId);
    final list = box.values.map((map) => ChatMessage.fromMap(map as Map)).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  // RAG Folder Operations
  @override
  Future<void> saveFolder(RagFolder folder) async {
    final box = await _getFoldersBox();
    await box.put(folder.id, folder.toMap());
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    final box = await _getFoldersBox();
    await box.delete(folderId);
    
    final docBox = await _getDocumentsBox();
    for (final docMap in docBox.values) {
      final doc = RagDocument.fromMap(docMap as Map);
      if (doc.folderId == folderId) {
        final updated = doc.copyWith(clearFolder: true);
        await docBox.put(updated.id, updated.toMap());
      }
    }
  }

  @override
  Future<List<RagFolder>> getFolders() async {
    final box = await _getFoldersBox();
    return box.values.map((map) => RagFolder.fromMap(map as Map)).toList();
  }

  // RAG Document & Chunk Operations
  @override
  Future<void> saveDocument(RagDocument doc, List<RagChunk> chunks) async {
    final box = await _getDocumentsBox();
    await box.put(doc.id, doc.toMap());

    final chunkBox = await _getChunksBox(doc.id);
    await chunkBox.clear();
    for (final chunk in chunks) {
      await chunkBox.put(chunk.id, chunk.toMap());
    }
  }

  @override
  Future<void> deleteDocument(String docId) async {
    final box = await _getDocumentsBox();
    await box.delete(docId);

    final chunkBox = await _getChunksBox(docId);
    await chunkBox.clear();
    await chunkBox.close();
  }

  @override
  Future<List<RagDocument>> getDocuments() async {
    final box = await _getDocumentsBox();
    return box.values.map((map) => RagDocument.fromMap(map as Map)).toList();
  }

  @override
  Future<List<RagChunk>> getChunks(String docId) async {
    final chunkBox = await _getChunksBox(docId);
    return chunkBox.values.map((map) => RagChunk.fromMap(map as Map)).toList();
  }

  @override
  Future<List<RagChunk>> getActiveChunks() async {
    final docBox = await _getDocumentsBox();
    final List<RagChunk> activeChunks = [];
    
    for (final docMap in docBox.values) {
      final doc = RagDocument.fromMap(docMap as Map);
      if (doc.isActive) {
        final chunks = await getChunks(doc.id);
        activeChunks.addAll(chunks);
      }
    }
    return activeChunks;
  }

  // Knowledge Base Note operations
  @override
  Future<void> saveNote(KnowledgeNote note) async {
    final box = await _getNotesBox();
    await box.put(note.id, note.toMap());
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final box = await _getNotesBox();
    await box.delete(noteId);
  }

  @override
  Future<List<KnowledgeNote>> getNotes() async {
    final box = await _getNotesBox();
    return box.values.map((map) => KnowledgeNote.fromMap(map as Map)).toList();
  }

  // Knowledge Base Collection operations
  @override
  Future<void> saveCollection(KnowledgeCollection col) async {
    final box = await _getCollectionsBox();
    await box.put(col.id, col.toMap());
  }

  @override
  Future<void> deleteCollection(String colId) async {
    final box = await _getCollectionsBox();
    await box.delete(colId);
    
    // Dissociate notes belonging to this collection
    final noteBox = await _getNotesBox();
    for (final noteMap in noteBox.values) {
      final note = KnowledgeNote.fromMap(noteMap as Map);
      if (note.collectionId == colId) {
        final updated = note.copyWith(clearCollectionId: true);
        await noteBox.put(updated.id, updated.toMap());
      }
    }
  }

  @override
  Future<List<KnowledgeCollection>> getCollections() async {
    final box = await _getCollectionsBox();
    return box.values.map((map) => KnowledgeCollection.fromMap(map as Map)).toList();
  }

  // Multi-model Compare Session management
  @override
  Future<void> saveCompareSession(CompareSession session) async {
    final box = await _getCompareSessionBox();
    await box.put(session.id, session.toMap());
  }

  @override
  Future<void> deleteCompareSession(String sessionId) async {
    final box = await _getCompareSessionBox();
    await box.delete(sessionId);

    final msgBox = await _getCompareMessageBox(sessionId);
    await msgBox.clear();
    await msgBox.close();
  }

  @override
  Future<List<CompareSession>> getCompareSessions() async {
    final box = await _getCompareSessionBox();
    return box.values.map((map) => CompareSession.fromMap(map as Map)).toList();
  }

  // Multi-model Compare Message management
  @override
  Future<void> saveCompareMessage(String sessionId, CompareMessage message) async {
    final box = await _getCompareMessageBox(sessionId);
    await box.put(message.id, message.toMap());
  }

  @override
  Future<void> deleteCompareMessage(String sessionId, String messageId) async {
    final box = await _getCompareMessageBox(sessionId);
    await box.delete(messageId);
  }

  @override
  Future<List<CompareMessage>> getCompareMessages(String sessionId) async {
    final box = await _getCompareMessageBox(sessionId);
    final list = box.values.map((map) => CompareMessage.fromMap(map as Map)).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  // Chat Folder management
  @override
  Future<void> saveChatFolder(ChatFolder folder) async {
    final box = await _getChatFoldersBox();
    await box.put(folder.id, folder.toMap());
  }

  @override
  Future<void> deleteChatFolder(String folderId) async {
    final box = await _getChatFoldersBox();
    await box.delete(folderId);

    // Dissociate sessions inside this folder
    final sessionBox = await _getSessionBox();
    for (final sessionMap in sessionBox.values) {
      final session = ChatSession.fromMap(sessionMap as Map);
      if (session.folderId == folderId) {
        final updated = session.copyWith(clearFolder: true);
        await sessionBox.put(updated.id, updated.toMap());
      }
    }
  }

  @override
  Future<List<ChatFolder>> getChatFolders() async {
    final box = await _getChatFoldersBox();
    return box.values.map((map) => ChatFolder.fromMap(map as Map)).toList();
  }

  // Prompt Template management
  @override
  Future<void> savePromptTemplate(PromptTemplate template) async {
    final box = await _getPromptTemplatesBox();
    await box.put(template.id, template.toMap());
  }

  @override
  Future<void> deletePromptTemplate(String templateId) async {
    final box = await _getPromptTemplatesBox();
    await box.delete(templateId);
  }

  @override
  Future<List<PromptTemplate>> getPromptTemplates() async {
    final box = await _getPromptTemplatesBox();
    return box.values.map((map) => PromptTemplate.fromMap(map as Map)).toList();
  }
}
