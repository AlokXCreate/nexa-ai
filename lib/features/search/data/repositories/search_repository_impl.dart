import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/model_marketplace/data/services/model_catalog_fallback_data.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/search/domain/entities/search_filters.dart';
import 'package:localmind_ai/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  static const String modelsBoxName = 'modelsBox';
  static const String installedBoxName = 'installedModelsBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(modelsBoxName)) {
      return await Hive.openBox(modelsBoxName);
    }
    return Hive.box(modelsBoxName);
  }

  @override
  Future<List<MarketplaceModel>> searchModels({
    required int page,
    required int limit,
    required SearchFilters filters,
  }) async {
    final box = await _getBox();

    if (box.isEmpty) {
      final fallbacks = ModelCatalogFallbackData.getFallbackModels();
      for (final model in fallbacks) {
        await box.put(model.id, model.toMap());
      }
    }

    final cachedMaps = box.values.toList();
    List<MarketplaceModel> results = cachedMaps
        .map((map) => MarketplaceModel.fromMap(map as Map))
        .toList();

    // 1. Cross-reference downloads
    final installedBox = Hive.isBoxOpen(installedBoxName)
        ? Hive.box(installedBoxName)
        : await Hive.openBox(installedBoxName);
    final installedIds = installedBox.keys.map((k) => k.toString()).toSet();

    results = results.map((model) {
      return model.copyWith(isDownloaded: installedIds.contains(model.id));
    }).toList();

    // 2. Query text search (Name, Developer, Family, Description, Tags, Parameters)
    if (filters.query.isNotEmpty) {
      final q = filters.query.toLowerCase();
      results = results.where((model) =>
          model.name.toLowerCase().contains(q) ||
          model.developer.toLowerCase().contains(q) ||
          model.family.toLowerCase().contains(q) ||
          model.description.toLowerCase().contains(q) ||
          model.parameters.toLowerCase().contains(q) ||
          model.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }

    // 3. Category Filter
    if (filters.category != 'All') {
      results = results.where((model) =>
          model.category.toLowerCase() == filters.category.toLowerCase()).toList();
    }

    // 4. Parameter Size Filter
    if (filters.paramSize != 'All') {
      results = results.where((model) {
        final cleanParam = model.parameters.replaceAll(RegExp(r'[^\d.]'), '');
        final size = double.tryParse(cleanParam) ?? 7.0;
        switch (filters.paramSize) {
          case 'small':
            return size <= 3.0;
          case 'medium':
            return size > 3.0 && size <= 7.0;
          case 'large':
            return size > 7.0;
          default:
            return true;
        }
      }).toList();
    }

    // 5. RAM Requirement Filter
    if (filters.ramFilter != 'All') {
      results = results.where((model) {
        final cleanRam = model.ramRequirement.replaceAll(RegExp(r'[^\d.]'), '');
        final ram = double.tryParse(cleanRam) ?? 8.0;
        switch (filters.ramFilter) {
          case 'low':
            return ram <= 4.0;
          case 'mid':
            return ram > 4.0 && ram <= 8.0;
          case 'high':
            return ram > 8.0;
          default:
            return true;
        }
      }).toList();
    }

    // 6. Language Filter
    if (filters.language != 'All') {
      results = results.where((model) => model.languages.any((l) =>
          l.toLowerCase().contains(filters.language.toLowerCase()))).toList();
    }

    // 7. Sorting
    switch (filters.sortBy) {
      case 'size':
        results.sort((a, b) => _parseSize(b.downloadSize).compareTo(_parseSize(a.downloadSize)));
        break;
      case 'rating':
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popularity':
      default:
        results.sort((a, b) => _parseDownloads(b.downloads).compareTo(_parseDownloads(a.downloads)));
        break;
    }

    // 8. Paging
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
      return (double.parse(val.replaceAll('K', '')) * 100).toInt();
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
}
