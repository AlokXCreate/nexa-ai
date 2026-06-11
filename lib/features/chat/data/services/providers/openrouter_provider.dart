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

class OpenRouterProvider implements UniversalAiProvider {
  final Dio _dio = Dio();
  final CloudConfigRepository _configRepo;

  OpenRouterProvider(this._configRepo);

  @override
  String get id => 'openrouter';

  @override
  String get name => 'OpenRouter AI API';

  @override
  Future<bool> isAvailable() async {
    final config = await _configRepo.getConfigById(id);
    return config != null && config.isEnabled;
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
        throw Exception('OpenRouter provider is disabled or missing.');
      }

      final modelId = modelOverride ?? config.defaultModelId;
      final endpoint = '${config.baseUrl}/chat/completions';
      final headers = {
        'Content-Type': 'application/json',
        if (config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${config.apiKey}',
      };

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
        if (maxTokens != null) 'max_tokens': maxTokens,
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
        throw Exception('OpenRouter failed to respond.');
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
          if (dataStr == '[DONE]') continue;

          try {
            final json = jsonDecode(dataStr);
            final choice = json['choices']?[0];
            final delta = choice?['delta'];
            final content = delta?['content'] as String?;
            final toolCallsJson = delta?['tool_calls'] as List?;

            List<ToolCallDelta>? toolCallDeltas;
            if (toolCallsJson != null) {
              toolCallDeltas = toolCallsJson.map((tc) {
                return ToolCallDelta(
                  index: tc['index'] as int? ?? 0,
                  id: tc['id'] as String?,
                  type: tc['type'] as String?,
                  functionName: tc['function']?['name'] as String?,
                  functionArgumentsDelta: tc['function']?['arguments'] as String?,
                );
              }).toList();
            }

            if ((content != null && content.isNotEmpty) || toolCallDeltas != null) {
              totalGeneratedTokens++;
              controller.add(ProviderStreamChunk(
                textDelta: content ?? '',
                toolCallDeltas: toolCallDeltas,
              ));
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
    // Simulated general OpenRouter rates
    return 0.0;
  }
}

final openRouterAiProvider = Provider<OpenRouterProvider>((ref) {
  final repo = ref.watch(cloudConfigRepositoryProvider);
  return OpenRouterProvider(repo);
});
