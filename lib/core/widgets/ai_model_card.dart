import 'package:flutter/material.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';

class AiModelCard extends StatelessWidget {
  final String title;
  final String description;
  final String size;
  final String parameterCount;
  final double? downloadProgress; // null if not downloading, 0.0 - 1.0 if downloading
  final VoidCallback onTap;
  final VoidCallback onActionPressed;
  final bool isDownloaded;

  const AiModelCard({
    super.key,
    required this.title,
    required this.description,
    required this.size,
    required this.parameterCount,
    this.downloadProgress,
    required this.onTap,
    required this.onActionPressed,
    required this.isDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = downloadProgress != null;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      borderRadius: 16.0,
      child: InkWell(
        onTap: onTap,
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
                        title,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildChip(context, parameterCount),
                          const SizedBox(width: 8),
                          _buildChip(context, size),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isDownloaded
                        ? Icons.play_arrow_rounded
                        : isDownloading
                            ? Icons.pause_rounded
                            : Icons.download_rounded,
                    color: isDownloaded ? AppColors.secondary : AppColors.textPrimary,
                  ),
                  onPressed: onActionPressed,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTypography.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isDownloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: downloadProgress,
                  backgroundColor: AppColors.surfaceElevated,
                  color: AppColors.primary,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading...',
                    style: AppTypography.labelMedium,
                  ),
                  Text(
                    '${((downloadProgress ?? 0) * 100).toInt()}%',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }
}
