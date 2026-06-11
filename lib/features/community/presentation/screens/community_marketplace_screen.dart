import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/community/domain/entities/community_model.dart';
import 'package:localmind_ai/features/community/presentation/controllers/community_controller.dart';
import 'package:localmind_ai/features/downloads/presentation/controllers/downloads_controller.dart';

class CommunityMarketplaceScreen extends ConsumerWidget {
  const CommunityMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityControllerProvider);
    final controller = ref.read(communityControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        title: Text(
          'Community Marketplace',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'curate new collection',
            icon: const Icon(Icons.playlist_add_rounded, color: Colors.cyanAccent),
            onPressed: () => _showCurateCollectionDialog(context, ref),
          ),
        ],
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
          child: RefreshIndicator(
            onRefresh: () => controller.loadAll(),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Search & Filters Bar
                      _buildSearchBar(context, state, controller),
                      const SizedBox(height: 20),

                      // Category Selector Chips
                      _buildCategoryChips(context, state, controller),
                      const SizedBox(height: 24),

                      // Trending Carousel (Horizontal Scroll)
                      _buildSectionTitle(context, 'Trending Models', Icons.trending_up_rounded),
                      const SizedBox(height: 12),
                      _buildTrendingCarousel(context, state, ref),
                      const SizedBox(height: 24),

                      // Curated Playlists/Collections
                      _buildSectionTitle(context, 'Curated Collections', Icons.folder_special_rounded),
                      const SizedBox(height: 12),
                      _buildCollectionsList(context, state),
                      const SizedBox(height: 24),

                      // Top Contributors
                      _buildSectionTitle(context, 'Featured Developers', Icons.code_rounded),
                      const SizedBox(height: 12),
                      _buildDevelopersList(context, state, controller),
                      const SizedBox(height: 24),

                      // Main Catalog Grid
                      _buildSectionTitle(context, 'Community Models', Icons.grid_view_rounded),
                      const SizedBox(height: 12),
                      _buildModelsGrid(context, state, ref),
                    ],
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
        label: Text('Upload Model', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
        onPressed: () => context.push('/community/upload'),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, CommunityState state, CommunityController controller) {
    final theme = Theme.of(context);
    return GlassContainer(
      borderRadius: 16,
      blur: 8,
      color: theme.colorScheme.surface.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (val) => controller.setSearchQuery(val),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search community models, tags, or devs...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, CommunityState state, CommunityController controller) {
    final categories = ['All', 'Chat', 'Coding', 'Reasoning', 'Writing', 'Translation', 'Vision'];
    final theme = Theme.of(context);

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = state.selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) controller.setSelectedCategory(cat);
              },
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface.withOpacity(0.3),
              labelStyle: TextStyle(color: isSelected ? Colors.white : theme.colorScheme.onSurface),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCarousel(BuildContext context, CommunityState state, WidgetRef ref) {
    final list = state.trendingModels;
    if (list.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No trending models cataloged.', style: TextStyle(color: Colors.white38))),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final model = list[index];
          final isBookmarked = state.bookmarkedModelIds.contains(model.id);

          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showModelReviewsSheet(context, model, ref),
              child: GlassContainer(
                borderRadius: 20,
                blur: 12,
                color: Colors.white.withOpacity(0.04),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            model.name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isBookmarked ? Colors.amberAccent : Colors.white60,
                            size: 20,
                          ),
                          onPressed: () => ref.read(communityControllerProvider.notifier).toggleBookmark(model.id),
                        ),
                      ],
                    ),
                    Text(
                      'by ${model.developerName}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            model.parameters,
                            style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            model.quantization,
                            style: GoogleFonts.shareTechMono(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              model.rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.download_rounded, color: Colors.white60, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${model.downloadsCount}',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _triggerDownload(context, ref, model),
                          child: Text(
                            'GET',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.cyanAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionsList(BuildContext context, CommunityState state) {
    final list = state.collections;
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('No collections created yet.', style: TextStyle(color: Colors.white38))),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final col = list[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/community/collection/${col.id}'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 10,
                color: Colors.white.withOpacity(0.03),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      col.name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${col.modelIds.length} Models • cur: ${col.ownerName}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 12),
                        const SizedBox(width: 4),
                        Text('${col.likesCount} likes', style: const TextStyle(color: Colors.white60, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDevelopersList(BuildContext context, CommunityState state, CommunityController controller) {
    final list = state.developers;
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final dev = list[index];
          final uid = controller._currentUserId;
          final isFollowing = dev.followers.contains(uid);

          return Container(
            width: 240,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/community/developer/${dev.id}'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 10,
                color: Colors.white.withOpacity(0.03),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(dev.avatarUrl),
                      backgroundColor: Colors.white10,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dev.name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${dev.modelsCount} models • ${dev.followersCount} followers',
                            style: const TextStyle(color: Colors.white54, fontSize: 9),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.white12 : Colors.white,
                              foregroundColor: isFollowing ? Colors.white : Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (isFollowing) {
                                controller.unfollowDeveloper(dev.id);
                              } else {
                                controller.followDeveloper(dev.id);
                              }
                            },
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModelsGrid(BuildContext context, CommunityState state, WidgetRef ref) {
    final list = state.models;
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No models match filter criteria.', style: TextStyle(color: Colors.white38))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final model = list[index];
        final isBookmarked = state.bookmarkedModelIds.contains(model.id);

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showModelReviewsSheet(context, model, ref),
          child: GlassContainer(
            borderRadius: 16,
            blur: 10,
            color: Colors.white.withOpacity(0.03),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        model.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(communityControllerProvider.notifier).toggleBookmark(model.id),
                      child: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isBookmarked ? Colors.amberAccent : Colors.white60,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  'by ${model.developerName}',
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      model.rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.download_rounded, color: Colors.white38, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${model.downloadsCount}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      model.parameters,
                      style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _triggerDownload(context, ref, model),
                      child: const Icon(Icons.download_rounded, size: 14, color: Colors.white70),
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

  void _triggerDownload(BuildContext context, WidgetRef ref, CommunityModel model) {
    // We hook the download URL straight to the existing downloads queue controller.
    ref.read(downloadsControllerProvider.notifier).startNewDownload(
          modelId: model.id,
          modelName: model.name,
          url: model.downloadUrl,
          totalBytes: _parseSizeToBytes(model.downloadSize),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${model.name} to Download Queue.'),
        backgroundColor: Colors.cyan,
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

  void _showModelReviewsSheet(BuildContext context, CommunityModel model, WidgetRef ref) {
    ref.read(communityControllerProvider.notifier).loadReviews(model.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final commentController = TextEditingController();
        double userRating = 5.0;

        return StatefulBuilder(
          builder: (context, setState) {
            final state = ref.watch(communityControllerProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F0E23),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(model.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                      Text(model.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      // Rating review submit form
                      Text('Write a Review', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < userRating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amberAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                userRating = index + 1.0;
                              });
                            },
                          );
                        }),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'Share your thoughts on this model...',
                                hintStyle: TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.cyanAccent),
                            onPressed: () async {
                              if (commentController.text.isNotEmpty) {
                                final success = await ref.read(communityControllerProvider.notifier).submitReview(
                                      model.id,
                                      userRating,
                                      commentController.text,
                                    );
                                if (success) {
                                  commentController.clear();
                                  userRating = 5.0;
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: state.activeReviews.length,
                          itemBuilder: (context, index) {
                            final rev = state.activeReviews[index];
                            final isLiked = rev.likedUsers.contains(ref.read(communityControllerProvider.notifier)._currentUserId);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  Text(rev.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: List.generate(5, (starIdx) {
                                      return Icon(
                                        starIdx < rev.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 10,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              subtitle: Text(rev.comment, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              trailing: TextButton.icon(
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                icon: Icon(
                                  isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                  size: 12,
                                  color: isLiked ? Colors.cyanAccent : Colors.white38,
                                ),
                                label: Text('${rev.likesCount}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                onPressed: () => ref.read(communityControllerProvider.notifier).likeReview(model.id, rev.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCurateCollectionDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final state = ref.read(communityControllerProvider);
    final selectedModels = <String>{};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F0E23),
              title: Text('Curate Model Collection', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Collection Name', hintStyle: TextStyle(color: Colors.white24)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Description', hintStyle: TextStyle(color: Colors.white24)),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Select Models:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    ...state.models.map((m) {
                      final isSelected = selectedModels.contains(m.id);
                      return CheckboxListTile(
                        title: Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selectedModels.add(m.id);
                            } else {
                              selectedModels.remove(m.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && selectedModels.isNotEmpty) {
                      await ref.read(communityControllerProvider.notifier).createCollection(
                            nameController.text,
                            descController.text,
                            selectedModels.toList(),
                            true,
                          );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Curate', style: TextStyle(color: Colors.cyanAccent)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
