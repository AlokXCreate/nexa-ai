import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/model_marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_query.dart';
import 'package:localmind_ai/features/model_marketplace/domain/repositories/marketplace_repository.dart';

class MarketplaceState {
  final List<MarketplaceModel> models;
  final MarketplaceFilters filters;
  final int currentPage;
  final bool isLoading;
  final bool isMoreLoading;
  final bool hasMore;
  final String? error;

  const MarketplaceState({
    this.models = const [],
    this.filters = const MarketplaceFilters(),
    this.currentPage = 1,
    this.isLoading = false,
    this.isMoreLoading = false,
    this.hasMore = true,
    this.error,
  });

  MarketplaceState copyWith({
    List<MarketplaceModel>? models,
    MarketplaceFilters? filters,
    int? currentPage,
    bool? isLoading,
    bool? isMoreLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return MarketplaceState(
      models: models ?? this.models,
      filters: filters ?? this.filters,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final MarketplaceRepository _repository;
  static const int _limit = 10;

  MarketplaceNotifier(this._repository) : super(const MarketplaceState()) {
    fetchModels();
  }

  Future<void> fetchModels({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isLoading: true, models: [], currentPage: 1, hasMore: true, clearError: true);
    } else {
      if (state.isLoading || !state.hasMore) return;
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final newModels = await _repository.getModels(
        page: state.currentPage,
        limit: _limit,
        filters: state.filters,
      );

      state = state.copyWith(
        isLoading: false,
        models: isRefresh ? newModels : [...state.models, ...newModels],
        hasMore: newModels.length == _limit,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMoreModels() async {
    if (state.isLoading || state.isMoreLoading || !state.hasMore) return;
    state = state.copyWith(isMoreLoading: true, clearError: true);

    try {
      final newModels = await _repository.getModels(
        page: state.currentPage,
        limit: _limit,
        filters: state.filters,
      );

      state = state.copyWith(
        isMoreLoading: false,
        models: [...state.models, ...newModels],
        hasMore: newModels.length == _limit,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isMoreLoading: false, error: e.toString());
    }
  }

  void updateCategory(String category) {
    if (state.filters.category == category) return;
    state = state.copyWith(filters: state.filters.copyWith(category: category));
    fetchModels(isRefresh: true);
  }

  void updateSearch(String query) {
    state = state.copyWith(filters: state.filters.copyWith(searchQuery: query));
    fetchModels(isRefresh: true);
  }

  void updateSort(ModelSort sort) {
    state = state.copyWith(filters: state.filters.copyWith(sortBy: sort));
    fetchModels(isRefresh: true);
  }

  void updateRamFilter(RamFilter ram) {
    state = state.copyWith(filters: state.filters.copyWith(ramFilter: ram));
    fetchModels(isRefresh: true);
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepositoryImpl();
});

final marketplaceNotifierProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier(ref.watch(marketplaceRepositoryProvider));
});
