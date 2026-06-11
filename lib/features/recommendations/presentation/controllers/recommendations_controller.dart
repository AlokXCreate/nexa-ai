import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/recommendations/domain/entities/recommendation_data.dart';
import 'package:localmind_ai/features/recommendations/domain/repositories/recommendations_repository.dart';
import 'package:localmind_ai/features/recommendations/data/repositories/recommendations_repository_impl.dart';
import 'package:localmind_ai/features/recommendations/data/services/recommendation_service.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/downloads/presentation/controllers/downloads_controller.dart';

class RecommendationsState {
  final RecommendationData data;
  final bool isLoading;
  final String? error;

  const RecommendationsState({
    required this.data,
    this.isLoading = false,
    this.error,
  });

  RecommendationsState copyWith({
    RecommendationData? data,
    bool? isLoading,
    String? error,
  }) {
    return RecommendationsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RecommendationsController extends StateNotifier<RecommendationsState> {
  final RecommendationsRepository _repository;
  final RecommendationService _service = RecommendationService();
  final Ref _ref;

  static const String settingsBoxName = 'settingsBox';

  RecommendationsController(this._repository, this._ref)
      : super(RecommendationsState(data: RecommendationData.empty())) {
    recalculateRecommendations();
  }

  Future<void> recalculateRecommendations() async {
    state = state.copyWith(isLoading: true);
    try {
      final allModels = await _repository.getAllCatalogModels();
      
      // Read other providers state
      final installedState = _ref.read(installedModelsControllerProvider);
      final downloadsState = _ref.read(downloadsControllerProvider);

      final settingsBox = Hive.isBoxOpen(settingsBoxName)
          ? Hive.box(settingsBoxName)
          : await Hive.openBox(settingsBoxName);

      final recentSearches = List<String>.from(
        settingsBox.get('recentSearches', defaultValue: <dynamic>[]) as List
      );

      final favorites = List<String>.from(
        settingsBox.get('favorites', defaultValue: <dynamic>[]) as List
      );

      final double freeStorage = installedState.storageMetrics?.freeSpaceGb ?? 180.0;
      const double ramLimit = 8.0; // Assume standard mobile RAM profile

      final recommendedData = await _service.generateRecommendations(
        allModels: allModels,
        installedModels: installedState.installedModels,
        recentDownloads: downloadsState.queue,
        recentSearches: recentSearches,
        favorites: favorites,
        deviceRamGb: ramLimit,
        deviceFreeStorageGb: freeStorage,
      );

      state = RecommendationsState(data: recommendedData, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final recommendationsRepositoryProvider = Provider<RecommendationsRepository>((ref) {
  return RecommendationsRepositoryImpl();
});

final recommendationsControllerProvider =
    StateNotifierProvider<RecommendationsController, RecommendationsState>((ref) {
  final repo = ref.watch(recommendationsRepositoryProvider);
  final controller = RecommendationsController(repo, ref);

  ref.listen<InstalledModelsState>(installedModelsControllerProvider, (prev, next) {
    controller.recalculateRecommendations();
  });

  ref.listen<DownloadsState>(downloadsControllerProvider, (prev, next) {
    controller.recalculateRecommendations();
  });

  return controller;
});
