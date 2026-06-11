import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/domain/repositories/universal_ai_provider.dart';
import 'package:localmind_ai/features/chat/data/services/providers/local_provider.dart';
import 'package:localmind_ai/features/chat/data/services/providers/openai_provider.dart';
import 'package:localmind_ai/features/chat/data/services/providers/anthropic_provider.dart';
import 'package:localmind_ai/features/chat/data/services/providers/gemini_provider.dart';
import 'package:localmind_ai/features/chat/data/services/providers/openrouter_provider.dart';
import 'package:localmind_ai/features/chat/data/services/providers/ollama_provider.dart';
import 'package:localmind_ai/features/chat/data/services/providers/custom_provider.dart';

final universalProvidersListProvider = Provider<List<UniversalAiProvider>>((ref) {
  return [
    ref.watch(localAiProvider),
    ref.watch(openAiProvider),
    ref.watch(anthropicAiProvider),
    ref.watch(geminiAiProvider),
    ref.watch(openRouterAiProvider),
    ref.watch(ollamaAiProvider),
    ref.watch(customAiProvider),
  ];
});
