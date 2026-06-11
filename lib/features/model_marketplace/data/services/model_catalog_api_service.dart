import 'package:dio/dio.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';

class ModelCatalogApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  static const String defaultCatalogUrl =
      'https://raw.githubusercontent.com/localmind-ai/models-registry/main/v1/model_catalog.json';

  Future<List<MarketplaceModel>> fetchRemoteCatalog({String? customUrl}) async {
    final url = customUrl ?? defaultCatalogUrl;
    try {
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data.containsKey('models')) {
          final List modelsList = data['models'] as List;
          return modelsList
              .map((map) => MarketplaceModel.fromMap(map as Map))
              .toList();
        } else {
          throw FormatException('Invalid JSON Catalog structure: "models" key missing.');
        }
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: url),
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error while retrieving AI catalog: ${e.message}');
    } catch (e) {
      throw Exception('Parsing error while reading remote catalog: $e');
    }
  }
}
