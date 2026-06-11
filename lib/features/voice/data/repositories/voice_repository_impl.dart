import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/voice/domain/entities/voice_settings.dart';
import 'package:localmind_ai/features/voice/domain/repositories/voice_repository.dart';

class VoiceRepositoryImpl implements VoiceRepository {
  static const String boxName = 'settingsBox';
  static const String settingsKey = 'voiceSettings';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  @override
  Future<VoiceSettings> getVoiceSettings() async {
    final box = await _getBox();
    final data = box.get(settingsKey);
    if (data == null) {
      final defaults = VoiceSettings.defaultSettings();
      await box.put(settingsKey, defaults.toMap());
      return defaults;
    }
    return VoiceSettings.fromMap(data as Map);
  }

  @override
  Future<void> saveVoiceSettings(VoiceSettings settings) async {
    final box = await _getBox();
    await box.put(settingsKey, settings.toMap());
  }
}
