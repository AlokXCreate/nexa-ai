import 'package:localmind_ai/features/voice/domain/entities/voice_settings.dart';

abstract class VoiceRepository {
  Future<VoiceSettings> getVoiceSettings();
  Future<void> saveVoiceSettings(VoiceSettings settings);
}
