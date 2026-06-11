import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/search/presentation/controllers/search_controller.dart';
import 'package:localmind_ai/features/search/domain/entities/search_filters.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _voiceAnimController;
  bool _isFiltersExpanded = false;

  final List<String> _trending = [
    'Llama 3.2',
    'Coding',
    'DeepSeek R1',
    'Reasoning',
    'Low RAM',
    'Vision',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _voiceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    _voiceAnimController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final notifier = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Ambient back glow
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0xFF161233),
                  AppColors.background,
                ],
                center: Alignment(0.5, -0.6),
                radius: 1.5,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Search Header Row
                _buildSearchHeader(state, notifier),
                const SizedBox(height: 8),

                // 2. Main Search Console Body
                Expanded(
                  child: _buildSearchBody(state, notifier),
                ),
              ],
            ),
          ),

          // 3. Voice Listening Overlay
          if (state.isListening) _buildVoiceOverlay(notifier),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(SearchState state, SearchController notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: GlassContainer(
              borderRadius: 14,
              blur: 10,
              color: AppColors.surface.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) => notifier.updateQuery(val),
                      onSubmitted: (val) => notifier.submitSearch(val),
                      decoration: const InputDecoration(
                        hintText: 'Search models, developer, tags...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_queryController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _queryController.clear();
                        notifier.updateQuery('');
                      },
                      child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _voiceAnimController.repeat();
                      notifier.startVoiceListening((val) {
                        _queryController.text = val;
                        _voiceAnimController.stop();
                      });
                    },
                    child: Icon(Icons.mic_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBody(SearchState state, SearchController notifier) {
    final queryText = _queryController.text.trim();

    // Case 1: Empty input query -> show History & Trending
    if (queryText.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildTrendingSection(notifier),
          const SizedBox(height: 28),
          _buildHistorySection(state, notifier),
        ],
      );
    }

    // Case 2: Autocomplete suggestions list
    if (state.suggestions.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = state.suggestions[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted, size: 20),
            title: Text(suggestion, style: const TextStyle(color: Colors.white, fontSize: 13)),
            trailing: const Icon(Icons.north_west_rounded, color: AppColors.textMuted, size: 16),
            onTap: () {
              final cleanQuery = suggestion.startsWith('#') ? suggestion.substring(1) : suggestion;
              _queryController.text = cleanQuery;
              notifier.submitSearch(cleanQuery);
            },
          );
        },
      );
    }

    // Case 3: Running Search & Showing Results
    return Column(
      children: [
        // Collapsible Filters
        _buildFiltersPanel(state, notifier),
        
        // Results
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _buildResultsList(state),
        ),
      ],
    );
  }

  Widget _buildTrendingSection(SearchController notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trending Searches',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trending.map((term) {
            return GestureDetector(
              onTap: () {
                _queryController.text = term;
                notifier.submitSearch(term);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Text(
                  '#$term',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHistorySection(SearchState state, SearchController notifier) {
    if (state.recentSearches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () => notifier.clearHistory(),
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.recentSearches.length,
          itemBuilder: (context, index) {
            final term = state.recentSearches[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 18),
              title: Text(term, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                onPressed: () => notifier.removeHistoryItem(term),
              ),
              onTap: () {
                _queryController.text = term;
                notifier.submitSearch(term);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFiltersPanel(SearchState state, SearchController notifier) {
    final filters = state.filters;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isFiltersExpanded = !_isFiltersExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text('Advanced Search Filters', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Icon(
                    _isFiltersExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isFiltersExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 8),
                      
                      // Row 1: Category & Sorting
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownFilter(
                              label: 'Category',
                              value: filters.category,
                              items: ['All', 'Chat', 'Coding', 'Reasoning', 'Writing', 'Translation', 'Vision'],
                              onChanged: (val) => notifier.updateFilters(filters.copyWith(category: val!)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdownFilter(
                              label: 'Sort By',
                              value: filters.sortBy,
                              items: ['popularity', 'rating', 'size'],
                              onChanged: (val) => notifier.updateFilters(filters.copyWith(sortBy: val!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Parameter Size & RAM Limits
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownFilter(
                              label: 'Params Size',
                              value: filters.paramSize,
                              items: ['All', 'small', 'medium', 'large'],
                              onChanged: (val) => notifier.updateFilters(filters.copyWith(paramSize: val!)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdownFilter(
                              label: 'RAM Limits',
                              value: filters.ramFilter,
                              items: ['All', 'low', 'mid', 'high'],
                              onChanged: (val) => notifier.updateFilters(filters.copyWith(ramFilter: val!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 3: Languages
                      _buildDropdownFilter(
                        label: 'Supported Languages',
                        value: filters.language,
                        items: ['All', 'English', 'French', 'German', 'Chinese', 'Spanish', 'Multilingual'],
                        onChanged: (val) => notifier.updateFilters(filters.copyWith(language: val!)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceElevated,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: items.map((val) => DropdownMenuItem<String>(
                value: val,
                child: Text(val),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(SearchState state) {
    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No models match query', style: AppTypography.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: state.results.length + (state.isMoreLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        }

        final model = state.results[index];
        return _buildModelResultCard(model);
      },
    );
  }

  Widget _buildModelResultCard(MarketplaceModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => context.go('/marketplace/model-details/${model.id}'),
        child: GlassContainer(
          borderRadius: 20,
          blur: 15,
          color: AppColors.surface.withOpacity(0.4),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        model.logo,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(model.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('by ${model.developer} • ${model.family}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(model.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                model.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSpecPill('Params', model.parameters),
                  const SizedBox(width: 4),
                  _buildSpecPill('Quant', model.quantization),
                  const SizedBox(width: 4),
                  _buildSpecPill('Disk', model.downloadSize),
                  const Spacer(),
                  Icon(
                    model.isDownloaded ? Icons.check_circle_rounded : Icons.download_for_offline_rounded,
                    color: model.isDownloaded ? AppColors.success : AppColors.textMuted,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
      ),
    );
  }

  Widget _buildVoiceOverlay(SearchController notifier) {
    return GestureDetector(
      onTap: () => notifier.stopVoiceListening(),
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                painter: _VoiceWavePainter(_voiceAnimController),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.mic_rounded, size: 36, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Listening...',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try saying "Llama 3.2" or "Coding model"',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 48),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => notifier.stopVoiceListening(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceWavePainter extends CustomPainter {
  final Animation<double> _animation;
  _VoiceWavePainter(this._animation) : super(repaint: _animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(1.0 - _animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = 44.0 + (_animation.value * 50);

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius + 20, paint..color = paint.color.withOpacity((1.0 - _animation.value) * 0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
