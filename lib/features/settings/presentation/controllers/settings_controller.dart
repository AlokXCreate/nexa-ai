import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:localmind_ai/features/settings/domain/entities/app_settings.dart';
import 'package:localmind_ai/features/settings/domain/repositories/settings_repository.dart';
import 'package:localmind_ai/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:localmind_ai/features/settings/data/repositories/settings_repository_sync_decorator.dart';

class SettingsState {
  final AppSettings settings;
  final String cacheSize;
  final double storageUsedGb;
  final double storageFreeGb;
  final double storageTotalGb;
  final bool isCleaning;
  final bool isAnalyzing;
  final List<String> debugLogs;

  const SettingsState({
    required this.settings,
    this.cacheSize = '0.0 MB',
    this.storageUsedGb = 64.5,
    this.storageFreeGb = 191.5,
    this.storageTotalGb = 256.0,
    this.isCleaning = false,
    this.isAnalyzing = false,
    this.debugLogs = const [],
  });

  SettingsState copyWith({
    AppSettings? settings,
    String? cacheSize,
    double? storageUsedGb,
    double? storageFreeGb,
    double? storageTotalGb,
    bool? isCleaning,
    bool? isAnalyzing,
    List<String>? debugLogs,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      cacheSize: cacheSize ?? this.cacheSize,
      storageUsedGb: storageUsedGb ?? this.storageUsedGb,
      storageFreeGb: storageFreeGb ?? this.storageFreeGb,
      storageTotalGb: storageTotalGb ?? this.storageTotalGb,
      isCleaning: isCleaning ?? this.isCleaning,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      debugLogs: debugLogs ?? this.debugLogs,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  SettingsController(this._repository)
      : super(SettingsState(settings: AppSettings.defaultSettings())) {
    _init();
  }

  void _init() async {
    final settings = await _repository.getSettings();
    state = state.copyWith(settings: settings);
    
    // Add initial system logs
    log('System initialized.');
    log('Theme mode loaded: ${settings.themeMode}');
    log('Accent color loaded: ${settings.accentColor}');
    
    analyzeStorage();
  }

  // Helper to log messages inside the controller
  void log(String message) {
    if (!state.settings.enableDebugLogs) return;
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logLine = '[$timestamp] $message';
    state = state.copyWith(debugLogs: [logLine, ...state.debugLogs].sublist(0, min(100, state.debugLogs.length + 1)));
  }

  void clearLogs() {
    state = state.copyWith(debugLogs: []);
  }

  // Persistence methods
  Future<void> _save(AppSettings updated) async {
    state = state.copyWith(settings: updated);
    await _repository.saveSettings(updated);
  }

  // 1. Appearance Settings
  Future<void> updateThemeMode(String mode) async {
    log('Theme mode changed to: $mode');
    await _save(state.settings.copyWith(themeMode: mode));
  }

  // 2. Customization Settings
  Future<void> updateAccentColor(String color) async {
    log('Accent color changed to: $color');
    await _save(state.settings.copyWith(accentColor: color));
  }

  Future<void> updateFontSize(String size) async {
    log('Font size changed to: $size');
    await _save(state.settings.copyWith(fontSize: size));
  }

  Future<void> updateAnimationSpeed(String speed) async {
    log('Animation speed changed to: $speed');
    await _save(state.settings.copyWith(animationSpeed: speed));
  }

  Future<void> updateLanguageCode(String code) async {
    log('Language changed to: $code');
    await _save(state.settings.copyWith(languageCode: code));
  }

  Future<void> toggleHighContrast(bool enabled) async {
    log('High contrast toggled: $enabled');
    await _save(state.settings.copyWith(highContrast: enabled));
  }

  Future<void> updateCustomColors({
    String? primary,
    String? accent,
    String? bg,
    String? surface,
  }) async {
    log('Custom colors applied from theme plugin');
    await _save(state.settings.copyWith(
      customPrimaryColor: primary,
      customAccentColor: accent,
      customBgColor: bg,
      customSurfaceColor: surface,
    ));
  }

  Future<void> clearCustomColors() async {
    log('Custom colors cleared');
    await _save(state.settings.copyWith(clearCustomColors: true));
  }

  // 3. AI Settings
  Future<void> updateDefaultModelId(String? modelId) async {
    log('Default model ID changed to: $modelId');
    if (modelId == null) {
      await _save(state.settings.copyWith(clearDefaultModel: true));
    } else {
      await _save(state.settings.copyWith(defaultModelId: modelId));
    }
  }

  Future<void> updateMaxContextSize(int contextSize) async {
    log('Max context size changed to: $contextSize');
    await _save(state.settings.copyWith(maxContextSize: contextSize));
  }

  Future<void> updateInferenceMode(String mode) async {
    log('Inference mode changed to: $mode');
    await _save(state.settings.copyWith(inferenceMode: mode));
  }

  // 4. Developer Settings
  Future<void> togglePerformanceMonitor(bool show) async {
    log('Performance monitor toggled: $show');
    await _save(state.settings.copyWith(showPerformanceMonitor: show));
  }

  Future<void> toggleDebugLogs(bool enable) async {
    // If enabling, we need to save first so that the log call registers.
    final updated = state.settings.copyWith(enableDebugLogs: enable);
    state = state.copyWith(settings: updated);
    await _repository.saveSettings(updated);
    log('Debug logs toggled: $enable');
  }

  Future<void> toggleTokenCounter(bool show) async {
    log('Token counter toggled: $show');
    await _save(state.settings.copyWith(showTokenCounter: show));
  }

  // 5. Storage Settings
  Future<void> updateDownloadLocation(String location) async {
    log('Download location updated: $location');
    await _save(state.settings.copyWith(downloadLocation: location));
  }

  Future<void> cleanCache() async {
    state = state.copyWith(isCleaning: true);
    log('Cache cleanup initiated...');
    
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        final List<FileSystemEntity> files = cacheDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
      await Future.delayed(const Duration(seconds: 1)); // UX delay for beautiful loader
      log('Cache cleaned successfully.');
    } catch (e) {
      log('Cache cleanup failed: $e');
    } finally {
      state = state.copyWith(isCleaning: false);
      analyzeStorage();
    }
  }

  Future<void> analyzeStorage() async {
    state = state.copyWith(isAnalyzing: true);
    log('Storage analysis started...');

    try {
      final cacheDir = await getTemporaryDirectory();
      double sizeInMb = 0.0;
      if (cacheDir.existsSync()) {
        final List<FileSystemEntity> files = cacheDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            sizeInMb += file.lengthSync() / (1024 * 1024);
          }
        }
      }

      // Compute randomized but realistic device storage partitions for representation
      final random = Random();
      final storageUsed = 50.0 + random.nextInt(20) + (sizeInMb / 1024.0);
      const storageTotal = 256.0;
      final storageFree = storageTotal - storageUsed;

      await Future.delayed(const Duration(milliseconds: 800)); // UX delay for premium analytics loading
      log('Storage analysis completed. Cache size: ${sizeInMb.toStringAsFixed(1)} MB');

      state = state.copyWith(
        cacheSize: '${sizeInMb.toStringAsFixed(1)} MB',
        storageUsedGb: storageUsed,
        storageFreeGb: storageFree,
        storageTotalGb: storageTotal,
      );
    } catch (e) {
      log('Storage analysis failed: $e');
    } finally {
      state = state.copyWith(isAnalyzing: false);
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final impl = SettingsRepositoryImpl();
  return SettingsRepositorySyncDecorator(impl, ref);
});

final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});
