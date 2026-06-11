import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/model_marketplace/data/services/model_catalog_fallback_data.dart';
import 'package:localmind_ai/features/recommendations/domain/repositories/recommendations_repository.dart';

class RecommendationsRepositoryImpl implements RecommendationsRepository {
  static const String modelsBoxName = 'modelsBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(modelsBoxName)) {
      return await Hive.openBox(modelsBoxName);
    }
    return Hive.box(modelsBoxName);
  }

  @override
  Future<List<MarketplaceModel>> getAllCatalogModels() async {
    final box = await _getBox();
    
    if (box.isEmpty) {
      return ModelCatalogFallbackData.getFallbackModels();
    }

    final cachedMaps = box.values.toList();
    return cachedMaps
        .map((map) => MarketplaceModel.fromMap(map as Map))
        .toList();
  }
}
