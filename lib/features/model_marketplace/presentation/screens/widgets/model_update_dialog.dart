import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/features/downloads/presentation/controllers/downloads_controller.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/model_update_info.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/model_update_controller.dart';

class ModelUpdateDialog extends ConsumerStatefulWidget {
  final String modelId;

  const ModelUpdateDialog({super.key, required this.modelId});

  @override
  ConsumerState<ModelUpdateDialog> createState() => _ModelUpdateDialogState();
}

class _ModelUpdateDialogState extends ConsumerState<ModelUpdateDialog> {
  bool _useDelta = true;

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(modelUpdateControllerProvider);
    final downloadsState = ref.watch(downloadsControllerProvider);

    final info = updateState.availableUpdates[widget.modelId];
    if (info == null) {
      // If no updates available, it means it completed successfully or was dismissed
      return Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 64),
              const SizedBox(height: 16),
              Text('Update Completed', style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              Text(
                'The model has been successfully updated to the latest version.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              PremiumButton(
                text: 'Dismiss',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    final isUpdatingThisModel = updateState.isUpdating && updateState.activeUpdateModelId == widget.modelId;
    final progress = downloadsState.progressMap[widget.modelId];
    final progressPercent = progress != null ? progress.downloadedBytes / progress.totalBytes : 0.0;
    
    // Check error
    if (updateState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updateState.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(modelUpdateControllerProvider.notifier).clearError();
      });
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: isUpdatingThisModel
            ? _buildProgressView(info, progressPercent, progress)
            : _buildSetupView(info),
      ),
    );
  }

  Widget _buildSetupView(ModelUpdateInfo info) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update ${info.modelName}',
                style: AppTypography.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Version Comparison Banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('Current', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(info.currentVersion, style: AppTypography.titleMedium),
                ],
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
              Column(
                children: [
                  Text('Latest', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(info.latestVersion, style: AppTypography.titleMedium.copyWith(color: AppColors.success)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('Update Method', style: AppTypography.titleSmall),
        const SizedBox(height: 8),

        // Radio-style cards for Delta vs Full Update
        if (info.isDeltaAvailable)
          _buildUpdateTypeCard(
            title: 'Delta Patch (Recommended)',
            subtitle: 'Downloads only modifications (${info.deltaSize ?? "N/A"})',
            selected: _useDelta,
            onTap: () => setState(() => _useDelta = true),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delta patch unavailable for major version changes.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        
        _buildUpdateTypeCard(
          title: 'Full Installation',
          subtitle: 'Downloads complete GGUF container (${info.downloadSize})',
          selected: !_useDelta || !info.isDeltaAvailable,
          onTap: () => setState(() => _useDelta = false),
        ),

        const SizedBox(height: 16),

        Text('System Requirements', style: AppTypography.titleSmall),
        const SizedBox(height: 8),
        
        // RAM Verification Row
        _buildRequirementRow(
          label: 'RAM: ${info.ramRequirement} Required',
          passed: info.isCompatible,
          failMessage: 'System profile requires higher memory allocation.',
        ),
        const SizedBox(height: 6),
        // Storage Verification Row
        _buildRequirementRow(
          label: 'Disk Space: Sufficient Space Available',
          passed: info.hasStorageSpace,
          failMessage: 'Insufficient storage partition for download.',
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 12),
            PremiumButton(
              text: 'Install Update',
              onPressed: (info.isCompatible && info.hasStorageSpace)
                  ? () => ref.read(modelUpdateControllerProvider.notifier).installUpdate(widget.modelId, useDelta: _useDelta)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpdateTypeCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border.withOpacity(0.6),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow({
    required String label,
    required bool passed,
    required String failMessage,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          passed ? Icons.check_circle_rounded : Icons.error_rounded,
          color: passed ? AppColors.success : AppColors.error,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                passed ? label : failMessage,
                style: AppTypography.bodyMedium.copyWith(
                  color: passed ? AppColors.textPrimary : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressView(ModelUpdateInfo info, double percent, dynamic progress) {
    final speed = progress != null ? '${progress.speedMbPerSecond.toStringAsFixed(1)} MB/s' : '0.0 MB/s';
    final remainingTime = progress != null ? _formatEta(progress.etaSeconds) : '--';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const CircularProgressIndicator(strokeWidth: 4),
        const SizedBox(height: 24),
        Text('Downloading Update...', style: AppTypography.titleMedium),
        const SizedBox(height: 8),
        Text('${info.modelName} (v${info.latestVersion})', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        // Progress Line
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: AppColors.border.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(percent * 100).toStringAsFixed(0)}%', style: AppTypography.bodyMedium),
            Text(speed, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Time Remaining:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            Text(remainingTime, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Do not close the application. Your model file will automatically install once complete.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  String _formatEta(int seconds) {
    if (seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }
}
