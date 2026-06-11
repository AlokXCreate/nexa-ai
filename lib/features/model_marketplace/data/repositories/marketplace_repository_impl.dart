import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/model_marketplace/data/services/model_catalog_api_service.dart';
import 'package:localmind_ai/features/model_marketplace/data/services/model_catalog_fallback_data.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_query.dart';
import 'package:localmind_ai/features/model_marketplace/domain/repositories/marketplace_repository.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final ModelCatalogApiService _apiService = ModelCatalogApiService();
  static const String modelsBoxName = 'modelsBox';
  static const String installedBoxName = 'installedModelsBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(modelsBoxName)) {
      return await Hive.openBox(modelsBoxName);
    }
    return Hive.box(modelsBoxName);
  }

  @override
  Future<List<MarketplaceModel>> getModels({
    required int page,
    required int limit,
    required MarketplaceFilters filters,
  }) async {
    final box = await _getBox();

    // 1. Dynamic Refresh on Page 1 (Online update, fallback to cache on timeout/error)
    if (page == 1) {
      try {
        final remoteModels = await _apiService
            .fetchRemoteCatalog()
            .timeout(const Duration(seconds: 4));
        if (remoteModels.isNotEmpty) {
          await box.clear();
          for (final model in remoteModels) {
            await box.put(model.id, model.toMap());
          }
        }
      } catch (_) {
        // Offline or connection timeout - fallback silently to cached files
      }
    }

    // 2. Fetch cache, if completely empty populate with local fallback data
    if (box.isEmpty) {
      final fallbacks = ModelCatalogFallbackData.getFallbackModels();
      for (final model in fallbacks) {
        await box.put(model.id, model.toMap());
      }
    }

    // 3. Load cache from Hive
    final cachedMaps = box.values.toList();
    List<MarketplaceModel> results = cachedMaps
        .map((map) => MarketplaceModel.fromMap(map as Map))
        .toList();

    // 4. Cross-reference with Installed Models to resolve isDownloaded flag
    final installedBox = Hive.isBoxOpen(installedBoxName)
        ? Hive.box(installedBoxName)
        : await Hive.openBox(installedBoxName);
    final installedIds = installedBox.keys.map((k) => k.toString()).toSet();

    results = results.map((model) {
      return model.copyWith(isDownloaded: installedIds.contains(model.id));
    }).toList();

    // 5. Category Filtering
    results = results.where((model) =>
        model.category.toLowerCase() == filters.category.toLowerCase()).toList();

    // 6. Search Query (Check Name, Developer, Description, Family, Tags, Parameters)
    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      results = results.where((model) =>
          model.name.toLowerCase().contains(query) ||
          model.developer.toLowerCase().contains(query) ||
          model.family.toLowerCase().contains(query) ||
          model.description.toLowerCase().contains(query) ||
          model.parameters.toLowerCase().contains(query) ||
          model.tags.any((tag) => tag.toLowerCase().contains(query))).toList();
    }

    // 7. RAM Requirements Filtering
    if (filters.ramFilter != RamFilter.all) {
      results = results.where((model) {
        final ram = int.tryParse(model.ramRequirement.replaceAll(RegExp(r'\D'), '')) ?? 8;
        switch (filters.ramFilter) {
          case RamFilter.low:
            return ram <= 4;
          case RamFilter.mid:
            return ram > 4 && ram <= 8;
          case RamFilter.high:
            return ram > 8;
          default:
            return true;
        }
      }).toList();
    }

    // 8. Sorting
    switch (filters.sortBy) {
      case ModelSort.popularity:
        results.sort((a, b) => _parseDownloads(b.downloads).compareTo(_parseDownloads(a.downloads)));
        break;
      case ModelSort.rating:
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ModelSort.size:
        results.sort((a, b) => _parseSize(b.downloadSize).compareTo(_parseSize(a.downloadSize)));
        break;
    }

    // 9. Pagination Sublist
    final startIndex = (page - 1) * limit;
    if (startIndex >= results.length) return [];
    final endIndex = (startIndex + limit) > results.length ? results.length : (startIndex + limit);

    return results.sublist(startIndex, endIndex);
  }

  int _parseDownloads(String val) {
    if (val.endsWith('M')) {
      return (double.parse(val.replaceAll('M', '')) * 1000000).toInt();
    }
    if (val.endsWith('K')) {
      return (double.parse(val.replaceAll('K', '')) * 1000).toInt();
    }
    return int.tryParse(val) ?? 0;
  }

  double _parseSize(String val) {
    if (val.endsWith('GB')) {
      return double.parse(val.replaceAll('GB', '')) * 1024;
    }
    if (val.endsWith('MB')) {
      return double.parse(val.replaceAll('MB', ''));
    }
    return 0;
  }

  @override
  Future<MarketplaceModel?> getModelById(String id) async {
    final box = await _getBox();
    final data = box.get(id);
    if (data == null) {
      // Check fallbacks if not cached yet
      final fallbacks = ModelCatalogFallbackData.getFallbackModels();
      final index = fallbacks.indexWhere((m) => m.id == id);
      if (index != -1) return fallbacks[index];
      return null;
    }
    
    // Resolve downloaded state
    final installedBox = Hive.isBoxOpen(installedBoxName)
        ? Hive.box(installedBoxName)
        : await Hive.openBox(installedBoxName);
    final isDownloaded = installedBox.containsKey(id);

    return MarketplaceModel.fromMap(data as Map).copyWith(isDownloaded: isDownloaded);
  }
}
