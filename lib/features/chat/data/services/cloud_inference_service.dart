import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_provider_config.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_usage_stats.dart';
import 'package:localmind_ai/features/plugins/domain/repositories/cloud_config_repository.dart';
import 'package:localmind_ai/features/plugins/data/repositories/cloud_config_repository_impl.dart';

class CloudInferenceService {
  final Dio _dio = Dio();
  final CloudConfigRepository _repository;

  CloudInferenceService(this._repository);

  Stream<String> streamCloudInference({
    required CloudProviderConfig config,
    required String prompt,
    String? modelOverride,
  }) {
    final controller = StreamController<String>.broadcast();
    final modelId = modelOverride ?? config.defaultModelId;

    // Run execution in async block to catch initial errors
    runZonedGuarded(() async {
      final endpoint = _resolveEndpoint(config, modelId);
      final headers = _resolveHeaders(config);
      final body = _resolveBody(config, modelId, prompt);

      int retries = 0;
      Response<ResponseBody>? response;

      while (retries <= config.maxRetries) {
        try {
          response = await _dio.post<ResponseBody>(
            endpoint,
            data: body,
            options: Options(
              headers: headers,
              responseType: ResponseType.stream,
              sendTimeout: Duration(seconds: config.timeoutSeconds),
              receiveTimeout: Duration(seconds: config.timeoutSeconds),
            ),
          );
          break; // Success
        } catch (e) {
          final isRateLimit = e is DioException && e.response?.statusCode == 429;
          final isTimeout = e is DioException &&
              (e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.receiveTimeout);

          if ((isRateLimit || isTimeout) && retries < config.maxRetries) {
            retries++;
            // Exponential backoff wait: 2^retries seconds
            await Future.delayed(Duration(seconds: pow(2, retries).toInt()));
            continue;
          }
          rethrow;
        }
      }

      if (response == null || response.data == null) {
        throw Exception('Cloud server failed to respond.');
      }

      int totalPromptTokens = (prompt.length / 4).round(); // Estimated input size
      int totalGeneratedTokens = 0;

      final transformer = response.data!.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in transformer) {
        final token = _parseStreamLine(config.id, line);
        if (token != null && token.isNotEmpty) {
          totalGeneratedTokens++;
          controller.add(token);
        }
      }

      // Record Usage Statistics
      final cost = _calculateCost(config.id, totalPromptTokens, totalGeneratedTokens);
      final stats = CloudUsageStats(
        timestamp: DateTime.now(),
        providerId: config.id,
        modelId: modelId,
        promptTokens: totalPromptTokens,
        generationTokens: totalGeneratedTokens,
        estimatedCost: cost,
      );
      await _repository.saveUsage(stats);

      await controller.close();
    }, (error, stack) {
      controller.addError(error);
    });

    return controller.stream;
  }

  String _resolveEndpoint(CloudProviderConfig config, String modelId) {
    switch (config.id) {
      case 'openai':
      case 'openrouter':
      case 'custom':
        return '${config.baseUrl}/chat/completions';
      case 'anthropic':
        return '${config.baseUrl}/messages';
      case 'gemini':
        return '${config.baseUrl}/models/$modelId:streamGenerateContent?key=${config.apiKey}';
      case 'ollama':
        return '${config.baseUrl}/chat';
      default:
        throw Exception('Unsupported cloud provider ID: ${config.id}');
    }
  }

  Map<String, dynamic> _resolveHeaders(CloudProviderConfig config) {
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    
    switch (config.id) {
      case 'openai':
      case 'openrouter':
      case 'custom':
        if (config.apiKey.isNotEmpty) {
          headers['Authorization'] = 'Bearer ${config.apiKey}';
        }
        break;
      case 'anthropic':
        headers['x-api-key'] = config.apiKey;
        headers['anthropic-version'] = '2023-06-01';
        break;
      case 'gemini':
        // Api key passed in URL query param
        break;
      case 'ollama':
        // Ollama usually runs unauthenticated locally
        break;
    }
    return headers;
  }

  Map<String, dynamic> _resolveBody(CloudProviderConfig config, String modelId, String prompt) {
    switch (config.id) {
      case 'openai':
      case 'openrouter':
      case 'custom':
        return {
          'model': modelId,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': true,
          'temperature': 0.7,
        };
      case 'anthropic':
        return {
          'model': modelId,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 1024,
          'stream': true,
        };
      case 'gemini':
        return {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        };
      case 'ollama':
        return {
          'model': modelId,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': true,
        };
      default:
        return {};
    }
  }

  String? _parseStreamLine(String providerId, String line) {
    final cleanLine = line.trim();
    if (cleanLine.isEmpty) return null;

    switch (providerId) {
      case 'openai':
      case 'openrouter':
      case 'custom':
        if (cleanLine.startsWith('data: ')) {
          final dataStr = cleanLine.substring(6).trim();
          if (dataStr == '[DONE]') return null;
          try {
            final json = jsonDecode(dataStr);
            return json['choices']?[0]?['delta']?['content'] as String?;
          } catch (_) {}
        }
        break;

      case 'anthropic':
        if (cleanLine.startsWith('data: ')) {
          final dataStr = cleanLine.substring(6).trim();
          try {
            final json = jsonDecode(dataStr);
            if (json['type'] == 'content_block_delta') {
              return json['delta']?['text'] as String?;
            }
          } catch (_) {}
        }
        break;

      case 'gemini':
        try {
          // Gemini returns streaming elements inside brackets
          final cleaned = cleanLine.replaceAll(RegExp(r'^,|\[|\]$'), '').trim();
          if (cleaned.isNotEmpty) {
            final json = jsonDecode(cleaned);
            return json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          }
        } catch (_) {}
        break;

      case 'ollama':
        try {
          final json = jsonDecode(cleanLine);
          return json['message']?['content'] as String?;
        } catch (_) {}
        break;
    }
    return null;
  }

  double _calculateCost(String providerId, int promptTokens, int genTokens) {
    // Simulated token price schemas per 1k tokens
    double promptPrice = 0.0;
    double genPrice = 0.0;

    switch (providerId) {
      case 'openai':
        promptPrice = 0.00015; // GPT-4o-mini rates
        genPrice = 0.0006;
        break;
      case 'anthropic':
        promptPrice = 0.003; // Sonnet rates
        genPrice = 0.015;
        break;
      case 'gemini':
        promptPrice = 0.000075;
        genPrice = 0.0003;
        break;
      case 'openrouter':
        promptPrice = 0.0; // Assume free model tier rates
        genPrice = 0.0;
        break;
      default:
        break;
    }

    return ((promptTokens * promptPrice) + (genTokens * genPrice)) / 1000.0;
  }
}

final cloudInferenceServiceProvider = Provider<CloudInferenceService>((ref) {
  final repo = ref.watch(cloudConfigRepositoryProvider);
  return CloudInferenceService(repo);
});
