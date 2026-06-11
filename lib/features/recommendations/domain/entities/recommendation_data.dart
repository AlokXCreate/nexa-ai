import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';

class RecommendationData {
  final List<MarketplaceModel> recommendedForYou;
  final List<MarketplaceModel> bestForDevice;
  final List<MarketplaceModel> trending;
  final List<MarketplaceModel> newReleases;
  final List<MarketplaceModel> popularCoding;
  final List<MarketplaceModel> popularChat;

  const RecommendationData({
    this.recommendedForYou = const [],
    this.bestForDevice = const [],
    this.trending = const [],
    this.newReleases = const [],
    this.popularCoding = const [],
    this.popularChat = const [],
  });

  RecommendationData copyWith({
    List<MarketplaceModel>? recommendedForYou,
    List<MarketplaceModel>? bestForDevice,
    List<MarketplaceModel>? trending,
    List<MarketplaceModel>? newReleases,
    List<MarketplaceModel>? popularCoding,
    List<MarketplaceModel>? popularChat,
  }) {
    return RecommendationData(
      recommendedForYou: recommendedForYou ?? this.recommendedForYou,
      bestForDevice: bestForDevice ?? this.bestForDevice,
      trending: trending ?? this.trending,
      newReleases: newReleases ?? this.newReleases,
      popularCoding: popularCoding ?? this.popularCoding,
      popularChat: popularChat ?? this.popularChat,
    );
  }

  factory RecommendationData.empty() {
    return const RecommendationData();
  }
}
