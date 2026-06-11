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

class AnthropicProvider implements UniversalAiProvider {
  final Dio _dio = Dio();
  final CloudConfigRepository _configRepo;

  AnthropicProvider(this._configRepo);

  @override
  String get id => 'anthropic';

  @override
  String get name => 'Anthropic Compatible API';

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
        throw Exception('Anthropic provider is disabled or missing.');
      }

      final modelId = modelOverride ?? config.defaultModelId;
      final endpoint = '${config.baseUrl}/messages';
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
      };

      // Map conversation history
      final messages = <Map<String, dynamic>>[];
      for (final msg in history) {
        messages.add({
          'role': msg.sender == MessageSender.user ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
      messages.add({'role': 'user', 'content': prompt});

      final body = {
        'model': modelId,
        'messages': messages,
        'stream': true,
        'temperature': temperature ?? 0.7,
        'top_p': topP ?? 0.9,
        'max_tokens': maxTokens ?? 1024,
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
        throw Exception('Anthropic failed to respond.');
      }

      int totalPromptTokens = (prompt.length / 4).round();
      int totalGeneratedTokens = 0;

      final transformer = response.data!.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in transformer) {
        final cleanLine = line.trim();
        if (cleanLine.isEmpty) continue;

        if (cleanLine.startsWith('data: ')) {
          final dataStr = cleanLine.substring(6).trim();

          try {
            final json = jsonDecode(dataStr);
            final type = json['type'] as String?;

            if (type == 'content_block_start') {
              final cb = json['content_block'];
              if (cb?['type'] == 'tool_use') {
                totalGeneratedTokens++;
                controller.add(ProviderStreamChunk(
                  toolCallDeltas: [
                    ToolCallDelta(
                      index: json['index'] as int? ?? 0,
                      id: cb['id'] as String?,
                      type: 'function',
                      functionName: cb['name'] as String?,
                    )
                  ],
                ));
              }
            } else if (type == 'content_block_delta') {
              final delta = json['delta'];
              final deltaType = delta?['type'] as String?;

              if (deltaType == 'text_delta') {
                final content = delta['text'] as String?;
                if (content != null && content.isNotEmpty) {
                  totalGeneratedTokens++;
                  controller.add(ProviderStreamChunk(textDelta: content));
                }
              } else if (deltaType == 'input_json_delta') {
                final partial = delta['partial_json'] as String?;
                if (partial != null && partial.isNotEmpty) {
                  totalGeneratedTokens++;
                  controller.add(ProviderStreamChunk(
                    toolCallDeltas: [
                      ToolCallDelta(
                        index: json['index'] as int? ?? 0,
                        functionArgumentsDelta: partial,
                      )
                    ],
                  ));
                }
              }
            }
          } catch (_) {}
        }
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
    final Map<int, List<ToolCallDelta>> accumulatedTools = {};

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
            accumulatedTools.putIfAbsent(delta.index, () => []).add(delta);
          }
        }
      },
      onError: (err) => completer.completeError(err),
      onDone: () {
        final List<ToolCall> finalToolCalls = [];
        accumulatedTools.forEach((index, deltas) {
          final id = deltas.firstWhere((d) => d.id != null, orElse: () => const ToolCallDelta(index: 0)).id ?? '';
          final type = deltas.firstWhere((d) => d.type != null, orElse: () => const ToolCallDelta(index: 0)).type ?? 'function';
          final nameBuffer = StringBuffer();
          final argsBuffer = StringBuffer();
          for (final d in deltas) {
            if (d.functionName != null) nameBuffer.write(d.functionName);
            if (d.functionArgumentsDelta != null) argsBuffer.write(d.functionArgumentsDelta);
          }
          finalToolCalls.add(ToolCall(
            id: id,
            type: type,
            functionName: nameBuffer.toString(),
            functionArguments: argsBuffer.toString(),
          ));
        });

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
    return ((promptTokens * 0.003) + (genTokens * 0.015)) / 1000.0; // Claude Sonnet Rates
  }
}

final anthropicProvider = Provider<AnthropicProvider>((ref) {
  final repo = ref.watch(cloudConfigRepositoryProvider);
  return AnthropicProvider(repo);
});
