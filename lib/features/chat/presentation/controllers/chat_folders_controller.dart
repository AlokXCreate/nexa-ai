import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_folder.dart';
import 'package:localmind_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/rag_documents_controller.dart'; // exposes chatRepositoryProvider

class ChatFoldersState {
  final List<ChatFolder> folders;
  final bool isLoading;
  final String? error;

  const ChatFoldersState({
    this.folders = const [],
    this.isLoading = false,
    this.error,
  });

  ChatFoldersState copyWith({
    List<ChatFolder>? folders,
    bool? isLoading,
    String? error,
  }) {
    return ChatFoldersState(
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatFoldersController extends StateNotifier<ChatFoldersState> {
  final ChatRepository _repository;

  ChatFoldersController(this._repository) : super(const ChatFoldersState()) {
    loadFolders();
  }

  Future<void> loadFolders() async {
    state = state.copyWith(isLoading: true);
    try {
      final folders = await _repository.getChatFolders();
      folders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(folders: folders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load folders: $e');
    }
  }

  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;
    try {
      final folder = ChatFolder(
        id: 'chat_fol_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        createdAt: DateTime.now(),
      );
      await _repository.saveChatFolder(folder);
      await loadFolders();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create folder: $e');
    }
  }

  Future<void> renameFolder(String folderId, String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      final idx = state.folders.indexWhere((f) => f.id == folderId);
      if (idx == -1) return;
      final updated = state.folders[idx].copyWith(name: newName.trim());
      await _repository.saveChatFolder(updated);
      await loadFolders();
    } catch (e) {
      state = state.copyWith(error: 'Failed to rename folder: $e');
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      await _repository.deleteChatFolder(folderId);
      await loadFolders();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete folder: $e');
    }
  }
}

final chatFoldersControllerProvider = StateNotifierProvider<ChatFoldersController, ChatFoldersState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatFoldersController(repo);
});
