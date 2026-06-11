import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/search/domain/entities/search_filters.dart';
import 'package:localmind_ai/features/search/domain/repositories/search_repository.dart';
import 'package:localmind_ai/features/search/data/repositories/search_repository_impl.dart';

class SearchState {
  final List<MarketplaceModel> results;
  final List<String> suggestions;
  final List<String> recentSearches;
  final SearchFilters filters;
  final int currentPage;
  final bool isLoading;
  final bool isMoreLoading;
  final bool hasMore;
  final bool isListening;
  final String? error;

  const SearchState({
    this.results = const [],
    this.suggestions = const [],
    this.recentSearches = const [],
    this.filters = const SearchFilters(),
    this.currentPage = 1,
    this.isLoading = false,
    this.isMoreLoading = false,
    this.hasMore = true,
    this.isListening = false,
    this.error,
  });

  SearchState copyWith({
    List<MarketplaceModel>? results,
    List<String>? suggestions,
    List<String>? recentSearches,
    SearchFilters? filters,
    int? currentPage,
    bool? isLoading,
    bool? isMoreLoading,
    bool? hasMore,
    bool? isListening,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      recentSearches: recentSearches ?? this.recentSearches,
      filters: filters ?? this.filters,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      hasMore: hasMore ?? this.hasMore,
      isListening: isListening ?? this.isListening,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  static const int _limit = 10;
  static const String settingsBoxName = 'settingsBox';
  static const String historyKey = 'recentSearches';

  SearchController(this._repository) : super(const SearchState()) {
    _loadHistory();
  }

  void _loadHistory() async {
    final box = Hive.isBoxOpen(settingsBoxName)
        ? Hive.box(settingsBoxName)
        : await Hive.openBox(settingsBoxName);
    
    final history = box.get(historyKey, defaultValue: <dynamic>[]) as List;
    state = state.copyWith(recentSearches: history.map((e) => e.toString()).toList());
  }

  Future<void> executeSearch({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isLoading: true, results: [], currentPage: 1, hasMore: true, clearError: true);
    } else {
      if (state.isLoading || !state.hasMore) return;
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final matches = await _repository.searchModels(
        page: state.currentPage,
        limit: _limit,
        filters: state.filters,
      );

      state = state.copyWith(
        isLoading: false,
        results: isRefresh ? matches : [...state.results, ...matches],
        hasMore: matches.length == _limit,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isMoreLoading || !state.hasMore) return;
    state = state.copyWith(isMoreLoading: true, clearError: true);

    try {
      final matches = await _repository.searchModels(
        page: state.currentPage,
        limit: _limit,
        filters: state.filters,
      );

      state = state.copyWith(
        isMoreLoading: false,
        results: [...state.results, ...matches],
        hasMore: matches.length == _limit,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isMoreLoading: false, error: e.toString());
    }
  }

  // Update query & generate dynamic suggestions
  void updateQuery(String query) async {
    state = state.copyWith(filters: state.filters.copyWith(query: query));
    
    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }

    // Generate dynamic autocomplete suggestions from Hive
    try {
      final box = Hive.isBoxOpen('modelsBox') ? Hive.box('modelsBox') : await Hive.openBox('modelsBox');
      final queryLower = query.toLowerCase();
      final List<String> matches = [];

      for (final value in box.values) {
        final name = (value['name'] as String?) ?? '';
        final developer = (value['developer'] as String?) ?? '';
        final tags = (value['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];

        if (name.toLowerCase().contains(queryLower) && !matches.contains(name)) {
          matches.add(name);
        } else if (developer.toLowerCase().contains(queryLower) && !matches.contains(developer)) {
          matches.add(developer);
        } else {
          for (final tag in tags) {
            if (tag.toLowerCase().contains(queryLower) && !matches.contains('#$tag')) {
              matches.add('#$tag');
            }
          }
        }
        if (matches.length >= 5) break;
      }
      state = state.copyWith(suggestions: matches);
    } catch (_) {
      state = state.copyWith(suggestions: []);
    }
  }

  // Submit search and update history
  void submitSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Save to history list
    final history = [...state.recentSearches];
    history.remove(trimmed); // remove duplicates to push to top
    final updatedHistory = [trimmed, ...history].sublist(0, updatedHistoryLength(history.length + 1));
    
    final box = Hive.isBoxOpen(settingsBoxName) ? Hive.box(settingsBoxName) : await Hive.openBox(settingsBoxName);
    await box.put(historyKey, updatedHistory);

    state = state.copyWith(
      recentSearches: updatedHistory,
      suggestions: [],
      filters: state.filters.copyWith(query: trimmed),
    );

    executeSearch(isRefresh: true);
  }

  int updatedHistoryLength(int length) => length > 10 ? 10 : length;

  void removeHistoryItem(String item) async {
    final history = [...state.recentSearches]..remove(item);
    final box = Hive.isBoxOpen(settingsBoxName) ? Hive.box(settingsBoxName) : await Hive.openBox(settingsBoxName);
    await box.put(historyKey, history);
    state = state.copyWith(recentSearches: history);
  }

  void clearHistory() async {
    final box = Hive.isBoxOpen(settingsBoxName) ? Hive.box(settingsBoxName) : await Hive.openBox(settingsBoxName);
    await box.put(historyKey, <String>[]);
    state = state.copyWith(recentSearches: []);
  }

  // Filters updates
  void updateFilters(SearchFilters nextFilters) {
    state = state.copyWith(filters: nextFilters);
    executeSearch(isRefresh: true);
  }

  // Voice Search simulation
  void startVoiceListening(Function(String) onResult) {
    state = state.copyWith(isListening: true);
    
    Timer(const Duration(seconds: 3), () {
      state = state.copyWith(isListening: false);
      // Simulate listening and picking a trending term
      const simulatedQueries = ['DeepSeek R1', 'Llama 3.2', 'Coding assistant', 'Gemma 2'];
      final picked = (simulatedQueries..shuffle()).first;
      onResult(picked);
      submitSearch(picked);
    });
  }

  void stopVoiceListening() {
    state = state.copyWith(isListening: false);
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl();
});

final searchControllerProvider = StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController(ref.watch(searchRepositoryProvider));
});
