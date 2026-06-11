import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/settings/domain/entities/app_settings.dart';
import 'package:localmind_ai/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String boxName = 'settingsBox';
  static const String settingsKey = 'appSettings';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  @override
  Future<AppSettings> getSettings() async {
    final box = await _getBox();
    final data = box.get(settingsKey);
    if (data == null) {
      final defaults = AppSettings.defaultSettings();
      await box.put(settingsKey, defaults.toMap());
      return defaults;
    }
    return AppSettings.fromMap(data as Map);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final box = await _getBox();
    await box.put(settingsKey, settings.toMap());
  }
}
