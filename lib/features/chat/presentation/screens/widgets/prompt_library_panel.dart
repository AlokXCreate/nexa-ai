import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/core/widgets/premium_dialog.dart';
import 'package:localmind_ai/features/chat/domain/entities/prompt_template.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/prompt_library_controller.dart';

class PromptLibraryPanel extends ConsumerStatefulWidget {
  final Function(String) onPromptSelected;
  final VoidCallback onClose;

  const PromptLibraryPanel({
    super.key,
    required this.onPromptSelected,
    required this.onClose,
  });

  @override
  ConsumerState<PromptLibraryPanel> createState() => _PromptLibraryPanelState();
}

class _PromptLibraryPanelState extends ConsumerState<PromptLibraryPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(promptLibraryControllerProvider);
    final notifier = ref.read(promptLibraryControllerProvider.notifier);

    // Apply search filter
    final filteredTemplates = libraryState.templates.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return GlassContainer(
      borderRadius: 16,
      blur: 20,
      color: AppColors.background.withOpacity(0.92),
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Prompt Library & Templates', style: AppTypography.titleMedium),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search prompts and templates...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 16),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Library'),
              Tab(text: 'Custom'),
              Tab(text: 'History'),
              Tab(text: 'Starred'),
            ],
          ),
          const SizedBox(height: 12),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTemplateTab(filteredTemplates, 'library', notifier),
                _buildTemplateTab(filteredTemplates, 'custom', notifier, showCreate: true),
                _buildTemplateTab(filteredTemplates, 'history', notifier),
                _buildTemplateTab(filteredTemplates, 'starred', notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateTab(
    List<PromptTemplate> allTemplates,
    String category,
    PromptLibraryController notifier, {
    bool showCreate = false,
  }) {
    List<PromptTemplate> list;
    if (category == 'starred') {
      list = allTemplates.where((t) => t.isFavorite).toList();
    } else {
      list = allTemplates.where((t) => t.category == category).toList();
    }

    return Column(
      children: [
        if (showCreate) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Create Custom Template', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                foregroundColor: AppColors.primary,
              ),
              onPressed: () => _showCreateTemplateDialog(notifier),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    category == 'history'
                        ? 'No history prompts yet.'
                        : category == 'starred'
                            ? 'No starred prompts.'
                            : 'No templates found.',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final t = list[index];
                    return _buildTemplateCard(t, notifier);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(PromptTemplate template, PromptLibraryController notifier) {
    final hasPlaceholders = template.placeholders.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                template.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            if (hasPlaceholders)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
                ),
                child: const Text('TEMPLATE', style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            template.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            template.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            color: template.isFavorite ? Colors.amberAccent : AppColors.textMuted,
            size: 20,
          ),
          onPressed: () => notifier.toggleFavorite(template.id),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                template.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: template.isPinned ? Colors.orangeAccent : AppColors.textMuted,
                size: 16,
              ),
              onPressed: () => notifier.togglePinned(template.id),
            ),
            if (template.category == 'custom')
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                onPressed: () => notifier.deleteTemplate(template.id),
              ),
          ],
        ),
        onTap: () => _handleTemplateSelection(template, notifier),
      ),
    );
  }

  void _handleTemplateSelection(PromptTemplate template, PromptLibraryController notifier) {
    if (template.placeholders.isEmpty) {
      widget.onPromptSelected(template.content);
      notifier.recordPromptHistory(template.content);
    } else {
      _showVariablesDialog(template, notifier);
    }
  }

  void _showVariablesDialog(PromptTemplate template, PromptLibraryController notifier) {
    final keys = template.placeholders;
    final Map<String, TextEditingController> controllers = {
      for (var key in keys) key: TextEditingController()
    };

    showDialog(
      context: context,
      builder: (context) => PremiumDialog(
        title: template.title,
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete prompt template placeholders:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...keys.map((key) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: controllers[key],
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Enter value for [$key]...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          border: InputBorder.none,
                          labelText: key.toUpperCase(),
                          labelStyle: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Inject Prompt', style: TextStyle(color: Colors.white)),
            onPressed: () {
              var resolvedContent = template.content;
              controllers.forEach((key, controller) {
                final val = controller.text.trim();
                resolvedContent = resolvedContent.replaceAll('[$key]', val.isEmpty ? '[$key]' : val);
              });
              
              // Clean up text field controllers
              controllers.forEach((_, c) => c.dispose());
              
              Navigator.of(context).pop();
              widget.onPromptSelected(resolvedContent);
              notifier.recordPromptHistory(resolvedContent);
            },
          ),
        ],
      ),
    );
  }

  void _showCreateTemplateDialog(PromptLibraryController notifier) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => PremiumDialog(
        title: 'New Prompt Template',
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'TEMPLATE NAME',
                    labelStyle: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    hintText: 'e.g. Code Optimizer',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: contentController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'PROMPT TEMPLATE',
                    labelStyle: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    hintText: 'Use brackets for variables, e.g. Write a [topic] about [length]...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () {
              titleController.dispose();
              contentController.dispose();
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Template', style: TextStyle(color: Colors.white)),
            onPressed: () {
              notifier.addCustomTemplate(titleController.text, contentController.text);
              titleController.dispose();
              contentController.dispose();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
