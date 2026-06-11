import 'package:localmind_ai/features/chat/domain/entities/chat_message.dart';
import 'package:localmind_ai/features/chat/domain/entities/provider_response.dart';

abstract class UniversalAiProvider {
  String get id; // e.g. 'local', 'openai', 'gemini', 'anthropic', 'openrouter', 'custom'
  String get name;

  Future<bool> isAvailable();

  Stream<ProviderStreamChunk> generateStream({
    required String prompt,
    required List<ChatMessage> history,
    String? modelOverride,
    double? temperature,
    double? topP,
    int? maxTokens,
    List<Map<String, dynamic>>? tools,
  });

  Future<ProviderResponse> generate({
    required String prompt,
    required List<ChatMessage> history,
    String? modelOverride,
    double? temperature,
    double? topP,
    int? maxTokens,
    List<Map<String, dynamic>>? tools,
  });
}
