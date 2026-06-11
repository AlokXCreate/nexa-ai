import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/community/domain/entities/model_collection.dart';
import 'package:localmind_ai/features/community/presentation/controllers/community_controller.dart';
import 'package:localmind_ai/features/downloads/presentation/controllers/downloads_controller.dart';

class CollectionDetailsScreen extends ConsumerWidget {
  final String collectionId;

  const CollectionDetailsScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final index = state.collections.indexWhere((c) => c.id == collectionId);
    if (index == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collection details')),
        body: const Center(child: Text('Collection not found', style: TextStyle(color: Colors.white))),
      );
    }

    final collection = state.collections[index];
    final modelsInCol = state.models.where((m) => collection.modelIds.contains(m.id)).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3),
            ),
          ),
        ),
        title: Text('Curated Collection', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF070416),
                    const Color(0xFF0F0726),
                    const Color(0xFF020105),
                  ]
                : [
                    const Color(0xFFF0F2FA),
                    const Color(0xFFF5F6FC),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                borderRadius: 24,
                blur: 10,
                color: Colors.white.withOpacity(0.04),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Curated by ${collection.ownerName}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      collection.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${collection.likesCount} curations liked this',
                          style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 14, color: Colors.white70),
                          label: const Text('Share Collection', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Collection sharing link copied to clipboard!'), backgroundColor: Colors.cyan),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Models in this collection (${modelsInCol.length})',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  if (modelsInCol.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.download_for_offline_outlined, size: 16, color: Colors.cyanAccent),
                      label: const Text('Get All Models', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        for (final m in modelsInCol) {
                          ref.read(downloadsControllerProvider.notifier).startNewDownload(
                                modelId: m.id,
                                modelName: m.name,
                                url: m.downloadUrl,
                                totalBytes: _parseSizeToBytes(m.downloadSize),
                              );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('All ${modelsInCol.length} models added to Download Queue.'), backgroundColor: Colors.cyan),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (modelsInCol.isEmpty)
                const Center(child: Text('No models cataloged in this collection.', style: TextStyle(color: Colors.white38)))
              else
                ...modelsInCol.map((model) {
                  final isBookmarked = state.bookmarkedModelIds.contains(model.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white.withOpacity(0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(model.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Params: ${model.parameters} • Quant: ${model.quantization}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(model.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              const SizedBox(width: 8),
                              const Icon(Icons.download_rounded, color: Colors.white38, size: 12),
                              const SizedBox(width: 2),
                              Text('${model.downloadsCount}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: isBookmarked ? Colors.amberAccent : Colors.white60,
                            ),
                            onPressed: () => ref.read(communityControllerProvider.notifier).toggleBookmark(model.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_rounded, color: Colors.cyanAccent),
                            onPressed: () {
                              ref.read(downloadsControllerProvider.notifier).startNewDownload(
                                    modelId: model.id,
                                    modelName: model.name,
                                    url: model.downloadUrl,
                                    totalBytes: _parseSizeToBytes(model.downloadSize),
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added ${model.name} to Download Queue.'), backgroundColor: Colors.cyan),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  int _parseSizeToBytes(String sizeStr) {
    final clean = sizeStr.replaceAll(RegExp(r'[^\d\.]'), '');
    final value = double.tryParse(clean) ?? 1.0;
    if (sizeStr.contains('GB')) {
      return (value * 1024 * 1024 * 1024).toInt();
    }
    return (value * 1024 * 1024).toInt();
  }
}
