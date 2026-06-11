import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_shimmer.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/recommendations/presentation/controllers/recommendations_controller.dart';
import 'package:localmind_ai/features/recommendations/domain/entities/recommendation_data.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/plugins/presentation/controllers/plugins_controller.dart';
import 'package:localmind_ai/features/plugins/presentation/widgets/plugin_dashboard_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final recState = ref.watch(recommendationsControllerProvider);
    final installedState = ref.watch(installedModelsControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final pluginsState = ref.watch(pluginsControllerProvider);
    final enabledWidgets = pluginsState.plugins
        .where((p) => p.isInstalled && p.isEnabled && p.category == 'Widgets')
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('LocalMind AI', style: AppTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => context.push('/search'),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              primaryColor.withOpacity(0.08),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            center: const Alignment(0.6, -0.7),
            radius: 1.5,
          ),
        ),
        child: RefreshIndicator(
          backgroundColor: AppColors.surfaceElevated,
          color: primaryColor,
          onRefresh: () async {
            await ref.read(recommendationsControllerProvider.notifier).recalculateRecommendations();
            await ref.read(installedModelsControllerProvider.notifier).fetchInstalledModels();
          },
          child: ListView(
            padding: const EdgeInsets.only(
              top: kToolbarHeight + 40,
              bottom: 120, // Spacing for bottom navigation
              left: 16,
              right: 16,
            ),
            children: [
              // 1. Welcome Header
              Text(
                _getGreeting(),
                style: AppTypography.labelMedium.copyWith(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Creative Intellect',
                style: AppTypography.titleLarge.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 20),

              // 2. Clickable Search Bar
              _buildSearchBar(),
              const SizedBox(height: 24),

              // Dynamic Plugin Widgets
              if (enabledWidgets.isNotEmpty) ...[
                ...enabledWidgets.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: p.id == 'pomodoro_widget'
                          ? const PomodoroTimerWidget()
                          : const TaskMatrixWidget(),
                    )),
              ],

              // 3. Main Recommendations Section Loader
              if (recState.isLoading)
                _buildShimmerSection()
              else if (recState.error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Error loading recommendations: ${recState.error}', style: const TextStyle(color: Colors.redAccent)),
                  ),
                )
              else
                ..._buildRecommendationLists(recState.data),

              const SizedBox(height: 24),

              // 4. Installed Models List
              _buildSectionHeader('Installed Models', () => context.push('/installed-models')),
              const SizedBox(height: 12),
              _buildInstalledList(installedState),
            ],
          ),
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
          hintText: 'Search models, parameters, tags...',
          hintStyle: TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  List<Widget> _buildRecommendationLists(RecommendationData data) {
    return [
      if (data.recommendedForYou.isNotEmpty) ...[
        _buildSectionHeader('Recommended for You', () => context.push('/marketplace')),
        const SizedBox(height: 12),
        _buildModelHorizontalList(data.recommendedForYou),
        const SizedBox(height: 24),
      ],
      if (data.bestForDevice.isNotEmpty) ...[
        _buildSectionHeader('Best for Your Device', () => context.push('/marketplace')),
        const SizedBox(height: 12),
        _buildModelHorizontalList(data.bestForDevice),
        const SizedBox(height: 24),
      ],
      if (data.trending.isNotEmpty) ...[
        _buildSectionHeader('Trending Models', () => context.push('/marketplace')),
        const SizedBox(height: 12),
        _buildModelHorizontalList(data.trending),
        const SizedBox(height: 24),
      ],
      if (data.newReleases.isNotEmpty) ...[
        _buildSectionHeader('New Releases', () => context.push('/marketplace')),
        const SizedBox(height: 12),
        _buildModelHorizontalList(data.newReleases),
        const SizedBox(height: 24),
      ],
      if (data.popularCoding.isNotEmpty) ...[
        _buildSectionHeader('Popular Coding Models', () => context.push('/marketplace')),
        const SizedBox(height: 12),
        _buildModelHorizontalList(data.popularCoding),
        const SizedBox(height: 24),
      ],
      if (data.popularChat.isNotEmpty) ...[
        _buildSectionHeader('Popular Chat Models', () => context.push('/marketplace')),
        const SizedBox(height: 12),
        _buildModelHorizontalList(data.popularChat),
      ],
    ];
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 16)),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('See all', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildModelHorizontalList(List<MarketplaceModel> models) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];
          return _buildModelSliderCard(model);
        },
      ),
    );
  }

  Widget _buildModelSliderCard(MarketplaceModel model) {
    return GestureDetector(
      onTap: () => context.push('/marketplace/model-details/${model.id}'),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 14),
        child: GlassContainer(
          borderRadius: 20,
          blur: 15,
          color: AppColors.surface.withOpacity(0.4),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
                    ),
                    child: Text(
                      model.category,
                      style: const TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'by ${model.developer} • ${model.family}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                model.description,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Params: ${model.parameters}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RAM: ${model.ramRequirement}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        model.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstalledList(InstalledModelsState state) {
    if (state.installedModels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No local models installed.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
    }

    // Render up to 3 installed models on the home page for a clean dashboard look
    final list = state.installedModels.sublist(0, state.installedModels.length > 3 ? 3 : state.installedModels.length);

    return Column(
      children: list.map((model) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            tileColor: AppColors.surfaceElevated.withOpacity(0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.bolt_rounded, color: AppColors.secondary, size: 20),
            ),
            title: Text(model.localName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Installed size: ${model.sizeString} • RAM: ${model.ramRequirement}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: () => context.push('/installed-models'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShimmerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: PremiumShimmer(width: 150, height: 18, borderRadius: 4),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(right: 14.0),
              child: PremiumShimmer(width: 260, height: 160, borderRadius: 20),
            ),
          ),
        ),
      ],
    );
  }
}
