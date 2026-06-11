import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/model_details_controller.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/model_update_info.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/model_update_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/screens/widgets/model_update_dialog.dart';
import 'package:localmind_ai/features/optimizer/presentation/controllers/device_optimizer_controller.dart';

class ModelDetailsScreen extends ConsumerStatefulWidget {
  final String modelId;
  const ModelDetailsScreen({super.key, required this.modelId});

  @override
  ConsumerState<ModelDetailsScreen> createState() => _ModelDetailsScreenState();
}

class _ProfileHeader extends SliverPersistentHeaderDelegate {
  final MarketplaceModel model;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final double expandedHeight;

  _ProfileHeader({
    required this.model,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.expandedHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double opacity = 1.0 - (shrinkOffset / expandedHeight).clamp(0.0, 1.0);
    final double appbarOpacity = (shrinkOffset / expandedHeight).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Banner Image with Hero
        Hero(
          tag: 'banner_${model.id}',
          child: Opacity(
            opacity: opacity,
            child: model.banner.isNotEmpty
                ? Image.network(
                    model.banner,
                    fit: BoxFit.cover, // Wait, Cover should be BoxFit.cover! Let's make sure it is correct
                    // Let's use BoxFit.cover instead of Cover
                    errorBuilder: (c, e, s) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF161233), Color(0xFF0A0A0A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.blur_on_rounded, size: 64, color: AppColors.primary),
                      ),
                    ),
                  )
                : Container(color: AppColors.surface),
          ),
        ),

        // Gradient overlay for bottom readability
        Opacity(
          opacity: opacity,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.background],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // App Bar overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            backgroundColor: AppColors.background.withOpacity(appbarOpacity * 0.9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Opacity(
              opacity: appbarOpacity,
              child: Text(model.name, style: AppTypography.titleMedium),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () => _shareModel(context, model),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : Colors.white,
                ),
                onPressed: onFavoritePressed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight + 40;

  @override
  bool shouldRebuild(covariant _ProfileHeader oldDelegate) {
    return oldDelegate.model != model || oldDelegate.isFavorite != isFavorite;
  }

  void _shareModel(BuildContext context, MarketplaceModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Share Model', style: TextStyle(color: Colors.white)),
        content: Text(
          'Copy catalog link for ${model.name}:\n\n${model.downloadUrl}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ModelDetailsScreenState extends ConsumerState<ModelDetailsScreen> {
  bool _isDescExpanded = false;
  bool _isReleaseExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modelDetailsControllerProvider(widget.modelId));
    final controller = ref.read(modelDetailsControllerProvider(widget.modelId).notifier);
    
    final updateState = ref.watch(modelUpdateControllerProvider);
    final updateInfo = updateState.availableUpdates[widget.modelId];
    final hasBackup = updateState.backupVersions.containsKey(widget.modelId);
    final backupVersion = updateState.backupVersions[widget.modelId];
    
    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    final model = state.model;
    if (model == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileHeader(
              model: model,
              isFavorite: state.isFavorite,
              onFavoritePressed: () => controller.toggleFavorite(),
              expandedHeight: 200.0,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Core Info Title Row
                    _buildCoreTitle(model),
                    const SizedBox(height: 24),

                    // Play Store style stats grid
                    _buildStatsRow(model),
                    const SizedBox(height: 24),

                    // Action buttons (Install, Run, Delete, Progress)
                    _buildActionBar(state, controller, updateInfo, hasBackup, backupVersion),
                    const SizedBox(height: 24),

                    // Expandable Description
                    _buildDescriptionSection(model),
                    const Divider(height: 32),

                    // Technical Specifications Table
                    _buildSpecsSection(model),
                    const Divider(height: 32),

                    // Expandable Release notes & Version history
                    _buildReleaseNotes(model, updateInfo),
                    const SizedBox(height: 120), // spacer for bottom nav spacing
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreTitle(MarketplaceModel model) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rounded App Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppColors.primaryGradient,
          ),
          child: Center(
            child: Text(
              model.logo,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.name,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                model.developer,
                style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'Family: ${model.family} • Version ${model.version}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(MarketplaceModel model) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(model.rating.toStringAsFixed(1), '★ Ratings', Colors.amber),
          _buildDivider(),
          _buildStatItem(model.downloads, 'Downloads', AppColors.primary),
          _buildDivider(),
          _buildStatItem(model.parameters, 'Parameters', AppColors.secondary),
          _buildDivider(),
          _buildStatItem(model.ramRequirement, 'Min RAM', Colors.orange),
          _buildDivider(),
          _buildStatItem(model.downloadSize, 'Disk Size', AppColors.success),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.border,
    );
  }

  Widget _buildStatItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionBar(
    ModelDetailsState state,
    ModelDetailsController controller,
    ModelUpdateInfo? updateInfo,
    bool hasBackup,
    String? backupVersion,
  ) {
    final model = state.model!;

    // 1. Download progress bar indicator
    if (state.isDownloading) {
      final pct = (state.downloadProgress * 100).toInt();
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloading... $pct%',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                '${state.downloadSpeed} • ETA: ${state.downloadEta}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.downloadProgress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevated,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => controller.cancelDownload(),
                child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: PremiumButton(
                  label: 'Pause',
                  onPressed: () => controller.pauseDownload(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Checking if a download is in queue but currently paused
    final downloadsState = ref.read(downloadsControllerProvider);
    final taskIndex = downloadsState.queue.indexWhere((t) => t.id == widget.modelId);
    final task = taskIndex != -1 ? downloadsState.queue[taskIndex] : null;

    if (task != null && task.status == DownloadStatus.paused) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Download Paused', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(
                'Progress: ${((task.downloadedBytes / task.totalBytes) * 100).toInt()}%',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => controller.cancelDownload(),
                child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 36,
                width: 100,
                child: PremiumButton(
                  label: 'Resume',
                  onPressed: () => controller.resumeDownload(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 2. Installed Actions
    if (state.isInstalled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (updateInfo != null) ...[
            _buildUpdateBanner(context, updateInfo),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: 'Run Model',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    controller.runModel();
                    context.go('/chats');
                  },
                ),
              ),
              if (updateInfo != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upgrade_rounded, color: AppColors.success),
                    label: const Text('Update', style: TextStyle(color: AppColors.success)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.success),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showUpdateDialog(context, model.id),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: () => _showDeleteConfirmation(controller),
              ),
            ],
          ),
          if (hasBackup && backupVersion != null && updateInfo == null) ...[
            const SizedBox(height: 12),
            _buildRollbackRow(context, ref, model.id, backupVersion),
          ],
        ],
      );
    }

    // 3. Not installed - Show Install
    return PremiumButton(
      label: 'Install Model (${model.downloadSize})',
      icon: Icons.download_rounded,
      onPressed: () {
        final optimizerState = ref.read(deviceOptimizerControllerProvider);
        final isSafe = ref.read(deviceOptimizerControllerProvider.notifier).isModelSafe(model.ramRequirement);
        
        if (!isSafe) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text('Memory Warning', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              content: Text(
                'This model requires ${model.ramRequirement} RAM.\n\nYour device\'s safe memory allocation budget is ${optimizerState.safeMemoryAllocationGb.toStringAsFixed(1)} GB. Downloading this model may cause severe system lag, application crashes, or fail to load entirely.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('Install Anyway', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    controller.startDownload();
                  },
                ),
              ],
            ),
          );
        } else {
          controller.startDownload();
        }
      },
    );
  }

  void _showUpdateDialog(BuildContext context, String modelId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModelUpdateDialog(modelId: modelId),
    );
  }

  Widget _buildUpdateBanner(BuildContext context, ModelUpdateInfo info) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New version v${info.latestVersion} available!',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Delta update size: ${info.deltaSize ?? info.downloadSize}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRollbackRow(BuildContext context, WidgetRef ref, String modelId, String backupVersion) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rollback available (v$backupVersion)',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Restore the backup version from your device.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => ref.read(modelUpdateControllerProvider.notifier).discardBackup(modelId),
                child: const Text('Discard', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => ref.read(modelUpdateControllerProvider.notifier).rollback(modelId),
                child: const Text('Rollback', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ModelDetailsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Uninstall Model?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove the GGUF binary from your local storage and free up space.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Uninstall', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              controller.deleteModel();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(MarketplaceModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this AI Model',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Text(
            model.description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            maxLines: _isDescExpanded ? 100 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isDescExpanded ? 'Show less' : 'Read more',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Icon(
                  _isDescExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsSection(MarketplaceModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technical Specifications',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildSpecsRow('Quantization', model.quantization),
        _buildSpecsRow('Disk Download Size', model.downloadSize),
        _buildSpecsRow('Installed Size', model.installedSize),
        _buildSpecsRow('Min RAM Size', model.ramRequirement),
        _buildSpecsRow('Storage Required', model.installedSize),
        _buildSpecsRow('Languages', model.languages.join(', ')),
        _buildSpecsRow('License', model.license),
        _buildSpecsRow('Min Android OS', 'Android ${model.minimumAndroidVersion}'),
        _buildSpecsRow('SHA256 Checksum', model.checksum.substring(0, 16) + '...'),
      ],
    );
  }

  Widget _buildSpecsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes(MarketplaceModel model, ModelUpdateInfo? updateInfo) {
    final notes = updateInfo != null ? updateInfo.releaseNotes : 
        ('• Added Q${model.quantization} quantized build profiles.\n'
        '• Optimized sliding window attention patterns.\n'
        '• Extended support to: ${model.languages.join(", ")}.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s New & History',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                updateInfo != null 
                    ? 'Latest Update: v${updateInfo.latestVersion}'
                    : 'Release Date: ${model.releaseDate}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Text(
                notes,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                maxLines: _isReleaseExpanded ? 100 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() => _isReleaseExpanded = !_isReleaseExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isReleaseExpanded ? 'Show less' : 'View history',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Icon(
                  _isReleaseExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
