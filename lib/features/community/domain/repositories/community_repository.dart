import 'package:localmind_ai/features/community/domain/entities/community_model.dart';
import 'package:localmind_ai/features/community/domain/entities/model_review.dart';
import 'package:localmind_ai/features/community/domain/entities/model_collection.dart';
import 'package:localmind_ai/features/community/domain/entities/developer_profile.dart';

abstract class CommunityRepository {
  // Model management
  Future<List<CommunityModel>> getModels({String? category, String? query});
  Future<List<CommunityModel>> getTrendingModels();
  Future<List<CommunityModel>> getTopDownloadedModels();
  Future<List<CommunityModel>> getEditorChoiceModels();
  Future<List<CommunityModel>> getRecentlyAddedModels();
  Future<CommunityModel?> getModelById(String id);
  Future<void> uploadModel(CommunityModel model);

  // Bookmarks
  Future<void> bookmarkModel(String userId, String modelId);
  Future<void> unbookmarkModel(String userId, String modelId);
  Future<List<String>> getBookmarkedModelIds(String userId);

  // Reviews
  Future<void> saveReview(ModelReview review);
  Future<void> likeReview(String modelId, String reviewId, String userId);
  Future<List<ModelReview>> getReviewsForModel(String modelId);

  // Collections
  Future<void> saveCollection(ModelCollection collection);
  Future<void> deleteCollection(String collectionId);
  Future<List<ModelCollection>> getCollections({bool publicOnly = true});
  Future<ModelCollection?> getCollectionById(String collectionId);

  // Developer Follows
  Future<void> followDeveloper(String developerId, String userId);
  Future<void> unfollowDeveloper(String developerId, String userId);
  Future<List<DeveloperProfile>> getDevelopers();
  Future<DeveloperProfile?> getDeveloperById(String id);
}
