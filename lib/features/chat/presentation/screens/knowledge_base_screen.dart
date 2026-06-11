import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/chat/domain/entities/knowledge_note.dart';
import 'package:localmind_ai/features/chat/domain/entities/knowledge_collection.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/knowledge_base_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';

class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  ConsumerState<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAiPanelOpen = false;
  bool _isAiQnaMode = false;
  final TextEditingController _qnaInputController = TextEditingController();

  @override
  void dispose() {
    _qnaInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(knowledgeBaseControllerProvider);
    final controller = ref.read(knowledgeBaseControllerProvider.notifier);
    final runtimeState = ref.watch(localRuntimeControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.book_rounded, color: AppColors.secondary),
            const SizedBox(width: 8),
            Text(
              'Local Knowledge Base',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => controller.loadAll(),
          ),
          if (MediaQuery.of(context).size.width <= 900)
            IconButton(
              icon: const Icon(Icons.menu_open_rounded, color: AppColors.textSecondary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width <= 900
          ? Drawer(
              backgroundColor: AppColors.background,
              child: _buildSidebar(context, state, controller),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          
          if (isWide) {
            return Row(
              children: [
                // 1. Sidebar (Collections & Tags)
                SizedBox(
                  width: 250,
                  child: _buildSidebar(context, state, controller),
                ),
                VerticalDivider(width: 1, color: AppColors.border),
                
                // 2. Note Cards List
                SizedBox(
                  width: 320,
                  child: _buildNoteListPanel(context, state, controller),
                ),
                VerticalDivider(width: 1, color: AppColors.border),
                
                // 3. Workspace Detail (Editor / Preview)
                Expanded(
                  child: _buildWorkspace(context, state, controller, runtimeState),
                ),

                // 4. Slide-out AI Panel
                if (_isAiPanelOpen) ...[
                  VerticalDivider(width: 1, color: AppColors.border),
                  SizedBox(
                    width: 350,
                    child: _buildAiPanel(context, state, controller, runtimeState),
                  ),
                ],
              ],
            );
          } else {
            // Mobile layout
            return WillPopScope(
              onWillPop: () async {
                if (state.selectedNoteId != null) {
                  controller.selectNote(null);
                  return false;
                }
                return true;
              },
              child: state.selectedNoteId == null
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildNoteListPanel(context, state, controller),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        _buildWorkspace(context, state, controller, runtimeState),
                        if (_isAiPanelOpen)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 80, // Keep space for floating bottom nav
                            child: Card(
                              color: AppColors.surfaceElevated,
                              margin: EdgeInsets.zero,
                              elevation: 16,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                              ),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.85,
                                child: _buildAiPanel(context, state, controller, runtimeState),
                              ),
                            ),
                          ),
                      ],
                    ),
            );
          }
        },
      ),
    );
  }

  // --- Sidebar Component ---
  Widget _buildSidebar(
    BuildContext context,
    KnowledgeBaseState state,
    KnowledgeBaseController controller,
  ) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        children: [
          // Header / Reset
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notes_rounded, color: AppColors.primary),
            title: const Text('All Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () {
              controller.selectCollection(null);
              controller.setSelectedCategory(null);
              controller.setSelectedTag(null);
              if (MediaQuery.of(context).size.width <= 900) {
                Navigator.pop(context);
              }
            },
          ),
          
          const Divider(color: AppColors.border),
          
          // Quick Filters
          _buildQuickFilterTile(
            icon: Icons.push_pin_rounded,
            label: 'Pinned Notes',
            active: state.showPinnedOnly,
            color: AppColors.warning,
            onTap: () => controller.togglePinnedOnly(),
          ),
          _buildQuickFilterTile(
            icon: Icons.favorite_rounded,
            label: 'Favorites',
            active: state.showFavoritesOnly,
            color: AppColors.error,
            onTap: () => controller.toggleFavoritesOnly(),
          ),

          const SizedBox(height: 16),
          
          // Folders / Collections Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOLDERS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined, color: AppColors.secondary, size: 20),
                onPressed: () => _showCreateFolderDialog(context, controller),
              ),
            ],
          ),
          
          if (state.collections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No folders created yet',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          
          ...state.collections.map((col) {
            final isSelected = state.selectedCollectionId == col.id;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Icon(
                isSelected ? Icons.folder_open_rounded : Icons.folder_rounded,
                color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                size: 20,
              ),
              title: Text(
                col.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textMuted),
                onSelected: (val) {
                  if (val == 'rename') {
                    _showRenameFolderDialog(context, controller, col);
                  } else if (val == 'delete') {
                    _showDeleteFolderConfirm(context, controller, col);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Folder', style: TextStyle(color: AppColors.error))),
                ],
              ),
              onTap: () {
                controller.selectCollection(col.id);
                if (MediaQuery.of(context).size.width <= 900) {
                  Navigator.pop(context);
                }
              },
            );
          }),

          const SizedBox(height: 20),

          // Categories Section
          Text(
            'CATEGORIES',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (controller.allCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('No categories yet', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: controller.allCategories.map((cat) {
              final isSelected = state.selectedCategory == cat;
              return GestureDetector(
                onTap: () => controller.setSelectedCategory(cat),
                child: Chip(
                  label: Text(cat, style: const TextStyle(fontSize: 11)),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: isSelected ? AppColors.secondary : AppColors.surfaceElevated,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Tags Section
          Text(
            'TAGS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (controller.allTags.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('No tags created', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: controller.allTags.map((tag) {
              final isSelected = state.selectedTag == tag;
              return GestureDetector(
                onTap: () => controller.setSelectedTag(tag),
                child: Chip(
                  avatar: Icon(Icons.local_offer_rounded, size: 10, color: isSelected ? Colors.black : AppColors.primary),
                  label: Text(tag, style: const TextStyle(fontSize: 11)),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                  backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterTile({
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: active ? color : AppColors.textSecondary, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.textSecondary,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: active ? Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)) : null,
      onTap: onTap,
    );
  }

  // --- Note Cards List Panel ---
  Widget _buildNoteListPanel(
    BuildContext context,
    KnowledgeBaseState state,
    KnowledgeBaseController controller,
  ) {
    return Container(
      color: AppColors.surface.withOpacity(0.4),
      child: Column(
        children: [
          // Search Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => controller.setSearchQuery(val),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: state.isSemanticSearch ? 'Semantic AI search...' : 'Search notes...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 16),
                            onPressed: () {
                              controller.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI Semantic Search',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Switch.adaptive(
                      value: state.isSemanticSearch,
                      activeColor: AppColors.secondary,
                      onChanged: (val) => controller.toggleSemanticSearch(val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Notes List
          Expanded(
            child: state.filteredNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notes_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            state.searchQuery.isNotEmpty 
                                ? 'No notes matched your search' 
                                : 'No notes in this folder',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('New Note', style: TextStyle(color: Colors.white)),
                            onPressed: () => controller.createNote(
                              title: 'Untitled Note',
                              content: '# New Markdown Note\n\nStart writing here...',
                              collectionId: state.selectedCollectionId,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.filteredNotes.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final note = state.filteredNotes[index];
                      final isSelected = state.selectedNoteId == note.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: () => controller.selectNote(note.id),
                          child: GlassContainer(
                            color: isSelected 
                                ? AppColors.primary.withOpacity(0.15) 
                                : AppColors.surface.withOpacity(0.7),
                            borderColor: isSelected 
                                ? AppColors.secondary.withOpacity(0.5) 
                                : AppColors.border,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (note.isPinned)
                                      Icon(Icons.push_pin_rounded, color: AppColors.warning, size: 14),
                                    if (note.isPinned) const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        note.title.isNotEmpty ? note.title : 'Untitled',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (note.isFavorite)
                                      Icon(Icons.favorite_rounded, color: AppColors.error, size: 14),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _stripMarkdown(note.content),
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(note.updatedAt),
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                                    ),
                                    if (note.category != null && note.category!.trim().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          note.category!,
                                          style: const TextStyle(color: AppColors.secondary, fontSize: 9, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Sticky Bottom Add Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('Add Note', style: TextStyle(color: Colors.white)),
                onPressed: () => controller.createNote(
                  title: 'Untitled Note',
                  content: '# New Markdown Note\n\nStart writing here...',
                  collectionId: state.selectedCollectionId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Workspace (Editor / Preview) Component ---
  Widget _buildWorkspace(
    BuildContext context,
    KnowledgeBaseState state,
    KnowledgeBaseController controller,
    LocalRuntimeState runtimeState,
  ) {
    if (state.selectedNoteId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_rounded, color: AppColors.textMuted.withOpacity(0.2), size: 100),
            const SizedBox(height: 16),
            const Text(
              'No note selected',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a note from the list, or create a new one to begin editing.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final noteIndex = state.notes.indexWhere((n) => n.id == state.selectedNoteId);
    if (noteIndex == -1) {
      return const Center(child: CircularProgressIndicator());
    }
    final note = state.notes[noteIndex];

    return _NoteEditorView(
      note: note,
      collections: state.collections,
      isAiPanelOpen: _isAiPanelOpen,
      onSave: (updated) => controller.updateNote(updated),
      onDelete: () => controller.deleteNote(note.id),
      onTogglePin: () => controller.togglePin(note.id),
      onToggleFavorite: () => controller.toggleFavorite(note.id),
      onToggleAiPanel: (isQna) {
        setState(() {
          if (_isAiPanelOpen && _isAiQnaMode == isQna) {
            _isAiPanelOpen = false;
          } else {
            _isAiPanelOpen = true;
            _isAiQnaMode = isQna;
          }
        });
        if (_isAiPanelOpen) {
          if (!isQna) {
            controller.summarizeNote(note.id);
          } else {
            _qnaInputController.clear();
          }
        }
      },
      onBack: () => controller.selectNote(null),
    );
  }

  // --- AI Assistant Panel Component ---
  Widget _buildAiPanel(
    BuildContext context,
    KnowledgeBaseState state,
    KnowledgeBaseController controller,
    LocalRuntimeState runtimeState,
  ) {
    final noteIndex = state.notes.indexWhere((n) => n.id == state.selectedNoteId);
    if (noteIndex == -1) return const SizedBox.shrink();
    final note = state.notes[noteIndex];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isAiQnaMode ? Icons.chat_bubble_outline_rounded : Icons.summarize_outlined,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAiQnaMode ? 'Note Q&A Chat' : 'AI Note Summary',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: () {
                  setState(() {
                    _isAiPanelOpen = false;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Local Model Status Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: runtimeState.isModelLoaded 
                  ? AppColors.success.withOpacity(0.08) 
                  : AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: runtimeState.isModelLoaded 
                    ? AppColors.success.withOpacity(0.3) 
                    : AppColors.warning.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  runtimeState.isModelLoaded ? Icons.check_circle : Icons.warning_rounded,
                  color: runtimeState.isModelLoaded ? AppColors.success : AppColors.warning,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    runtimeState.isModelLoaded
                        ? 'LLM Engine Active: ${runtimeState.activeModelId?.split('/').last ?? 'GGUF model'}'
                        : 'No active local model loaded. Go to Chats tab to run a model.',
                    style: TextStyle(
                      color: runtimeState.isModelLoaded ? Colors.white : AppColors.warning,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Output Panel
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.isGeneratingAi && state.aiOutput.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(strokeWidth: 2),
                              SizedBox(height: 12),
                              Text('Model is thinking...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else if (state.aiOutput.isNotEmpty) ...[
                      MarkdownBody(
                        data: state.aiOutput,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                          listBullet: const TextStyle(color: AppColors.secondary),
                        ),
                      ),
                      if (state.isGeneratingAi) ...[
                        const SizedBox(height: 12),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                        ),
                      ]
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            _isAiQnaMode 
                                ? 'Ask a question about this note.' 
                                : 'Press summarize to write a brief overview.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Input / Trigger Action
          const SizedBox(height: 12),
          if (!_isAiQnaMode)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.summarize, color: Colors.white, size: 18),
                    label: const Text('Regenerate Summary', style: TextStyle(color: Colors.white, fontSize: 13)),
                    onPressed: state.isGeneratingAi 
                        ? null 
                        : () => controller.summarizeNote(note.id),
                  ),
                ),
                if (state.isGeneratingAi) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withOpacity(0.2),
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.stop, color: AppColors.error),
                    onPressed: () => controller.stopAiGeneration(),
                  ),
                ],
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qnaInputController,
                    onSubmitted: (val) {
                      if (runtimeState.isModelLoaded && !state.isGeneratingAi) {
                        controller.askNoteQuestion(note.id, val);
                        _qnaInputController.clear();
                      }
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ask note question...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (state.isGeneratingAi)
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withOpacity(0.2),
                    ),
                    icon: const Icon(Icons.stop, color: AppColors.error, size: 20),
                    onPressed: () => controller.stopAiGeneration(),
                  )
                else
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    icon: const Icon(Icons.send, color: Colors.black, size: 18),
                    onPressed: () {
                      final question = _qnaInputController.text.trim();
                      if (question.isNotEmpty) {
                        controller.askNoteQuestion(note.id, question);
                        _qnaInputController.clear();
                      }
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- Helper Helpers ---
  String _stripMarkdown(String text) {
    // Strip headers
    var clean = text.replaceAll(RegExp(r'#+\s+'), '');
    // Strip bold/italics
    clean = clean.replaceAll(RegExp(r'\*\*|__|\*|_'), '');
    // Strip links
    clean = clean.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), '\$1');
    // Normalize spacing
    return clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'Just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // --- Folders CRUD Dialogs ---
  void _showCreateFolderDialog(BuildContext context, KnowledgeBaseController controller) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Create New Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Folder name...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondary)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                controller.createCollection(name);
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(
    BuildContext context, 
    KnowledgeBaseController controller, 
    KnowledgeCollection col,
  ) {
    final textController = TextEditingController(text: col.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Rename Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Folder name...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondary)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Rename', style: TextStyle(color: Colors.white)),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                controller.renameCollection(col.id, name);
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderConfirm(
    BuildContext context,
    KnowledgeBaseController controller,
    KnowledgeCollection col,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete Folder?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${col.name}"? Notes in this folder will NOT be deleted; they will be moved to the root folder list.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () {
              controller.deleteCollection(col.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

// --- Inner Note Editor & Viewer View (Stateful to prevent Cursor Jitter) ---
class _NoteEditorView extends StatefulWidget {
  final KnowledgeNote note;
  final List<KnowledgeCollection> collections;
  final bool isAiPanelOpen;
  final Function(KnowledgeNote) onSave;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleFavorite;
  final Function(bool isQna) onToggleAiPanel;
  final VoidCallback onBack;

  const _NoteEditorView({
    required this.note,
    required this.collections,
    required this.isAiPanelOpen,
    required this.onSave,
    required this.onDelete,
    required this.onTogglePin,
    required this.onToggleFavorite,
    required this.onToggleAiPanel,
    required this.onBack,
  });

  @override
  State<_NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends State<_NoteEditorView> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _categoryController = TextEditingController(text: widget.note.category ?? '');
    _tagsController = TextEditingController(text: widget.note.tags.join(', '));
  }

  @override
  void didUpdateWidget(covariant _NoteEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _titleController.text = widget.note.title;
      _contentController.text = widget.note.content;
      _categoryController.text = widget.note.category ?? '';
      _tagsController.text = widget.note.tags.join(', ');
      _isPreviewMode = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _triggerAutoSave() {
    final cleanTags = _tagsController.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
        
    final updated = widget.note.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text,
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      tags: cleanTags,
      clearCategory: _categoryController.text.trim().isEmpty,
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 900;
    
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Action Bar Top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                    onPressed: widget.onBack,
                  ),
                
                // Pin / Favorite Quick Actions
                IconButton(
                  icon: Icon(
                    widget.note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    color: widget.note.isPinned ? AppColors.warning : AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: widget.onTogglePin,
                ),
                IconButton(
                  icon: Icon(
                    widget.note.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: widget.note.isFavorite ? AppColors.error : AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: widget.onToggleFavorite,
                ),

                const Spacer(),

                // Toggle Preview Mode
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPreviewMode = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isPreviewMode ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: !_isPreviewMode ? AppColors.secondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPreviewMode = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isPreviewMode ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                          ),
                          child: Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: _isPreviewMode ? AppColors.secondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // AI Assist buttons
                PopupMenuButton<String>(
                  icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary),
                  onSelected: (val) {
                    if (val == 'summary') {
                      widget.onToggleAiPanel(false);
                    } else if (val == 'qna') {
                      widget.onToggleAiPanel(true);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'summary',
                      child: Row(
                        children: [
                          Icon(Icons.summarize_outlined, color: AppColors.secondary, size: 18),
                          SizedBox(width: 8),
                          Text('AI Summarize'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'qna',
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: AppColors.secondary, size: 18),
                          SizedBox(width: 8),
                          Text('Chat with Note'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _confirmDeleteDialog(context),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppColors.border),
          
          // Note Title & Meta Fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                // Title Field
                TextField(
                  controller: _titleController,
                  onChanged: (val) => _triggerAutoSave(),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Note Title...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Metadata Row (Folder, Category, Tags)
                Row(
                  children: [
                    // Folder Select Dropdown
                    Icon(Icons.folder_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: widget.note.collectionId,
                          hint: const Text('No Folder', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          dropdownColor: AppColors.surfaceElevated,
                          iconSize: 16,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Uncategorized'),
                            ),
                            ...widget.collections.map((col) => DropdownMenuItem(
                                  value: col.id,
                                  child: Text(col.name),
                                )),
                          ],
                          onChanged: (val) {
                            final updated = widget.note.copyWith(
                              collectionId: val,
                              clearCollectionId: val == null,
                            );
                            widget.onSave(updated);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Category Input
                    Icon(Icons.category_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _categoryController,
                        onChanged: (val) => _triggerAutoSave(),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Category (e.g. Work)',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // Tags row
                Row(
                  children: [
                    Icon(Icons.local_offer_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _tagsController,
                        onChanged: (val) => _triggerAutoSave(),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Tags (comma separated: dev, ideas, notes)',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppColors.border),
          
          // Body content editor / preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isPreviewMode
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: MarkdownBody(
                          data: _contentController.text.isNotEmpty 
                              ? _contentController.text 
                              : '*No note body text written yet. Switch to Edit mode to write.*',
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.5),
                            h1: const TextStyle(color: AppColors.secondary, fontSize: 24, fontWeight: FontWeight.bold, height: 1.8),
                            h2: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold, height: 1.6),
                            h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
                            listBullet: const TextStyle(color: AppColors.secondary),
                            code: const TextStyle(
                              backgroundColor: AppColors.surface,
                              color: AppColors.secondary,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            blockquote: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            blockquoteDecoration: const BoxDecoration(
                              border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
                            ),
                          ),
                        ),
                      ),
                    )
                  : TextField(
                      controller: _contentController,
                      onChanged: (val) => _triggerAutoSave(),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: 'Start writing in Markdown (# Header, - bullet, etc.)...',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete Note?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this note permanently? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () {
              widget.onDelete();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
