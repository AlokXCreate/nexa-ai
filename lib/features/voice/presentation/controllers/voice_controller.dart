import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_messages_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';
import 'package:localmind_ai/features/voice/domain/entities/voice_settings.dart';
import 'package:localmind_ai/features/voice/domain/repositories/voice_repository.dart';
import 'package:localmind_ai/features/voice/data/repositories/voice_repository_impl.dart';
import 'package:localmind_ai/features/voice/data/services/voice_service.dart';

class VoiceState {
  final AssistantVoiceStatus status;
  final String userTranscript;
  final String aiTranscript;
  final double soundLevel;
  final VoiceSettings settings;
  final List<Map<String, String>> availableVoices;

  VoiceState({
    this.status = AssistantVoiceStatus.idle,
    this.userTranscript = '',
    this.aiTranscript = '',
    this.soundLevel = 0.0,
    required this.settings,
    this.availableVoices = const [],
  });

  VoiceState copyWith({
    AssistantVoiceStatus? status,
    String? userTranscript,
    String? aiTranscript,
    double? soundLevel,
    VoiceSettings? settings,
    List<Map<String, String>>? availableVoices,
  }) {
    return VoiceState(
      status: status ?? this.status,
      userTranscript: userTranscript ?? this.userTranscript,
      aiTranscript: aiTranscript ?? this.aiTranscript,
      soundLevel: soundLevel ?? this.soundLevel,
      settings: settings ?? this.settings,
      availableVoices: availableVoices ?? this.availableVoices,
    );
  }
}

class VoiceController extends StateNotifier<VoiceState> {
  final VoiceRepository _repository;
  final VoiceService _voiceService;
  final Ref _ref;
  
  String _lastLlmText = '';

  VoiceController(
    this._repository,
    this._voiceService,
    this._ref,
  ) : super(VoiceState(settings: VoiceSettings.defaultSettings())) {
    _init();
  }

  void _init() async {
    final settings = await _repository.getVoiceSettings();
    state = state.copyWith(settings: settings);

    // Apply tts configuration
    await _voiceService.configureTts(
      voiceName: settings.voiceName,
      speed: settings.speechRate,
    );

    // Fetch offline voice profiles
    final voices = await _voiceService.getVoices();
    state = state.copyWith(availableVoices: voices);

    // 1. Listen to service status streams
    _voiceService.statusStream.listen((status) {
      state = state.copyWith(status: status);
      if (status == AssistantVoiceStatus.listening) {
        state = state.copyWith(userTranscript: '', aiTranscript: '');
      }
    });

    // 2. Listen to voice transcript recognition
    _voiceService.transcriptStream.listen((transcript) {
      state = state.copyWith(userTranscript: transcript);
    });

    // 3. Listen to microphone decibel levels
    _voiceService.decibelStream.listen((db) {
      state = state.copyWith(soundLevel: db);
    });

    // 4. Hook service callbacks
    _voiceService.onSpeechRecognized = (transcript) {
      _sendUserPrompt(transcript);
    };

    _voiceService.onTtsQueueFinished = () {
      if (state.settings.isHandsFree && state.status == AssistantVoiceStatus.idle) {
        // Continuous Dialogue: automatically resume listening after speaking ends
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && state.settings.isHandsFree && state.status == AssistantVoiceStatus.idle) {
            startListening();
          }
        });
      }
    };

    // 5. Listen to LLM runtime stream diffs
    _ref.listen<LocalRuntimeState>(localRuntimeControllerProvider, (prev, next) {
      if (next.isGenerating) {
        if (next.currentGenerationText.length > _lastLlmText.length) {
          final diff = next.currentGenerationText.substring(_lastLlmText.length);
          _voiceService.feedStreamingToken(diff);
          _lastLlmText = next.currentGenerationText;
          state = state.copyWith(aiTranscript: next.currentGenerationText);
        }
      } else {
        if (prev != null && prev.isGenerating) {
          _voiceService.finalizeStreamingResponse();
          _lastLlmText = '';
        }
      }
    });
  }

  Future<void> startListening() async {
    _lastLlmText = '';
    // If AI is speaking, interrupt it
    if (state.status == AssistantVoiceStatus.speaking) {
      await _voiceService.stopSpeaking();
      _ref.read(localRuntimeControllerProvider.notifier).stopGeneration();
    }
    await _voiceService.startListening();
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  Future<void> cancelVoiceAssistant() async {
    _lastLlmText = '';
    await _voiceService.resetAll();
    _ref.read(localRuntimeControllerProvider.notifier).stopGeneration();
  }

  Future<void> _sendUserPrompt(String text) async {
    if (text.trim().isEmpty) {
      state = state.copyWith(status: AssistantVoiceStatus.idle);
      return;
    }

    state = state.copyWith(status: AssistantVoiceStatus.thinking);
    // Send user message to active chat messages list
    await _ref.read(chatMessagesControllerProvider.notifier).sendMessage(text);
  }

  Future<void> updateSpeechRate(double rate) async {
    final updated = state.settings.copyWith(speechRate: rate);
    await _repository.saveVoiceSettings(updated);
    state = state.copyWith(settings: updated);
    await _voiceService.configureTts(speed: rate);
  }

  Future<void> updateVoice(String voiceName) async {
    final updated = state.settings.copyWith(voiceName: voiceName);
    await _repository.saveVoiceSettings(updated);
    state = state.copyWith(settings: updated);
    await _voiceService.configureTts(voiceName: voiceName);
  }

  Future<void> toggleHandsFree(bool enable) async {
    final updated = state.settings.copyWith(isHandsFree: enable);
    await _repository.saveVoiceSettings(updated);
    state = state.copyWith(settings: updated);
  }
}

// Riverpod Providers
final voiceRepositoryProvider = Provider<VoiceRepository>((ref) {
  return VoiceRepositoryImpl();
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

final voiceControllerProvider = StateNotifierProvider<VoiceController, VoiceState>((ref) {
  final repo = ref.watch(voiceRepositoryProvider);
  final service = ref.watch(voiceServiceProvider);
  return VoiceController(repo, service, ref);
});
