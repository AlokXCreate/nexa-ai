import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';

abstract class RecommendationsRepository {
  Future<List<MarketplaceModel>> getAllCatalogModels();
}
