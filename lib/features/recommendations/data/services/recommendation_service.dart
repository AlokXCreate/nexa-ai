import 'dart:math';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/recommendations/domain/entities/recommendation_data.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/installed_model.dart';

class RecommendationService {
  Future<RecommendationData> generateRecommendations({
    required List<MarketplaceModel> allModels,
    required List<InstalledModel> installedModels,
    required List<DownloadTaskModel> recentDownloads,
    required List<String> recentSearches,
    required List<String> favorites,
    required double deviceRamGb,
    required double deviceFreeStorageGb,
  }) async {
    // 1. Compute Category Preference Weights
    final Map<String, double> categoryScores = {
      'Chat': 1.0,
      'Coding': 1.0,
      'Reasoning': 1.0,
      'Writing': 1.0,
      'Translation': 1.0,
      'Vision': 1.0,
    };

    // Installed models weights (heavy weight: +2.0)
    for (final model in installedModels) {
      // Find matching catalog category
      final catalogMatch = allModels.firstWhere(
        (m) => m.id == model.id,
        orElse: () => const MarketplaceModel(
          id: '', name: '', family: '', developer: '', description: '', category: 'Chat',
          parameters: '', quantization: '', downloadSize: '', installedSize: '',
          ramRequirement: '', minimumAndroidVersion: '', version: '', releaseDate: '',
          languages: [], license: '', rating: 4.0, downloads: '', thumbnail: '', banner: '',
          tags: [], downloadUrl: '', checksum: ''
        ),
      );
      if (catalogMatch.id.isNotEmpty) {
        categoryScores[catalogMatch.category] = (categoryScores[catalogMatch.category] ?? 0) + 2.0;
      }
    }

    // Recent downloads weights (+1.5)
    for (final task in recentDownloads) {
      final catalogMatch = allModels.firstWhere((m) => m.id == task.id, orElse: () => allModels.first);
      categoryScores[catalogMatch.category] = (categoryScores[catalogMatch.category] ?? 0) + 1.5;
    }

    // Favorites weights (+1.5)
    for (final favId in favorites) {
      final catalogMatch = allModels.firstWhere((m) => m.id == favId, orElse: () => allModels.first);
      categoryScores[catalogMatch.category] = (categoryScores[catalogMatch.category] ?? 0) + 1.5;
    }

    // Recent Searches weights (+1.0)
    for (final query in recentSearches) {
      final q = query.toLowerCase();
      if (q.contains('code') || q.contains('coding') || q.contains('python') || q.contains('rust')) {
        categoryScores['Coding'] = categoryScores['Coding']! + 1.0;
      }
      if (q.contains('chat') || q.contains('agent') || q.contains('assistant') || q.contains('converse')) {
        categoryScores['Chat'] = categoryScores['Chat']! + 1.0;
      }
      if (q.contains('reason') || q.contains('logic') || q.contains('math') || q.contains('cot') || q.contains('r1')) {
        categoryScores['Reasoning'] = categoryScores['Reasoning']! + 1.0;
      }
      if (q.contains('write') || q.contains('creative') || q.contains('blog') || q.contains('text')) {
        categoryScores['Writing'] = categoryScores['Writing']! + 1.0;
      }
      if (q.contains('trans') || q.contains('language') || q.contains('multilingual') || q.contains('speak')) {
        categoryScores['Translation'] = categoryScores['Translation']! + 1.0;
      }
      if (q.contains('vision') || q.contains('image') || q.contains('ocr') || q.contains('describe')) {
        categoryScores['Vision'] = categoryScores['Vision']! + 1.0;
      }
    }

    // Sort categories based on preference
    final sortedCategories = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory1 = sortedCategories[0].key;
    final topCategory2 = sortedCategories[1].key;

    final installedIds = installedModels.map((m) => m.id).toSet();

    // 2. Filter Sections
    // SECTION A: Recommended For You (Exclude installed models, pick from top 2 favorite categories)
    final recommendedForYou = allModels
        .where((m) => !installedIds.contains(m.id) && (m.category == topCategory1 || m.category == topCategory2))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    // SECTION B: Best For Device (Excluding models beyond hardware capabilities)
    final bestForDevice = allModels.where((m) {
      final ram = _parseRamGb(m.ramRequirement);
      final storage = _parseSizeGb(m.installedSize);
      return ram <= deviceRamGb && storage <= deviceFreeStorageGb;
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    // SECTION C: Trending (Downloads popularity count sorting)
    final trending = [...allModels]
      ..sort((a, b) => _parseDownloads(b.downloads).compareTo(_parseDownloads(a.downloads)));

    // SECTION D: New Releases (Sort by releaseDate descending)
    final newReleases = [...allModels]
      ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

    // SECTION E: Popular Coding
    final popularCoding = allModels.where((m) => m.category == 'Coding').toList()
      ..sort((a, b) => _parseDownloads(b.downloads).compareTo(_parseDownloads(a.downloads)));

    // SECTION F: Popular Chat
    final popularChat = allModels.where((m) => m.category == 'Chat').toList()
      ..sort((a, b) => _parseDownloads(b.downloads).compareTo(_parseDownloads(a.downloads)));

    return RecommendationData(
      recommendedForYou: recommendedForYou.sublist(0, min(10, recommendedForYou.length)),
      bestForDevice: bestForDevice.sublist(0, min(10, bestForDevice.length)),
      trending: trending.sublist(0, min(10, trending.length)),
      newReleases: newReleases.sublist(0, min(10, newReleases.length)),
      popularCoding: popularCoding.sublist(0, min(10, popularCoding.length)),
      popularChat: popularChat.sublist(0, min(10, popularChat.length)),
    );
  }

  double _parseRamGb(String ramStr) {
    final clean = ramStr.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean) ?? 4.0;
  }

  double _parseSizeGb(String sizeStr) {
    final clean = sizeStr.replaceAll(RegExp(r'[^\d.]'), '');
    final num = double.tryParse(clean) ?? 2.0;
    if (sizeStr.toUpperCase().contains('MB')) {
      return num / 1024.0;
    }
    return num;
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
}
