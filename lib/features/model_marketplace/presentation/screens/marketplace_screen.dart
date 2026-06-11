import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_shimmer.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_query.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/marketplace_notifier.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Chat',
    'Coding',
    'Reasoning',
    'Writing',
    'Translation',
    'Vision',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(marketplaceNotifierProvider.notifier).fetchMoreModels();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('Explore Models', style: AppTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onPressed: () => _showSortFilterDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF161233), // Subtle primary ambient glow
              AppColors.background,
            ],
            center: Alignment(-0.6, -0.7),
            radius: 1.5,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 40),
            
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 16),

            // 2. Sliding Category Tabs
            _buildCategoryTabs(state),
            const SizedBox(height: 8),

            // 3. Main Paginated Model List
            Expanded(
              child: RefreshIndicator(
                backgroundColor: AppColors.surfaceElevated,
                color: AppColors.primary,
                onRefresh: () => ref.read(marketplaceNotifierProvider.notifier).fetchModels(isRefresh: true),
                child: _buildModelList(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GlassContainer(
      borderRadius: 14,
      blur: 10,
      color: AppColors.surface.withOpacity(0.4),
      borderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: TextField(
        readOnly: true,
        onTap: () => context.push('/search'),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search models...',
          hintStyle: TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(MarketplaceState state) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat.toLowerCase() == state.filters.category.toLowerCase();

          return GestureDetector(
            onTap: () => ref.read(marketplaceNotifierProvider.notifier).updateCategory(cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface.withOpacity(0.4),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModelList(MarketplaceState state) {
    if (state.isLoading && state.models.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 120, top: 10),
        itemCount: 6,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PremiumShimmer(width: double.infinity, height: 130, borderRadius: 16),
        ),
      );
    }

    if (state.models.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_off_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No Models Found', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Try checking filters or changing tags.', style: AppTypography.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 120, top: 10),
      itemCount: state.models.length + (state.isMoreLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.models.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              ),
            ),
          );
        }

        final model = state.models[index];
        return _buildModelCard(model);
      },
    );
  }

  Widget _buildModelCard(MarketplaceModel model) {
    return GestureDetector(
      onTap: () => context.go('/marketplace/model-details/${model.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassContainer(
        borderRadius: 20,
        blur: 15,
        color: AppColors.surface.withOpacity(0.5),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      model.logo,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'by ${model.developer} • ${model.family}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      model.rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              model.description,
              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Dynamic tags row
            if (model.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: model.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 0.5),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            
            Row(
              children: [
                _buildSpecPill('Params', model.parameters),
                const SizedBox(width: 6),
                _buildSpecPill('Quant', model.quantization),
                const SizedBox(width: 6),
                _buildSpecPill('RAM', model.ramRequirement),
                const SizedBox(width: 6),
                _buildSpecPill('Disk', model.downloadSize),
                const Spacer(),
                
                Row(
                  children: [
                    const Icon(Icons.download_rounded, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${model.downloads} downloads',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showSortFilterDialog(BuildContext context) {
    final state = ref.read(marketplaceNotifierProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return GlassContainer(
              borderRadius: 24,
              blur: 30,
              color: AppColors.surface.withOpacity(0.9),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sort & Filter', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
                  const SizedBox(height: 24),
                  
                  const Text('Sort by', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFilterChip(
                        label: 'Popularity',
                        isSelected: state.filters.sortBy == ModelSort.popularity,
                        onTap: () {
                          ref.read(marketplaceNotifierProvider.notifier).updateSort(ModelSort.popularity);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Rating',
                        isSelected: state.filters.sortBy == ModelSort.rating,
                        onTap: () {
                          ref.read(marketplaceNotifierProvider.notifier).updateSort(ModelSort.rating);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Size',
                        isSelected: state.filters.sortBy == ModelSort.size,
                        onTap: () {
                          ref.read(marketplaceNotifierProvider.notifier).updateSort(ModelSort.size);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('RAM Requirements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        isSelected: state.filters.ramFilter == RamFilter.all,
                        onTap: () {
                          ref.read(marketplaceNotifierProvider.notifier).updateRamFilter(RamFilter.all);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '<= 4GB',
                        isSelected: state.filters.ramFilter == RamFilter.low,
                        onTap: () {
                          ref.read(marketplaceNotifierProvider.notifier).updateRamFilter(RamFilter.low);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '4GB - 8GB',
                        isSelected: state.filters.ramFilter == RamFilter.mid,
                        onTap: () {
                          ref.read(marketplaceNotifierProvider.notifier).updateRamFilter(RamFilter.mid);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '8GB+',
                        isSelected: state.filters.ramFilter == RamFilter.high,
                        onTap: () {
                          ref.read(marketplaceNotifierProvider.notifier).updateRamFilter(RamFilter.high);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
