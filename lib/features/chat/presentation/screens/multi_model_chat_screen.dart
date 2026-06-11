import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/core/widgets/premium_dialog.dart';
import 'package:localmind_ai/core/widgets/markdown_code_block.dart';
import 'package:localmind_ai/core/widgets/premium_shimmer.dart';
import 'package:localmind_ai/features/chat/domain/entities/compare_session.dart';
import 'package:localmind_ai/features/chat/domain/entities/compare_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/model_response.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/multi_model_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';

enum ComparisonLayout { split, tabs, matrix }

class MultiModelChatScreen extends ConsumerStatefulWidget {
  const MultiModelChatScreen({super.key});

  @override
  ConsumerState<MultiModelChatScreen> createState() => _MultiModelChatScreenState();
}

class _MultiModelChatScreenState extends ConsumerState<MultiModelChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  ComparisonLayout _layoutMode = ComparisonLayout.split;
  String? _selectedTabModelId; // For tabs mode active model

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
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
    final state = ref.watch(multiModelControllerProvider);
    final installedState = ref.watch(installedModelsControllerProvider);

    // Auto-scroll on loading tokens
    ref.listen<MultiModelState>(multiModelControllerProvider, (prev, next) {
      if (next.isComparing) {
        _scrollToBottom();
      }
    });

    final activeSession = state.activeSessionId != null
        ? state.compareSessions.firstWhere((s) => s.id == state.activeSessionId, orElse: () => state.compareSessions.first)
        : null;

    // Default the active tab model ID if not set
    if (activeSession != null && activeSession.modelIds.isNotEmpty) {
      if (_selectedTabModelId == null || !activeSession.modelIds.contains(_selectedTabModelId)) {
        _selectedTabModelId = activeSession.modelIds.first;
      }
    }

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
        );
        ref.read(multiModelControllerProvider.notifier).clearError();
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildLeftDrawer(state, activeSession),
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model Comparison Console', style: AppTypography.titleMedium),
            if (activeSession != null)
              Text(
                activeSession.title,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          _buildLayoutSelector(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.go('/chats'),
            tooltip: 'Back to standard chat',
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // Left sidebar model selection for setup (only if no active session)
            if (activeSession == null && installedState.installedModels.isNotEmpty)
              _buildModelSelectorSidebar(state, installedState),
            
            // Main conversation/comparison view
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: activeSession == null
                        ? _buildEmptyState(installedState)
                        : _buildMessagesList(state, activeSession, installedState),
                  ),
                  
                  // Message input bar
                  if (activeSession != null || state.selectedModelIds.length >= 2)
                    _buildInputBar(state, activeSession),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLayoutIcon(ComparisonLayout.split, Icons.splitscreen_rounded, 'Split View'),
          _buildLayoutIcon(ComparisonLayout.tabs, Icons.tab_rounded, 'Tabs View'),
          _buildLayoutIcon(ComparisonLayout.matrix, Icons.grid_view_rounded, 'Matrix View'),
        ],
      ),
    );
  }

  Widget _buildLayoutIcon(ComparisonLayout layout, IconData icon, String tooltip) {
    final isSelected = _layoutMode == layout;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _layoutMode = layout),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelectorSidebar(MultiModelState state, InstalledModelsState installedState) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT MODELS TO COMPARE',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pick 2 or more local LLMs. Prompts will run sequentially to safeguard physical system memory.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: installedState.installedModels.length,
              itemBuilder: (context, index) {
                final model = installedState.installedModels[index];
                final isSelected = state.selectedModelIds.contains(model.id);
                return Card(
                  color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary.withOpacity(0.5) : AppColors.border,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) {
                      ref.read(multiModelControllerProvider.notifier).toggleModelSelection(model.id);
                    },
                    title: Text(
                      model.localName,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Size: ${model.sizeString} • RAM req: ${model.ramRequirement}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    dense: true,
                  ),
                );
              },
            ),
          ),
          if (state.selectedModelIds.length >= 2) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PremiumButton(
                label: 'Initialize Comparison',
                icon: Icons.rocket_launch_rounded,
                onPressed: () {
                  ref.read(multiModelControllerProvider.notifier).createCompareSession(state.selectedModelIds);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(InstalledModelsState installedState) {
    if (installedState.installedModels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.download_for_offline_outlined, size: 60, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('No Downloaded Models Found', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              const Text(
                'Model comparison requires local LLM files to run offline. Please go to the marketplace to download models.',
                textAlign: Center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              PremiumButton(
                label: 'Go to Marketplace',
                icon: Icons.storefront_rounded,
                onPressed: () => context.go('/marketplace'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.compare_arrows_rounded, size: 60, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Multi-Model Comparison Engine', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Select models from the left sidebar or open an existing comparison session from the sidebar menu to begin comparing inference speeds, memory footprints, and generation quality.',
              textAlign: Center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    MultiModelState state,
    CompareSession session,
    InstalledModelsState installedState,
  ) {
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.message_outlined, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text('No messages in this comparison session.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Type a prompt below to trigger the sequential generation loop.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Prompt
            _buildUserMessageBubble(message.prompt),
            const SizedBox(height: 16),
            
            // Models Responses Layout
            _buildComparisonLayout(message, session, installedState),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildUserMessageBubble(String prompt) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: SelectableText(
          prompt,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildComparisonLayout(
    CompareMessage message,
    CompareSession session,
    InstalledModelsState installedState,
  ) {
    final rankBadges = _getRankingBadges(message);
    
    switch (_layoutMode) {
      case ComparisonLayout.split:
        return _buildSplitLayout(message, session, installedState, rankBadges);
      case ComparisonLayout.tabs:
        return _buildTabsLayout(message, session, installedState, rankBadges);
      case ComparisonLayout.matrix:
        return _buildMatrixLayout(message, session, installedState, rankBadges);
    }
  }

  // Helper to get local model display name
  String _getModelDisplayName(String modelId, InstalledModelsState installedState) {
    final idx = installedState.installedModels.indexWhere((m) => m.id == modelId);
    if (idx != -1) {
      return installedState.installedModels[idx].localName;
    }
    return modelId.replaceAll('_', ' ');
  }

  Widget _buildSplitLayout(
    CompareMessage message,
    CompareSession session,
    InstalledModelsState installedState,
    Map<String, List<Widget>> rankBadges,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: session.modelIds.map((modelId) {
          final response = message.modelResponses[modelId] ?? ModelResponse.empty(modelId);
          final displayName = _getModelDisplayName(modelId, installedState);
          final badges = rankBadges[modelId] ?? [];

          return Container(
            width: 380,
            margin: const EdgeInsets.only(right: 16),
            child: _buildModelResponseCard(
              displayName: displayName,
              response: response,
              badges: badges,
              message: message,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabsLayout(
    CompareMessage message,
    CompareSession session,
    InstalledModelsState installedState,
    Map<String, List<Widget>> rankBadges,
  ) {
    if (_selectedTabModelId == null || !session.modelIds.contains(_selectedTabModelId)) {
      _selectedTabModelId = session.modelIds.first;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: session.modelIds.map((modelId) {
              final isSelected = _selectedTabModelId == modelId;
              final response = message.modelResponses[modelId] ?? ModelResponse.empty(modelId);
              final displayName = _getModelDisplayName(modelId, installedState);
              final hasBadges = (rankBadges[modelId] ?? []).isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(displayName),
                      if (response.isGenerating) ...[
                        const SizedBox(width: 6),
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                        ),
                      ] else if (hasBadges) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 12),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedTabModelId = modelId),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        
        // Active tab card
        if (_selectedTabModelId != null) ...[
          _buildModelResponseCard(
            displayName: _getModelDisplayName(_selectedTabModelId!, installedState),
            response: message.modelResponses[_selectedTabModelId!] ?? ModelResponse.empty(_selectedTabModelId!),
            badges: rankBadges[_selectedTabModelId!] ?? [],
            message: message,
          ),
        ],
      ],
    );
  }

  Widget _buildMatrixLayout(
    CompareMessage message,
    CompareSession session,
    InstalledModelsState installedState,
    Map<String, List<Widget>> rankBadges,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table of comparative metrics
        Table(
          border: TableBorder.all(color: AppColors.border, width: 0.5, borderRadius: BorderRadius.circular(8)),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1.0),
            2: FlexColumnWidth(1.0),
            3: FlexColumnWidth(1.0),
            4: FlexColumnWidth(0.8),
          },
          children: [
            // Header
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFF161616)),
              children: [
                TableCell(padding: EdgeInsets.all(8), child: Text('Model', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                TableCell(padding: EdgeInsets.all(8), child: Text('Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                TableCell(padding: EdgeInsets.all(8), child: Text('Latency', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                TableCell(padding: EdgeInsets.all(8), child: Text('RAM Usage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                TableCell(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              ],
            ),
            
            // Model metrics rows
            ...session.modelIds.map((modelId) {
              final response = message.modelResponses[modelId] ?? ModelResponse.empty(modelId);
              final name = _getModelDisplayName(modelId, installedState);
              
              String status = 'Idle';
              Color statusColor = AppColors.textMuted;
              if (response.isQueued) {
                status = 'Queued';
                statusColor = Colors.orangeAccent;
              } else if (response.isGenerating) {
                status = 'Generating';
                statusColor = AppColors.primary;
              } else if (response.totalTokens > 0) {
                status = 'Finished';
                statusColor = AppColors.success;
              }

              return TableRow(
                children: [
                  TableCell(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                        const SizedBox(height: 2),
                        ...rankBadges[modelId]?.map((b) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: b,
                        )) ?? [],
                      ],
                    ),
                  ),
                  TableCell(padding: const EdgeInsets.all(8), child: Text('${response.tokensPerSecond.toStringAsFixed(1)} tok/s', style: const TextStyle(color: Colors.white, fontSize: 11))),
                  TableCell(padding: const EdgeInsets.all(8), child: Text('${response.timeToFirstTokenMs} ms', style: const TextStyle(color: Colors.white, fontSize: 11))),
                  TableCell(padding: const EdgeInsets.all(8), child: Text('${response.ramUsageMb.toStringAsFixed(0)} MB', style: const TextStyle(color: Colors.white, fontSize: 11))),
                  TableCell(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        
        // Export Comparison & side-by-side answers preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Comparative Answers Matrix',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Row(
              children: [
                _buildExportButton(message, 'Markdown'),
                const SizedBox(width: 8),
                _buildExportButton(message, 'CSV'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Grid layout of responses
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: session.modelIds.length == 1 ? 1 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: session.modelIds.map((modelId) {
            final response = message.modelResponses[modelId] ?? ModelResponse.empty(modelId);
            final name = _getModelDisplayName(modelId, installedState);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 14),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: response.content));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Response copied!')));
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: response.isQueued
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PremiumShimmer(width: 140, height: 12),
                                  SizedBox(height: 6),
                                  PremiumShimmer(width: 160, height: 12),
                                  SizedBox(height: 6),
                                  PremiumShimmer(width: 100, height: 12),
                                ],
                              ),
                            )
                          : response.content.isEmpty && response.isGenerating
                              ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                              : _buildMessageContent(response.content),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExportButton(CompareMessage message, String format) {
    return ElevatedButton.icon(
      icon: Icon(format == 'CSV' ? Icons.table_chart_rounded : Icons.copy_rounded, size: 12),
      label: Text('Copy $format', style: const TextStyle(fontSize: 10)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      onPressed: () {
        final content = ref.read(multiModelControllerProvider.notifier).exportComparison(message, format);
        Clipboard.setData(ClipboardData(text: content));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied comparison as $format to clipboard!')),
        );
      },
    );
  }

  Widget _buildModelResponseCard({
    required String displayName,
    required ModelResponse response,
    required List<Widget> badges,
    required CompareMessage message,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: response.isGenerating ? AppColors.primary.withOpacity(0.5) : AppColors.border,
          width: response.isGenerating ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of card
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: badges,
                        ),
                      ],
                    ],
                  ),
                ),
                if (response.isGenerating) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: response.content));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Response copied!')));
                    },
                    tooltip: 'Copy text',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(color: AppColors.border, height: 1),
          
          // Metrics Telemetry Panel
          _buildMetricsTelemetryPanel(response),
          
          const Divider(color: AppColors.border, height: 1),

          // Output Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: SingleChildScrollView(
                child: response.isQueued
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PremiumShimmer(width: 240, height: 16),
                            SizedBox(height: 8),
                            PremiumShimmer(width: 300, height: 16),
                            SizedBox(height: 8),
                            PremiumShimmer(width: 180, height: 16),
                            SizedBox(height: 16),
                            Text('Queued in execution pipeline...', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      )
                    : response.content.isEmpty && response.isGenerating
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PremiumShimmer(width: 280, height: 16),
                                SizedBox(height: 8),
                                PremiumShimmer(width: 220, height: 16),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Loading model weights into RAM...', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : _buildMessageContent(response.content),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsTelemetryPanel(ModelResponse response) {
    return Container(
      color: Colors.black.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTelemetryMetric(
            label: 'SPEED',
            value: '${response.tokensPerSecond.toStringAsFixed(1)} tok/s',
            color: Colors.greenAccent,
          ),
          _buildTelemetryMetric(
            label: 'LATENCY',
            value: '${response.timeToFirstTokenMs} ms',
            color: Colors.blueAccent,
          ),
          _buildTelemetryMetric(
            label: 'RAM USAGE',
            value: '${response.ramUsageMb.toStringAsFixed(0)} MB',
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(String text) {
    if (text.contains('```')) {
      final List<Widget> children = [];
      final parts = text.split('```');
      
      for (var i = 0; i < parts.length; i++) {
        if (i % 2 == 0) {
          if (parts[i].trim().isNotEmpty) {
            children.add(SelectableText(parts[i], style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)));
          }
        } else {
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

  Map<String, List<Widget>> _getRankingBadges(CompareMessage message) {
    final Map<String, List<Widget>> badges = {};
    for (final modelId in message.modelResponses.keys) {
      badges[modelId] = [];
    }

    final validResponses = message.modelResponses.entries
        .where((e) => e.value.totalTokens > 0 && !e.value.isGenerating && !e.value.isQueued)
        .toList();

    if (validResponses.isEmpty) return badges;

    // 1. Fastest Speed
    double maxSpeed = -1.0;
    String? fastestId;
    for (final entry in validResponses) {
      if (entry.value.tokensPerSecond > maxSpeed) {
        maxSpeed = entry.value.tokensPerSecond;
        fastestId = entry.key;
      }
    }
    if (fastestId != null && maxSpeed > 0) {
      badges[fastestId]!.add(_buildBadge('Fastest', Colors.greenAccent, Icons.flash_on_rounded));
    }

    // 2. Lowest Latency (TTFT)
    int minTtft = 999999;
    String? lowestLatencyId;
    for (final entry in validResponses) {
      if (entry.value.timeToFirstTokenMs < minTtft && entry.value.timeToFirstTokenMs > 0) {
        minTtft = entry.value.timeToFirstTokenMs;
        lowestLatencyId = entry.key;
      }
    }
    if (lowestLatencyId != null && minTtft < 999999) {
      badges[lowestLatencyId]!.add(_buildBadge('Fastest TTFT', Colors.blueAccent, Icons.timer_rounded));
    }

    // 3. Lowest RAM Usage
    double minRam = 999999.0;
    String? mostEfficientId;
    for (final entry in validResponses) {
      if (entry.value.ramUsageMb < minRam && entry.value.ramUsageMb > 0) {
        minRam = entry.value.ramUsageMb;
        mostEfficientId = entry.key;
      }
    }
    if (mostEfficientId != null && minRam < 999999.0) {
      badges[mostEfficientId]!.add(_buildBadge('Lowest RAM', Colors.orangeAccent, Icons.memory_rounded));
    }

    return badges;
  }

  Widget _buildInputBar(MultiModelState state, CompareSession? activeSession) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _promptController,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask all models a prompt...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) {
                  if (_promptController.text.trim().isNotEmpty && !state.isComparing) {
                    _sendPrompt();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (state.isComparing)
            GestureDetector(
              onTap: () {
                ref.read(multiModelControllerProvider.notifier).stopComparison();
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.error.withOpacity(0.2),
                child: const Icon(Icons.stop_rounded, color: AppColors.error),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                if (_promptController.text.trim().isNotEmpty) {
                  _sendPrompt();
                }
              },
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  void _sendPrompt() {
    final text = _promptController.text.trim();
    _promptController.clear();
    ref.read(multiModelControllerProvider.notifier).sendComparePrompt(text);
    _scrollToBottom();
  }

  Widget _buildLeftDrawer(MultiModelState state, CompareSession? activeSession) {
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
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    label: 'New Comparison',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      ref.read(multiModelControllerProvider.notifier).selectModels([]);
                      ref.read(multiModelControllerProvider.notifier).createCompareSession([]); // resets active session
                      Navigator.of(context).pop(); // close drawer
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'COMPARISON HISTORY',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: state.compareSessions.isEmpty
                  ? const Center(
                      child: Text('No compare history.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    )
                  : ListView.builder(
                      itemCount: state.compareSessions.length,
                      itemBuilder: (context, index) {
                        final session = state.compareSessions[index];
                        final isActive = activeSession?.id == session.id;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.surface.withOpacity(0.4) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              session.title,
                              style: TextStyle(
                                color: isActive ? Colors.white : AppColors.textSecondary,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${session.modelIds.length} models • ${session.createdAt.day}/${session.createdAt.month}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                            ),
                            leading: Icon(
                              Icons.compare_arrows_rounded,
                              size: 16,
                              color: isActive ? AppColors.primary : AppColors.textMuted,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 14),
                              onPressed: () {
                                ref.read(multiModelControllerProvider.notifier).deleteCompareSession(session.id);
                              },
                            ),
                            onTap: () {
                              ref.read(multiModelControllerProvider.notifier).selectCompareSession(session.id);
                              Navigator.of(context).pop(); // close drawer
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
