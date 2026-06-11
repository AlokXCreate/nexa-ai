import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/data/services/local_inference_service.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/provider_response.dart';
import 'package:localmind_ai/features/chat/domain/repositories/universal_ai_provider.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';
import 'package:localmind_ai/features/model_marketplace/domain/repositories/installed_models_repository.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';

class LocalAiProvider implements UniversalAiProvider {
  final LocalInferenceService _localInference;
  final InstalledModelsRepository _installedRepo;

  LocalAiProvider(this._localInference, this._installedRepo);

  @override
  String get id => 'local';

  @override
  String get name => 'Local Offline Model (GGUF)';

  @override
  Future<bool> isAvailable() async {
    final installed = await _installedRepo.getInstalledModels();
    return installed.isNotEmpty;
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
    final fullPrompt = _buildHistoryPrompt(prompt, history);
    
    final localStream = _localInference.streamInference(
      prompt: fullPrompt,
      temperature: temperature ?? 0.7,
      topP: topP ?? 0.9,
      maxTokens: maxTokens ?? 512,
    );

    return localStream.map((token) => ProviderStreamChunk(textDelta: token));
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
    final completer = Completer<String>();
    final buffer = StringBuffer();
    
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
      (chunk) => buffer.write(chunk.textDelta),
      onError: (err) => completer.completeError(err),
      onDone: () => completer.complete(buffer.toString()),
    );

    final text = await completer.future;
    return ProviderResponse(
      text: text,
      promptTokens: (prompt.length / 4).round(),
      generationTokens: (text.length / 4).round(),
      estimatedCost: 0.0,
    );
  }

  String _buildHistoryPrompt(String prompt, List<ChatMessage> history) {
    if (history.isEmpty) return prompt;
    final buffer = StringBuffer();
    for (final msg in history) {
      final role = msg.sender == MessageSender.user ? 'User' : 'Assistant';
      buffer.writeln('$role: ${msg.content}');
    }
    buffer.writeln('User: $prompt');
    buffer.writeln('Assistant:');
    return buffer.toString();
  }
}

final localAiProvider = Provider<LocalAiProvider>((ref) {
  final service = ref.watch(localInferenceServiceProvider);
  final repo = ref.watch(installedModelsRepositoryProvider);
  return LocalAiProvider(service, repo);
});
