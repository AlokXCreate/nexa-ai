import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/community/domain/entities/developer_profile.dart';
import 'package:localmind_ai/features/community/presentation/controllers/community_controller.dart';
import 'package:localmind_ai/features/downloads/presentation/controllers/downloads_controller.dart';

class DeveloperDetailsScreen extends ConsumerWidget {
  final String developerId;

  const DeveloperDetailsScreen({super.key, required this.developerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityControllerProvider);
    final controller = ref.read(communityControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final index = state.developers.indexWhere((d) => d.id == developerId);
    if (index == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Developer Details')),
        body: const Center(child: Text('Developer profile not found.', style: TextStyle(color: Colors.white))),
      );
    }

    final dev = state.developers[index];
    final modelsByDev = state.models.where((m) => m.developerId == developerId).toList();
    final uid = controller._currentUserId;
    final isFollowing = dev.followers.contains(uid);

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
        title: Text('Developer Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: NetworkImage(dev.avatarUrl),
                      backgroundColor: Colors.white10,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dev.name,
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dev.bio,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatTile('Models', '${dev.modelsCount}'),
                        _buildStatTile('Followers', '${dev.followersCount}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.white10 : Colors.white,
                          foregroundColor: isFollowing ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (isFollowing) {
                            controller.unfollowDeveloper(dev.id);
                          } else {
                            controller.followDeveloper(dev.id);
                          }
                        },
                        child: Text(
                          isFollowing ? 'Following' : 'Follow Developer',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Models by ${dev.name}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 12),
              if (modelsByDev.isEmpty)
                const Center(child: Text('No models uploaded by this developer.', style: TextStyle(color: Colors.white38)))
              else
                ...modelsByDev.map((model) {
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

  Widget _buildStatTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.shareTechMono(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
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
