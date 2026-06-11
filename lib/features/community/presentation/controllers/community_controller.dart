import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:localmind_ai/features/community/domain/entities/community_model.dart';
import 'package:localmind_ai/features/community/domain/entities/model_review.dart';
import 'package:localmind_ai/features/community/domain/entities/model_collection.dart';
import 'package:localmind_ai/features/community/domain/entities/developer_profile.dart';
import 'package:localmind_ai/features/community/domain/repositories/community_repository.dart';
import 'package:localmind_ai/features/community/data/repositories/community_repository_impl.dart';

class CommunityState {
  final List<CommunityModel> models;
  final List<CommunityModel> trendingModels;
  final List<CommunityModel> editorChoiceModels;
  final List<ModelCollection> collections;
  final List<DeveloperProfile> developers;
  final List<String> bookmarkedModelIds;
  final List<ModelReview> activeReviews;
  final bool isLoading;
  final bool isUploading;
  final String searchQuery;
  final String selectedCategory;
  final String? error;

  const CommunityState({
    this.models = const [],
    this.trendingModels = const [],
    this.editorChoiceModels = const [],
    this.collections = const [],
    this.developers = const [],
    this.bookmarkedModelIds = const [],
    this.activeReviews = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.error,
  });

  CommunityState copyWith({
    List<CommunityModel>? models,
    List<CommunityModel>? trendingModels,
    List<CommunityModel>? editorChoiceModels,
    List<ModelCollection>? collections,
    List<DeveloperProfile>? developers,
    List<String>? bookmarkedModelIds,
    List<ModelReview>? activeReviews,
    bool? isLoading,
    bool? isUploading,
    String? searchQuery,
    String? selectedCategory,
    String? error,
    bool clearError = false,
  }) {
    return CommunityState(
      models: models ?? this.models,
      trendingModels: trendingModels ?? this.trendingModels,
      editorChoiceModels: editorChoiceModels ?? this.editorChoiceModels,
      collections: collections ?? this.collections,
      developers: developers ?? this.developers,
      bookmarkedModelIds: bookmarkedModelIds ?? this.bookmarkedModelIds,
      activeReviews: activeReviews ?? this.activeReviews,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CommunityController extends StateNotifier<CommunityState> {
  final CommunityRepository _repository;
  final Ref _ref;

  CommunityController(this._repository, this._ref) : super(const CommunityState()) {
    loadAll();
  }

  String? get _currentUserId {
    final user = _ref.read(authStateChangesProvider).value;
    return user?.id;
  }

  String get _currentUserName {
    final user = _ref.read(authStateChangesProvider).value;
    return user?.displayName ?? user?.email ?? 'Anonymous User';
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final models = await _repository.getModels(
        category: state.selectedCategory,
        query: state.searchQuery,
      );
      final trending = await _repository.getTrendingModels();
      final editorChoice = await _repository.getEditorChoiceModels();
      final collections = await _repository.getCollections();
      final devs = await _repository.getDevelopers();

      List<String> bookmarks = [];
      final uid = _currentUserId;
      if (uid != null) {
        bookmarks = await _repository.getBookmarkedModelIds(uid);
      }

      state = state.copyWith(
        models: models,
        trendingModels: trending,
        editorChoiceModels: editorChoice,
        collections: collections,
        developers: devs,
        bookmarkedModelIds: bookmarks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load community marketplace: $e');
    }
  }

  Future<void> setSelectedCategory(String category) async {
    state = state.copyWith(selectedCategory: category);
    await loadAll();
  }

  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadAll();
  }

  Future<bool> uploadModel(CommunityModel model) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      await _repository.uploadModel(model);
      await loadAll();
      state = state.copyWith(isUploading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: 'Upload failed: $e');
      return false;
    }
  }

  Future<void> toggleBookmark(String modelId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final isBookmarked = state.bookmarkedModelIds.contains(modelId);
    try {
      if (isBookmarked) {
        await _repository.unbookmarkModel(uid, modelId);
        state = state.copyWith(
          bookmarkedModelIds: state.bookmarkedModelIds.where((id) => id != modelId).toList(),
        );
      } else {
        await _repository.bookmarkModel(uid, modelId);
        state = state.copyWith(
          bookmarkedModelIds: [...state.bookmarkedModelIds, modelId],
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Bookmark change failed: $e');
    }
  }

  Future<void> loadReviews(String modelId) async {
    state = state.copyWith(clearError: true);
    try {
      final reviews = await _repository.getReviewsForModel(modelId);
      state = state.copyWith(activeReviews: reviews);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load reviews: $e');
    }
  }

  Future<bool> submitReview(String modelId, double rating, String comment) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    final review = ModelReview(
      id: 'rev_${modelId}_${uid}_${DateTime.now().millisecondsSinceEpoch}',
      modelId: modelId,
      userId: uid,
      userName: _currentUserName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.saveReview(review);
      await loadReviews(modelId);
      await loadAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to post review: $e');
      return false;
    }
  }

  Future<void> likeReview(String modelId, String reviewId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      await _repository.likeReview(modelId, reviewId, uid);
      await loadReviews(modelId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to like review: $e');
    }
  }

  Future<bool> createCollection(String name, String description, List<String> modelIds, bool isPublic) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    final col = ModelCollection(
      id: 'col_${uid}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      ownerId: uid,
      ownerName: _currentUserName,
      modelIds: modelIds,
      isPublic: isPublic,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.saveCollection(col);
      await loadAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create collection: $e');
      return false;
    }
  }

  Future<void> followDeveloper(String developerId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      await _repository.followDeveloper(developerId, uid);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Follow action failed: $e');
    }
  }

  Future<void> unfollowDeveloper(String developerId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      await _repository.unfollowDeveloper(developerId, uid);
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Unfollow action failed: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl();
});

final communityControllerProvider = StateNotifierProvider<CommunityController, CommunityState>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return CommunityController(repo, ref);
});
