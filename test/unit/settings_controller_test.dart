import 'package:flutter_test/flutter_test.dart';
import 'package:localmind_ai/features/settings/domain/entities/app_settings.dart';
import 'package:localmind_ai/features/settings/domain/repositories/settings_repository.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';

class FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = AppSettings.defaultSettings();

  @override
  Future<AppSettings> getSettings() async {
    return _settings;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}

void main() {
  group('SettingsController & AppSettings Unit Tests', () {
    late FakeSettingsRepository repository;
    late SettingsController controller;

    setUp(() {
      repository = FakeSettingsRepository();
      controller = SettingsController(repository);
    });

    test('Initial state contains default settings', () async {
      expect(controller.state.settings.languageCode, equals('en'));
      expect(controller.state.settings.highContrast, isFalse);
      expect(controller.state.settings.themeMode, equals('system'));
    });

    test('Update theme mode persists and updates state', () async {
      await controller.updateThemeMode('dark');
      expect(controller.state.settings.themeMode, equals('dark'));
    });

    test('Update language code persists and updates state', () async {
      await controller.updateLanguageCode('hi');
      expect(controller.state.settings.languageCode, equals('hi'));
    });

    test('Toggle high contrast mode updates state', () async {
      await controller.toggleHighContrast(true);
      expect(controller.state.settings.highContrast, isTrue);
    });
  });
}
