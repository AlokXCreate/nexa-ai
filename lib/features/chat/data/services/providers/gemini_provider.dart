import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/provider_response.dart';
import 'package:localmind_ai/features/chat/domain/repositories/universal_ai_provider.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_provider_config.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_usage_stats.dart';
import 'package:localmind_ai/features/plugins/domain/repositories/cloud_config_repository.dart';
import 'package:localmind_ai/features/plugins/data/repositories/cloud_config_repository_impl.dart';

class GeminiProvider implements UniversalAiProvider {
  final Dio _dio = Dio();
  final CloudConfigRepository _configRepo;

  GeminiProvider(this._configRepo);

  @override
  String get id => 'gemini';

  @override
  String get name => 'Google Gemini API';

  @override
  Future<bool> isAvailable() async {
    final config = await _configRepo.getConfigById(id);
    return config != null && config.isEnabled && config.apiKey.isNotEmpty;
  }

  @override
  Stream<ProviderStreamChunk> generateStream({
    required String prompt,
    required List<ChatMessage> history,
    String? modelOverride,
    double? temperature,
    double? topP,
    int? maxTokens,
    List<Map<String, dynamic>>? tools,
  }) {
    final controller = StreamController<ProviderStreamChunk>.broadcast();

    runZonedGuarded(() async {
      final config = await _configRepo.getConfigById(id);
      if (config == null || !config.isEnabled) {
        throw Exception('Gemini provider is disabled or missing.');
      }

      final modelId = modelOverride ?? config.defaultModelId;
      final endpoint = '${config.baseUrl}/models/$modelId:streamGenerateContent?key=${config.apiKey}';
      final headers = {'Content-Type': 'application/json'};

      // Map conversation history
      final contents = <Map<String, dynamic>>[];
      for (final msg in history) {
        contents.add({
          'role': msg.sender == MessageSender.user ? 'user' : 'model',
          'parts': [
            {'text': msg.content}
          ],
        });
      }
      contents.add({
        'role': 'user',
        'parts': [
          {'text': prompt}
        ],
      });

      final body = {
        'contents': contents,
        'generationConfig': {
          'temperature': temperature ?? 0.7,
          if (maxTokens != null) 'maxOutputTokens': maxTokens,
        },
        if (tools != null && tools.isNotEmpty) 'tools': tools,
      };

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
          break;
        } catch (e) {
          final isRateLimit = e is DioException && e.response?.statusCode == 429;
          final isTimeout = e is DioException &&
              (e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.receiveTimeout);

          if ((isRateLimit || isTimeout) && retries < config.maxRetries) {
            retries++;
            await Future.delayed(Duration(seconds: pow(2, retries).toInt()));
            continue;
          }
          rethrow;
        }
      }

      if (response == null || response.data == null) {
        throw Exception('Gemini failed to respond.');
      }

      int totalPromptTokens = (prompt.length / 4).round();
      int totalGeneratedTokens = 0;

      final transformer = response.data!.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in transformer) {
        final cleanLine = line.trim();
        if (cleanLine.isEmpty) continue;

        try {
          // Gemini returns streaming elements inside brackets
          final cleaned = cleanLine.replaceAll(RegExp(r'^,|\[|\]$'), '').trim();
          if (cleaned.isNotEmpty) {
            final json = jsonDecode(cleaned);
            final parts = json['candidates']?[0]?['content']?['parts'] as List?;
            if (parts != null) {
              String textDelta = '';
              List<ToolCallDelta>? toolCallDeltas;

              for (int i = 0; i < parts.length; i++) {
                final part = parts[i];
                final text = part['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  textDelta += text;
                }

                final fn = part['functionCall'];
                if (fn != null) {
                  toolCallDeltas ??= [];
                  toolCallDeltas.add(ToolCallDelta(
                    index: i,
                    id: 'call_${DateTime.now().millisecondsSinceEpoch}_$i',
                    type: 'function',
                    functionName: fn['name'] as String?,
                    functionArgumentsDelta: jsonEncode(fn['args']),
                  ));
                }
              }

              if (textDelta.isNotEmpty || toolCallDeltas != null) {
                totalGeneratedTokens++;
                controller.add(ProviderStreamChunk(
                  textDelta: textDelta,
                  toolCallDeltas: toolCallDeltas,
                ));
              }
            }
          }
        } catch (_) {}
      }

      // Record stats
      final cost = _calculateCost(totalPromptTokens, totalGeneratedTokens);
      final stats = CloudUsageStats(
        timestamp: DateTime.now(),
        providerId: id,
        modelId: modelId,
        promptTokens: totalPromptTokens,
        generationTokens: totalGeneratedTokens,
        estimatedCost: cost,
      );
      await _configRepo.saveUsage(stats);

      await controller.close();
    }, (error, stack) {
      controller.addError(error);
    });

    return controller.stream;
  }

  @override
  Future<ProviderResponse> generate({
    required String prompt,
    required List<ChatMessage> history,
    String? modelOverride,
    double? temperature,
    double? topP,
    int? maxTokens,
    List<Map<String, dynamic>>? tools,
  }) async {
    final completer = Completer<ProviderResponse>();
    final buffer = StringBuffer();
    final List<ToolCall> finalToolCalls = [];

    final stream = generateStream(
      prompt: prompt,
      history: history,
      modelOverride: modelOverride,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
      tools: tools,
    );

    stream.listen(
      (chunk) {
        if (chunk.textDelta.isNotEmpty) {
          buffer.write(chunk.textDelta);
        }
        if (chunk.toolCallDeltas != null) {
          for (final delta in chunk.toolCallDeltas!) {
            finalToolCalls.add(ToolCall(
              id: delta.id ?? '',
              type: delta.type ?? 'function',
              functionName: delta.functionName ?? '',
              functionArguments: delta.functionArgumentsDelta ?? '',
            ));
          }
        }
      },
      onError: (err) => completer.completeError(err),
      onDone: () {
        final text = buffer.toString();
        final promptTokens = (prompt.length / 4).round();
        final genTokens = (text.length / 4).round();
        final cost = _calculateCost(promptTokens, genTokens);

        completer.complete(ProviderResponse(
          text: text,
          toolCalls: finalToolCalls.isEmpty ? null : finalToolCalls,
          promptTokens: promptTokens,
          generationTokens: genTokens,
          estimatedCost: cost,
        ));
      },
    );

    return completer.future;
  }

  double _calculateCost(int promptTokens, int genTokens) {
    return ((promptTokens * 0.000075) + (genTokens * 0.0003)) / 1000.0;
  }
}

final geminiProvider = Provider<GeminiProvider>((ref) {
  final repo = ref.watch(cloudConfigRepositoryProvider);
  return GeminiProvider(repo);
});
