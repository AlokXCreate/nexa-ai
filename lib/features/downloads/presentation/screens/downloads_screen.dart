import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';
import 'package:localmind_ai/features/downloads/presentation/controllers/downloads_controller.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadsControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('Downloads Manager', style: AppTypography.titleMedium),
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
            : state.queue.isEmpty
                ? _buildEmptyState()
                : _buildQueueList(context, ref, state),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.download_for_offline_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No active downloads', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text('Your model download list is currently empty.', style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildQueueList(BuildContext context, WidgetRef ref, DownloadsState state) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: kToolbarHeight + 40, bottom: 120, left: 16, right: 16),
      itemCount: state.queue.length,
      itemBuilder: (context, index) {
        final task = state.queue[index];
        final progress = state.progressMap[task.id];

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.modelName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusTag(task.status),
                        ],
                      ),
                    ),
                    _buildActions(ref, task),
                  ],
                ),
                const SizedBox(height: 16),

                if (task.status == DownloadStatus.downloading && progress != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.percentage / 100.0,
                      backgroundColor: AppColors.surfaceElevated,
                      color: AppColors.primary,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(progress.sizeFractionString, style: AppTypography.labelMedium),
                      Text(progress.speedString, style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${progress.percentage.toInt()}% completed', style: AppTypography.labelMedium),
                      Text(progress.etaString, style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
                    ],
                  ),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.totalBytes > 0 ? task.downloadedBytes / task.totalBytes : 0.0,
                      backgroundColor: AppColors.surfaceElevated,
                      color: task.status == DownloadStatus.completed ? AppColors.success : AppColors.textMuted,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(task.downloadedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB / ${(task.totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
                        style: AppTypography.labelMedium,
                      ),
                      if (task.status == DownloadStatus.failed)
                        Text(task.errorMessage ?? 'Download error', style: const TextStyle(color: AppColors.error, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTag(DownloadStatus status) {
    Color color = AppColors.textMuted;
    String label = 'Pending';

    switch (status) {
      case DownloadStatus.pending:
        color = AppColors.textMuted;
        label = 'Pending';
        break;
      case DownloadStatus.downloading:
        color = AppColors.primary;
        label = 'Downloading';
        break;
      case DownloadStatus.paused:
        color = AppColors.warning;
        label = 'Paused';
        break;
      case DownloadStatus.completed:
        color = AppColors.success;
        label = 'Completed';
        break;
      case DownloadStatus.failed:
        color = AppColors.error;
        label = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActions(WidgetRef ref, DownloadTaskModel task) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.status == DownloadStatus.downloading)
          IconButton(
            icon: const Icon(Icons.pause_rounded, color: Colors.white),
            onPressed: () => ref.read(downloadsControllerProvider.notifier).pauseDownload(task.id),
          )
        else if (task.status == DownloadStatus.paused || task.status == DownloadStatus.pending)
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            onPressed: () => ref.read(downloadsControllerProvider.notifier).resumeDownload(task.id),
          )
        else if (task.status == DownloadStatus.failed)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.read(downloadsControllerProvider.notifier).retryDownload(task.id),
          ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
          onPressed: () => ref.read(downloadsControllerProvider.notifier).cancelDownload(task.id),
        ),
      ],
    );
  }
}
