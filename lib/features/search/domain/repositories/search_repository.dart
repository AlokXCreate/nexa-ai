import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/search/domain/entities/search_filters.dart';

abstract class SearchRepository {
  Future<List<MarketplaceModel>> searchModels({
    required int page,
    required int limit,
    required SearchFilters filters,
  });
}
