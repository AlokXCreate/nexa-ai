import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_query.dart';

abstract class MarketplaceRepository {
  Future<List<MarketplaceModel>> getModels({
    required int page,
    required int limit,
    required MarketplaceFilters filters,
  });

  Future<MarketplaceModel?> getModelById(String id);
}
