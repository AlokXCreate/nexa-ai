import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/core/widgets/premium_dialog.dart';
import 'package:localmind_ai/core/widgets/markdown_code_block.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_session.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_folder.dart';
import 'package:localmind_ai/features/chat/domain/entities/rag_document.dart';
import 'package:localmind_ai/features/chat/domain/entities/rag_folder.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_sessions_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_messages_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/rag_documents_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_folders_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/prompt_library_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/plugins/presentation/controllers/cloud_settings_controller.dart';
import 'package:localmind_ai/features/chat/presentation/screens/widgets/parameter_config_panel.dart';
import 'package:localmind_ai/features/chat/presentation/screens/widgets/prompt_library_panel.dart';
import 'package:localmind_ai/features/chat/data/services/chat_export_helper.dart';
import 'package:localmind_ai/features/voice/presentation/screens/widgets/voice_assistant_panel.dart';
import 'package:localmind_ai/features/voice/presentation/controllers/voice_controller.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String _activeTab = 'sessions'; // 'sessions' or 'kb'
  bool _isEditingSessionTitle = false;
  bool _showPromptLibrary = false;
  late TextEditingController _sessionTitleController;

  @override
  void initState() {
    super.initState();
    _sessionTitleController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sessionTitleController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsState = ref.watch(chatSessionsControllerProvider);
    final messagesState = ref.watch(chatMessagesControllerProvider);
    final runtimeState = ref.watch(localRuntimeControllerProvider);

    final activeSession = sessionsState.activeSessionId != null
        ? sessionsState.sessions.firstWhere((s) => s.id == sessionsState.activeSessionId)
        : null;

    // Trigger scroll when new messages arrive or streaming text updates
    ref.listen<ChatMessagesState>(chatMessagesControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    ref.listen<LocalRuntimeState>(localRuntimeControllerProvider, (prev, next) {
      if (next.isGenerating) {
        _scrollToBottom();
      }
    });

    // Check error states
    if (messagesState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messagesState.error!), backgroundColor: AppColors.error),
        );
        ref.read(chatMessagesControllerProvider.notifier).clearError();
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildLeftSidebar(sessionsState, activeSession),
      endDrawer: activeSession != null ? ParameterConfigPanel(session: activeSession) : null,
      appBar: _buildAppBar(activeSession, runtimeState, messagesState),
      body: Row(
        children: [
          // Main conversation workspace
          Expanded(
            child: activeSession == null
                ? _buildEmptyStateWorkspace()
                : _buildConversationWorkspace(messagesState, runtimeState, activeSession),
          ),
          if (_showPromptLibrary && activeSession != null)
            SizedBox(
              width: 360,
              child: PromptLibraryPanel(
                onPromptSelected: (prompt) {
                  setState(() {
                    _messageController.text = prompt;
                    _showPromptLibrary = false;
                  });
                },
                onClose: () => setState(() => _showPromptLibrary = false),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatSession? session, LocalRuntimeState runtime, ChatMessagesState messagesState) {
    return AppBar(
      backgroundColor: AppColors.background.withOpacity(0.9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: session == null
          ? Text('LocalMind AI Console', style: AppTypography.titleMedium)
          : _buildAppBarSessionTitle(session),
      actions: [
        if (runtime.isGenerating) ...[
          _buildMetricsBadge(runtime),
          const SizedBox(width: 8),
        ],
        if (session != null) ...[
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
            onPressed: () => _showExportDialog(session, messagesState.messages),
            tooltip: 'Export conversation',
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ],
    );
  }

  Widget _buildAppBarSessionTitle(ChatSession session) {
    if (_isEditingSessionTitle) {
      return TextField(
        controller: _sessionTitleController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          border: InputBorder.none,
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
        ),
        onSubmitted: (val) {
          if (val.trim().isNotEmpty) {
            ref.read(chatSessionsControllerProvider.notifier).renameSession(session.id, val.trim());
          }
          setState(() => _isEditingSessionTitle = false);
        },
      );
    }

    return GestureDetector(
      onDoubleTap: () {
        _sessionTitleController.text = session.title;
        setState(() => _isEditingSessionTitle = true);
      },
      child: Text(
        session.title,
        style: AppTypography.titleMedium,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMetricsBadge(LocalRuntimeState runtime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        '${runtime.performanceMetrics.tokensPerSecond.toStringAsFixed(1)} T/s • ${runtime.performanceMetrics.ramUsageMb.toStringAsFixed(0)} MB',
        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLeftSidebar(ChatSessionsState sessionsState, ChatSession? activeSession) {
    final kbState = ref.watch(ragDocumentsControllerProvider);
    final installedState = ref.watch(installedModelsControllerProvider);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: 0,
        blur: 20,
        color: AppColors.background.withOpacity(0.95),
        borderColor: AppColors.border,
        padding: const EdgeInsets.only(top: kToolbarHeight - 10, left: 12, right: 12, bottom: 20),
        child: Column(
          children: [
            // Top Session controls
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    label: 'New Session',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      final cloudState = ref.read(cloudSettingsControllerProvider);
                      final activeCloud = cloudState.configs.where((c) => c.isEnabled).toList();

                      if (installedState.installedModels.isEmpty && activeCloud.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please download a local model or configure a Cloud AI provider first.')),
                        );
                        return;
                      }

                      final defaultModel = installedState.installedModels.isNotEmpty
                          ? installedState.installedModels.first.id
                          : activeCloud.first.id;

                      ref.read(chatSessionsControllerProvider.notifier).createSession(defaultModel).then((_) {
                        _messageController.clear();
                        Navigator.of(context).pop(); // close drawer
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.compare_arrows_rounded, color: AppColors.primary, size: 16),
                    label: const Text('Compare Models', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // close drawer
                      context.push('/multi-model-compare');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 16),
                    label: const Text('AI Agents Console', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // close drawer
                      context.push('/agents');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs toggle: Sessions vs Knowledge Base
            Row(
              children: [
                _buildSidebarTab('Sessions', 'sessions', Icons.chat_bubble_outline_rounded),
                const SizedBox(width: 8),
                _buildSidebarTab('Knowledge (RAG)', 'kb', Icons.folder_open_rounded),
              ],
            ),
            const SizedBox(height: 16),

            // List Content
            Expanded(
              child: _activeTab == 'sessions'
                  ? _buildSessionsTab(sessionsState)
                  : _buildKbTab(kbState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTab(String label, String tabKey, IconData icon) {
    final isSelected = _activeTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tabKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary.withOpacity(0.3) : AppColors.border.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsTab(ChatSessionsState sessionsState) {
    final foldersState = ref.watch(chatFoldersControllerProvider);

    final Set<String> allTags = {};
    for (final s in sessionsState.sessions) {
      allTags.addAll(s.tags);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Box
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Search chats & history...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
              border: InputBorder.none,
              icon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 16),
            ),
            onChanged: (val) {
              ref.read(chatSessionsControllerProvider.notifier).setSearchQuery(val);
            },
          ),
        ),
        const SizedBox(height: 8),

        // 2. Tag filters chips
        if (allTags.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: FilterChip(
                    label: const Text('All', style: TextStyle(fontSize: 10)),
                    selected: sessionsState.selectedTag == null,
                    onSelected: (_) => ref.read(chatSessionsControllerProvider.notifier).setSelectedTag(null),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(color: sessionsState.selectedTag == null ? Colors.white : AppColors.textSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border)),
                  ),
                ),
                ...allTags.map((tag) {
                  final isSelected = sessionsState.selectedTag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: FilterChip(
                      label: Text('#$tag', style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      onSelected: (_) => ref.read(chatSessionsControllerProvider.notifier).setSelectedTag(isSelected ? null : tag),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border)),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 3. New Folder Button
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.create_new_folder_outlined, size: 12, color: AppColors.textSecondary),
                label: const Text('New Folder', style: TextStyle(color: Colors.white, fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () => _showCreateChatFolderDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4. Session Tree (Folders & Chats)
        Expanded(
          child: sessionsState.filteredSessions.isEmpty
              ? const Center(
                  child: Text('No active chats.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                )
              : ListView(
                  children: [
                    // Folders
                    ...foldersState.folders.map((folder) {
                      final folderSessions = sessionsState.filteredSessions
                          .where((s) => s.folderId == folder.id)
                          .toList();

                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          dense: true,
                          leading: const Icon(Icons.folder_rounded, color: Colors.orangeAccent, size: 18),
                          title: Text(
                            folder.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 12, color: AppColors.textMuted),
                                onPressed: () => _showRenameChatFolderDialog(folder),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 12, color: AppColors.error),
                                onPressed: () => ref.read(chatFoldersControllerProvider.notifier).deleteFolder(folder.id),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          children: folderSessions.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
                                    child: Text('Empty folder', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                  )
                                ]
                              : folderSessions.map((session) => _buildSessionItemRow(session, sessionsState)).toList(),
                        ),
                      );
                    }),

                    const Divider(color: AppColors.border, height: 16),

                    // Unassigned
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text('UNGROUPED CHATS', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                    ...sessionsState.filteredSessions
                        .where((s) => s.folderId == null)
                        .map((session) => _buildSessionItemRow(session, sessionsState)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSessionItemRow(ChatSession session, ChatSessionsState state) {
    final isActive = state.activeSessionId == session.id;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface.withOpacity(0.4) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 8, right: 4),
        title: Text(
          session.title,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: session.tags.isNotEmpty
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: session.tags.map((t) => Container(
                    margin: const EdgeInsets.only(right: 4, top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('#$t', style: const TextStyle(fontSize: 8, color: AppColors.primary)),
                  )).toList(),
                ),
              )
            : Text(
                'Model: ${session.modelId.replaceAll("_", " ")}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
              ),
        leading: Icon(
          session.isPinned ? Icons.push_pin_rounded : Icons.chat_bubble_outline_rounded,
          size: 14,
          color: session.isPinned ? Colors.orangeAccent : AppColors.textMuted,
        ),
        trailing: _buildSessionMenu(session),
        onTap: () {
          ref.read(chatSessionsControllerProvider.notifier).selectSession(session.id);
          Navigator.of(context).pop(); // close drawer
        },
      ),
    );
  }

  Widget _buildSessionMenu(ChatSession session) {
    final foldersState = ref.read(chatFoldersControllerProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 16),
      backgroundColor: AppColors.surfaceElevated,
      offset: const Offset(0, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (val) {
        if (val == 'pin') {
          ref.read(chatSessionsControllerProvider.notifier).pinSession(session.id, !session.isPinned);
        } else if (val == 'rename') {
          _sessionTitleController.text = session.title;
          setState(() {
            _isEditingSessionTitle = true;
          });
          ref.read(chatSessionsControllerProvider.notifier).selectSession(session.id);
          Navigator.of(context).pop(); // close drawer
        } else if (val == 'tags') {
          _showManageTagsDialog(session);
        } else if (val == 'delete') {
          ref.read(chatSessionsControllerProvider.notifier).deleteSession(session.id);
        } else if (val.startsWith('move_')) {
          final folderId = val.substring(5) == 'null' ? null : val.substring(5);
          ref.read(chatSessionsControllerProvider.notifier).moveSessionToFolder(session.id, folderId);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pin',
          child: Row(children: [
            Icon(session.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 14),
            const SizedBox(width: 8),
            Text(session.isPinned ? 'Unpin' : 'Pin')
          ]),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: Row(children: [Icon(Icons.edit_outlined, size: 14), SizedBox(width: 8), Text('Rename')]),
        ),
        const PopupMenuItem(
          value: 'tags',
          child: Row(children: [Icon(Icons.local_offer_outlined, size: 14), SizedBox(width: 8), Text('Tags')]),
        ),
        PopupMenuItem(
          enabled: false,
          child: Row(children: [
            const Icon(Icons.folder_open_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text('Move to:', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold))
          ]),
        ),
        PopupMenuItem(
          value: 'move_null',
          child: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Row(children: [Icon(Icons.folder_off_rounded, size: 12), SizedBox(width: 8), Text('Ungrouped')]),
          ),
        ),
        ...foldersState.folders.map((folder) => PopupMenuItem(
              value: 'move_${folder.id}',
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(children: [const Icon(Icons.folder_rounded, size: 12, color: Colors.orangeAccent), const SizedBox(width: 8), Text(folder.name)]),
              ),
            )),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 14), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
        ),
      ],
    );
  }

  Widget _buildKbTab(RagDocumentsState state) {
    return Column(
      children: [
        // Import Document & New Folder Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.create_new_folder_outlined, size: 14),
                label: const Text('New Folder', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () => _showCreateFolderDialog(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_upload_outlined, size: 14),
                label: const Text('Import Doc', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () => _showImportDocDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (state.isImporting) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.importProgress,
              backgroundColor: AppColors.border.withOpacity(0.3),
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Extracting & Indexing... ${(state.importProgress * 100).toInt()}%',
            style: const TextStyle(color: AppColors.success, fontSize: 10),
          ),
          const SizedBox(height: 12),
        ],

        // List Folders & Documents
        Expanded(
          child: ListView(
            children: [
              // 1. Folders
              if (state.folders.isNotEmpty) ...[
                const Text('FOLDERS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...state.folders.map((folder) => _buildFolderRow(folder, state.documents)),
                const SizedBox(height: 16),
              ],

              // 2. Unassigned Documents
              const Text('UNASSIGNED DOCUMENTS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...state.documents
                  .where((d) => d.folderId == null)
                  .map((doc) => _buildDocRow(doc)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFolderRow(RagFolder folder, List<RagDocument> allDocs) {
    final folderDocs = allDocs.where((d) => d.folderId == folder.id).toList();

    return ExpansionTile(
      dense: true,
      textColor: Colors.white,
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.textSecondary,
      leading: const Icon(Icons.folder_rounded, color: AppColors.secondary, size: 18),
      title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 14),
        onPressed: () => ref.read(ragDocumentsControllerProvider.notifier).deleteFolder(folder.id),
      ),
      children: [
        if (folderDocs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text('Empty Folder', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          )
        else
          ...folderDocs.map((doc) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _buildDocRow(doc),
          )),
      ],
    );
  }

  Widget _buildDocRow(RagDocument doc) {
    final bytesStr = '${(doc.sizeBytes / 1024).toStringAsFixed(1)} KB';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 8, right: 4),
        title: Text(
          doc.name,
          style: TextStyle(color: doc.isActive ? Colors.white : AppColors.textSecondary, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$bytesStr • ${doc.chunkCount} paragraphs',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
        ),
        leading: Checkbox(
          value: doc.isActive,
          activeColor: AppColors.success,
          onChanged: (val) {
            if (val != null) {
              ref.read(ragDocumentsControllerProvider.notifier).toggleDocumentActive(doc.id, val);
            }
          },
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 14),
          onPressed: () => ref.read(ragDocumentsControllerProvider.notifier).deleteDocument(doc.id),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWorkspace() {
    final installedState = ref.watch(installedModelsControllerProvider);

    return Container(
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('LocalMind AI Console', style: AppTypography.titleLarge.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                '100% Offline Retrieval-Augmented Generation',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              final cloudState = ref.watch(cloudSettingsControllerProvider);
              final hasCloudEnabled = cloudState.configs.any((c) => c.isEnabled);

              if (installedState.installedModels.isEmpty && !hasCloudEnabled) ...[
                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
                const SizedBox(height: 8),
                Text(
                  'No local models downloaded or cloud APIs configured. Go to the Marketplace to download a model, or configure Cloud AI Integrations.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.orangeAccent),
                ),
              ] else ...[
                // Suggestion chips grid
                Text('Start a new session with prompt suggestions:', style: AppTypography.bodySmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSuggestionChip('What is Llama 3.2\'s context window?'),
                    _buildSuggestionChip('How does offline RAG work?'),
                    _buildSuggestionChip('Explain local GGUF quantizations.'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String prompt) {
    final installedState = ref.read(installedModelsControllerProvider);
    return ActionChip(
      label: Text(prompt, style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () {
        final cloudState = ref.read(cloudSettingsControllerProvider);
        final activeCloud = cloudState.configs.where((c) => c.isEnabled).toList();

        if (installedState.installedModels.isNotEmpty || activeCloud.isNotEmpty) {
          final defaultModel = installedState.installedModels.isNotEmpty
              ? installedState.installedModels.first.id
              : activeCloud.first.id;

          ref.read(chatSessionsControllerProvider.notifier).createSession(defaultModel).then((_) {
            _messageController.text = prompt;
            sendMessage();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please download a local model or configure a Cloud AI provider first.')),
          );
        }
      },
    );
  }

  Widget _buildConversationWorkspace(
    ChatMessagesState state,
    LocalRuntimeState runtime,
    ChatSession session,
  ) {
    final isGeneratingThisSession = runtime.isGenerating && state.activeSessionId == session.id;
    final libraryState = ref.watch(promptLibraryControllerProvider);
    final pinned = libraryState.templates.where((t) => t.isPinned).toList();

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: state.messages.length + (isGeneratingThisSession ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length) {
                  // Renders the streaming text block
                  return _buildMessageBubble(
                    ChatMessage(
                      id: 'streaming_ai',
                      sender: MessageSender.ai,
                      content: runtime.currentGenerationText,
                      timestamp: DateTime.now(),
                    ),
                    isStreaming: true,
                  );
                }

                final msg = state.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Pinned prompts chips
          if (pinned.isNotEmpty)
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pinned.length,
                itemBuilder: (context, index) {
                  final t = pinned[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(t.title, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.surfaceElevated,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border, width: 0.5)),
                      onPressed: () {
                        if (t.placeholders.isEmpty) {
                          _messageController.text = t.content;
                        } else {
                          setState(() {
                            _showPromptLibrary = true;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          // Message Input bar
          _buildInputBar(runtime, session),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, {bool isStreaming = false}) {
    final isUser = msg.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.android_rounded, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primary.withOpacity(0.85)
                          : AppColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      border: Border.all(
                        color: isUser ? Colors.transparent : AppColors.border,
                      ),
                    ),
                    child: _buildMessageContent(msg.content),
                  ),

                  if (isUser && msg.isEdited) ...[
                    const SizedBox(height: 2),
                    Text(
                      'edited',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                    ),
                  ],

                  if (!isUser && msg.sources != null && msg.sources!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildSourcesWidget(msg.sources!),
                  ],
                ],
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 14),
                backgroundColor: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditPromptDialog(msg);
                  } else if (val == 'delete') {
                    ref.read(chatMessagesControllerProvider.notifier).deleteMessage(msg.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_outlined, size: 14), SizedBox(width: 8), Text('Edit')]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 14), SizedBox(width: 8), Text('Delete')]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(String text) {
    // Basic markdown code blocks parser helper
    if (text.contains('```')) {
      final List<Widget> children = [];
      final parts = text.split('```');
      
      for (var i = 0; i < parts.length; i++) {
        if (i % 2 == 0) {
          // Regular text
          if (parts[i].trim().isNotEmpty) {
            children.add(SelectableText(parts[i], style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)));
          }
        } else {
          // Code block
          final lines = parts[i].split('\n');
          final language = lines.first.trim();
          final code = lines.sublist(1).join('\n').trim();
          
          children.add(MarkdownCodeBlock(code: code, language: language.isEmpty ? 'code' : language));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }

    return SelectableText(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
    );
  }

  Widget _buildSourcesWidget(List<String> sources) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        dense: true,
        collapsedBackgroundColor: AppColors.success.withOpacity(0.06),
        backgroundColor: AppColors.success.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.success.withOpacity(0.2), width: 0.5),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.success.withOpacity(0.15), width: 0.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.library_books_rounded, color: AppColors.success, size: 14),
            const SizedBox(width: 6),
            Text(
              'RAG Active • ${sources.length} sources referenced',
              style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        children: sources.map((source) {
          return Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                source,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar(LocalRuntimeState runtime, ChatSession session) {
    final useRag = session.useRag ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // RAG status pill
            IconButton(
              icon: Icon(
                useRag ? Icons.psychology_rounded : Icons.psychology_outlined,
                color: useRag ? AppColors.success : AppColors.textMuted,
              ),
              onPressed: () {
                ref.read(chatSessionsControllerProvider.notifier).updateSessionParams(
                  session.id,
                  useRag: !useRag,
                );
              },
              tooltip: useRag ? 'RAG is Active' : 'RAG is Disabled',
            ),
            const SizedBox(width: 4),

            // Prompt library toggle bulb
            IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _showPromptLibrary = !_showPromptLibrary;
                });
              },
              tooltip: 'Prompt Library & Templates',
            ),
            const SizedBox(width: 4),

            // Voice Assistant mic trigger
            IconButton(
              icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const VoiceAssistantPanel(),
                );
                // Trigger auto-start listening
                ref.read(voiceControllerProvider.notifier).startListening();
              },
              tooltip: 'Voice Assistant',
            ),
            const SizedBox(width: 8),

            // Input TextField
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: useRag ? 'Ask Knowledge Base...' : 'Type message...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  fillColor: AppColors.surface,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send / Stop button
            if (runtime.isGenerating)
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 18),
                  onPressed: () {
                    ref.read(localRuntimeControllerProvider.notifier).stopGeneration();
                  },
                ),
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  onPressed: sendMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatMessagesControllerProvider.notifier).sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. AI Documentation',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(ragDocumentsControllerProvider.notifier).createFolder(controller.text.trim());
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showImportDocDialog() {
    final pathController = TextEditingController();
    String fileType = 'pdf';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Import Knowledge Document', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pathController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Enter file path or mock name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: 'e.g. C:\\Users\\Name\\Desktop\\file.pdf',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('File Type:', style: TextStyle(color: AppColors.textSecondary)),
                  DropdownButton<String>(
                    value: fileType,
                    dropdownColor: AppColors.surfaceElevated,
                    items: ['pdf', 'docx', 'txt', 'md', 'html']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => fileType = val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Import'),
              onPressed: () {
                if (pathController.text.trim().isNotEmpty) {
                  ref.read(ragDocumentsControllerProvider.notifier).importDocument(
                        filePath: pathController.text.trim(),
                        fileType: fileType,
                      );
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPromptDialog(ChatMessage msg) {
    final controller = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Prompt', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Save & Regenerate'),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(chatMessagesControllerProvider.notifier).editMessage(msg.id, controller.text.trim());
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
  }

  void _showCreateChatFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => PremiumDialog(
        title: 'New Chat Folder',
        content: SizedBox(
          width: 300,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'e.g. Work Prompts',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create Folder', style: TextStyle(color: Colors.white)),
            onPressed: () {
              ref.read(chatFoldersControllerProvider.notifier).createFolder(controller.text);
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showRenameChatFolderDialog(ChatFolder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => PremiumDialog(
        title: 'Rename Folder',
        content: SizedBox(
          width: 300,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
            onPressed: () {
              ref.read(chatFoldersControllerProvider.notifier).renameFolder(folder.id, controller.text);
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showManageTagsDialog(ChatSession session) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sessionsState = ref.watch(chatSessionsControllerProvider);
            final currentSession = sessionsState.sessions.firstWhere((s) => s.id == session.id);

            return PremiumDialog(
              title: 'Manage Tags',
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentSession.tags.isNotEmpty) ...[
                      const Text('ACTIVE TAGS', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: currentSession.tags.map((t) => Chip(
                          label: Text('#$t', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          side: const BorderSide(color: AppColors.primary, width: 0.5),
                          padding: EdgeInsets.zero,
                          deleteIconColor: Colors.white70,
                          onDeleted: () {
                            ref.read(chatSessionsControllerProvider.notifier).removeTagFromSession(session.id, t);
                            setDialogState(() {});
                          },
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Add new tag (press Enter)...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            ref.read(chatSessionsControllerProvider.notifier).addTagToSession(session.id, val.trim());
                            controller.clear();
                            setDialogState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    controller.dispose();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showExportDialog(ChatSession session, List<ChatMessage> messages) {
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot export an empty conversation.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PremiumDialog(
        title: 'Export Conversation',
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a document format to export this conversation history:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildExportOption(session, messages, 'md', 'Markdown Document (.md)', Icons.markdown_rounded),
              _buildExportOption(session, messages, 'txt', 'Plain Text File (.txt)', Icons.text_snippet_outlined),
              _buildExportOption(session, messages, 'pdf', 'PDF Document (.pdf)', Icons.picture_as_pdf_outlined),
              _buildExportOption(session, messages, 'docx', 'Word Compatible Document (.docx)', Icons.description_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    ChatSession session,
    List<ChatMessage> messages,
    String format,
    String label,
    IconData icon,
  ) {
    return Card(
      color: AppColors.surfaceElevated,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.border, width: 0.5)),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.primary, size: 18),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        onTap: () async {
          Navigator.of(context).pop();
          try {
            final path = await ChatExportHelper.exportChat(
              sessionTitle: session.title,
              messages: messages,
              format: format,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Exported successfully to:\n$path', style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
            );
          }
        },
      ),
    );
  }
}
