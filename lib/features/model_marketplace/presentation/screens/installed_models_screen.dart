import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/installed_model.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/core/widgets/premium_dialog.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/model_update_info.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/model_update_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/screens/widgets/model_update_dialog.dart';

class InstalledModelsScreen extends ConsumerWidget {
  const InstalledModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(installedModelsControllerProvider);
    final updateState = ref.watch(modelUpdateControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('Storage & Installed Models', style: AppTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF161233), // Indigo aura
              AppColors.background,
            ],
            center: Alignment(0, -0.6),
            radius: 1.5,
          ),
        ),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.only(top: kToolbarHeight + 40, bottom: 40, left: 16, right: 16),
                children: [
                  if (state.storageMetrics != null) ...[
                    _buildStorageDashboard(context, state),
                    const SizedBox(height: 24),
                  ],

                  if (updateState.availableUpdates.isNotEmpty) ...[
                    _buildUpdatesListSection(context, ref, updateState.availableUpdates.values.toList()),
                    const SizedBox(height: 24),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Installed Models', style: AppTypography.titleMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
                        ),
                        child: Text(
                          '${state.installedModels.length} active',
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (state.installedModels.isEmpty)
                    _buildEmptyState()
                  else
                    ...state.installedModels.map((model) => _buildInstalledModelCard(context, ref, model)),
                ],
              ),
      ),
    );
  }

  Widget _buildStorageDashboard(BuildContext context, InstalledModelsState state) {
    final metrics = state.storageMetrics!;
    final totalUsed = metrics.usedSpaceGb.toStringAsFixed(1);
    final totalSize = metrics.totalSpaceGb.toStringAsFixed(0);
    final freeSpace = metrics.freeSpaceGb.toStringAsFixed(1);
    final pct = metrics.usedPercentage / 100.0;

    return GlassContainer(
      borderRadius: 24,
      blur: 20,
      color: AppColors.surface.withOpacity(0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Local Storage Usage', style: AppTypography.titleMedium.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('$totalUsed GB of $totalSize GB used', style: AppTypography.labelMedium),
                ],
              ),
              const Icon(Icons.storage_rounded, color: AppColors.secondary, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStorageStat('Free Disk Space', '$freeSpace GB', AppColors.success),
              _buildStorageStat('Installed Models', '${state.installedModels.fold<double>(0.0, (s, m) => s + m.sizeInGb).toStringAsFixed(1)} GB', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStat(String title, String value, Color indicatorColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: indicatorColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No models installed', style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildInstalledModelCard(BuildContext context, WidgetRef ref, InstalledModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: GlassContainer(
        borderRadius: 20,
        blur: 15,
        color: AppColors.surface.withOpacity(0.5),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.bolt_rounded, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.localName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('quantized v${model.version} • by ${model.developer}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                _buildActionMenu(context, ref, model),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildModelStat('Disk Space', model.sizeString),
                _buildModelStat('Min RAM', model.ramRequirement),
                _buildModelStat('Last Used', _formatLastUsed(model.lastUsed)),
              ],
            ),
            const SizedBox(height: 16),

            PremiumButton(
              label: 'Run Model',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                ref.read(installedModelsControllerProvider.notifier).runModel(model.id);
                context.go('/chats');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStat(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _formatLastUsed(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildActionMenu(BuildContext context, WidgetRef ref, InstalledModel model) {
    final updateState = ref.read(modelUpdateControllerProvider);
    final hasUpdate = updateState.availableUpdates.containsKey(model.id);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      backgroundColor: AppColors.surfaceElevated,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'rename') {
          _showRenameDialog(context, ref, model);
        } else if (value == 'delete') {
          _showDeleteDialog(context, ref, model);
        } else if (value == 'details') {
          _showDetailsDialog(context, model);
        } else if (value == 'update') {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => ModelUpdateDialog(modelId: model.id),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(children: [Icon(Icons.info_outline, size: 18), SizedBox(width: 8), Text('Details')]),
        ),
        if (hasUpdate)
          const PopupMenuItem(
            value: 'update',
            child: Row(children: [Icon(Icons.upgrade_rounded, color: AppColors.success, size: 18), SizedBox(width: 8), Text('Update Model', style: TextStyle(color: AppColors.success))]),
          ),
        const PopupMenuItem(
          value: 'rename',
          child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Rename')]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, InstalledModel model) {
    final controller = TextEditingController(text: model.localName);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: 24,
            blur: 20,
            color: AppColors.surface,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rename Model', style: AppTypography.titleMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Local custom name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      child: const Text('Rename'),
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          ref.read(installedModelsControllerProvider.notifier).renameModel(model.id, controller.text.trim());
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, InstalledModel model) {
    PremiumDialog.show(
      context: context,
      title: 'Delete Model?',
      content: 'You are about to delete ${model.localName} from disk. This will free up ${model.sizeString} of space. This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onCancel: () {},
      onConfirm: () {
        ref.read(installedModelsControllerProvider.notifier).deleteModel(model.id);
      },
    );
  }

  void _showDetailsDialog(BuildContext context, InstalledModel model) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: 24,
            blur: 20,
            color: AppColors.surface,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Model Details', style: AppTypography.titleMedium),
                const SizedBox(height: 16),
                _buildDetailRow('Name', model.localName),
                _buildDetailRow('Developer', model.developer),
                _buildDetailRow('Version', model.version),
                _buildDetailRow('RAM requirement', model.ramRequirement),
                _buildDetailRow('File Size', model.sizeString),
                _buildDetailRow('Storage Path', model.filePath),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesListSection(BuildContext context, WidgetRef ref, List<ModelUpdateInfo> updates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pending Updates', style: AppTypography.titleMedium.copyWith(color: AppColors.success)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.3), width: 0.5),
              ),
              child: Text(
                '${updates.length} available',
                style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...updates.map((update) => _buildUpdateInfoCard(context, ref, update)),
      ],
    );
  }

  Widget _buildUpdateInfoCard(BuildContext context, WidgetRef ref, ModelUpdateInfo update) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: GlassContainer(
        borderRadius: 20,
        blur: 15,
        color: AppColors.success.withOpacity(0.05),
        borderColor: AppColors.success.withOpacity(0.3),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.upgrade_rounded, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.modelName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v${update.currentVersion} ➔ v${update.latestVersion}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.success),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => ModelUpdateDialog(modelId: update.modelId),
                );
              },
              child: const Text('Update', style: TextStyle(color: AppColors.success, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
