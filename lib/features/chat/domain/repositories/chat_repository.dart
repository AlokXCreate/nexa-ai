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

abstract class ChatRepository {
  // Chat Session management
  Future<void> saveSession(ChatSession session);
  Future<void> deleteSession(String sessionId);
  Future<List<ChatSession>> getSessions();
  
  // Message management
  Future<void> saveMessage(String sessionId, ChatMessage message);
  Future<void> deleteMessage(String sessionId, String messageId);
  Future<List<ChatMessage>> getMessages(String sessionId);

  // RAG Folder management
  Future<void> saveFolder(RagFolder folder);
  Future<void> deleteFolder(String folderId);
  Future<List<RagFolder>> getFolders();

  // RAG Document management
  Future<void> saveDocument(RagDocument doc, List<RagChunk> chunks);
  Future<void> deleteDocument(String docId);
  Future<List<RagDocument>> getDocuments();
  
  // RAG Chunk management
  Future<List<RagChunk>> getChunks(String docId);
  Future<List<RagChunk>> getActiveChunks();

  // Knowledge Base Note operations
  Future<void> saveNote(KnowledgeNote note);
  Future<void> deleteNote(String noteId);
  Future<List<KnowledgeNote>> getNotes();

  // Knowledge Base Collection operations
  Future<void> saveCollection(KnowledgeCollection col);
  Future<void> deleteCollection(String colId);
  Future<List<KnowledgeCollection>> getCollections();

  // Multi-model Compare Session management
  Future<void> saveCompareSession(CompareSession session);
  Future<void> deleteCompareSession(String sessionId);
  Future<List<CompareSession>> getCompareSessions();

  // Multi-model Compare Message management
  Future<void> saveCompareMessage(String sessionId, CompareMessage message);
  Future<void> deleteCompareMessage(String sessionId, String messageId);
  Future<List<CompareMessage>> getCompareMessages(String sessionId);

  // Chat Folder management
  Future<void> saveChatFolder(ChatFolder folder);
  Future<void> deleteChatFolder(String folderId);
  Future<List<ChatFolder>> getChatFolders();

  // Prompt Template management
  Future<void> savePromptTemplate(PromptTemplate template);
  Future<void> deletePromptTemplate(String templateId);
  Future<List<PromptTemplate>> getPromptTemplates();
}
