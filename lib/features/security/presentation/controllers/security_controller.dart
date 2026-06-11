import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/security/domain/entities/security_config.dart';
import 'package:localmind_ai/features/security/data/services/security_service.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_sessions_controller.dart';
import 'package:localmind_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:localmind_ai/features/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:path_provider/path_provider.dart';

class SecurityState {
  final SecurityConfig config;
  final double securityScore;
  final bool isAppLocked;
  final bool isAuthedForPrivateChats;
  final Map<String, String> permissions;
  final bool isLoading;
  final String? error;
  final String? lastBackupPath;

  const SecurityState({
    required this.config,
    this.securityScore = 0.0,
    this.isAppLocked = false,
    this.isAuthedForPrivateChats = false,
    this.permissions = const {},
    this.isLoading = false,
    this.error,
    this.lastBackupPath,
  });

  SecurityState copyWith({
    SecurityConfig? config,
    double? securityScore,
    bool? isAppLocked,
    bool? isAuthedForPrivateChats,
    Map<String, String>? permissions,
    bool? isLoading,
    String? error,
    String? lastBackupPath,
    bool clearError = false,
    bool clearBackupPath = false,
  }) {
    return SecurityState(
      config: config ?? this.config,
      securityScore: securityScore ?? this.securityScore,
      isAppLocked: isAppLocked ?? this.isAppLocked,
      isAuthedForPrivateChats: isAuthedForPrivateChats ?? this.isAuthedForPrivateChats,
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastBackupPath: clearBackupPath ? null : (lastBackupPath ?? this.lastBackupPath),
    );
  }
}

class SecurityController extends StateNotifier<SecurityState> {
  final SecurityService _service = SecurityService();
  final Ref _ref;
  static const String boxName = 'securityBox';

  SecurityController(this._ref) : super(SecurityState(config: SecurityConfig.defaultConfig())) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final box = await Hive.openBox(boxName);
      final savedConfigMap = box.get('config');
      SecurityConfig config;
      
      if (savedConfigMap is Map) {
        config = SecurityConfig.fromMap(savedConfigMap);
      } else {
        config = SecurityConfig.defaultConfig();
      }

      state = state.copyWith(
        config: config,
        isAppLocked: config.isPinEnabled, // Lock app on launch if PIN enabled
        isLoading: false,
      );
      
      await loadPermissions();
      _computeSecurityScore();
    } catch (e) {
      state = state.copyWith(
        config: SecurityConfig.defaultConfig(),
        isLoading: false,
        error: 'Failed to initialize security configs: $e',
      );
    }
  }

  void _computeSecurityScore() {
    double score = 0.0;
    final cfg = state.config;

    // PIN Lock: +25
    if (cfg.isPinEnabled) score += 25.0;
    // Biometric Lock: +25
    if (cfg.isBiometricEnabled) score += 25.0;
    // Incognito Mode Active: +15
    if (cfg.isIncognitoActive) score += 15.0;
    // Private Chats Configured: +15
    if (cfg.privateSessionIds.isNotEmpty) score += 15.0;
    // Standard Local Encryption Active: +20
    score += 20.0;

    state = state.copyWith(securityScore: score);
  }

  Future<void> _saveConfig(SecurityConfig config) async {
    final box = Hive.box(boxName);
    await box.put('config', config.toMap());
    state = state.copyWith(config: config);
    _computeSecurityScore();
  }

  Future<void> toggleBiometrics(bool enabled) async {
    final updated = state.config.copyWith(isBiometricEnabled: enabled);
    await _saveConfig(updated);
  }

  Future<void> setPinCode(String pin) async {
    final obfuscated = _service.encryptPin(pin);
    final updated = state.config.copyWith(
      isPinEnabled: true,
      pinCodeObfuscated: obfuscated,
    );
    await _saveConfig(updated);
  }

  Future<void> disablePin() async {
    final updated = state.config.copyWith(
      isPinEnabled: false,
      pinCodeObfuscated: '',
    );
    await _saveConfig(updated);
  }

  bool verifyPin(String inputPin) {
    final verified = _service.verifyPin(inputPin, state.config.pinCodeObfuscated);
    if (verified) {
      state = state.copyWith(
        isAppLocked: false,
        isAuthedForPrivateChats: true,
      );
    }
    return verified;
  }

  void lockApp() {
    if (state.config.isPinEnabled) {
      state = state.copyWith(
        isAppLocked: true,
        isAuthedForPrivateChats: false,
      );
    }
  }

  void resetPrivateChatAuth() {
    state = state.copyWith(isAuthedForPrivateChats: false);
  }

  Future<void> toggleIncognitoMode(bool active) async {
    final updated = state.config.copyWith(isIncognitoActive: active);
    await _saveConfig(updated);
  }

  Future<void> toggleSessionPrivacy(String sessionId, bool isPrivate) async {
    final currentList = List<String>.from(state.config.privateSessionIds);
    if (isPrivate) {
      if (!currentList.contains(sessionId)) {
        currentList.add(sessionId);
      }
    } else {
      currentList.remove(sessionId);
    }
    final updated = state.config.copyWith(privateSessionIds: currentList);
    await _saveConfig(updated);
  }

  bool isSessionPrivate(String sessionId) {
    return state.config.privateSessionIds.contains(sessionId);
  }

  Future<void> loadPermissions() async {
    final perms = await _service.checkPermissions();
    state = state.copyWith(permissions: perms);
  }

  Future<void> requestPermission(String name) async {
    await _service.requestPermission(name);
    await loadPermissions();
  }

  Future<void> purgeAllData() async {
    state = state.copyWith(isLoading: true);
    final settings = _ref.read(settingsControllerProvider).settings;
    await _service.purgeAllAppData(settings.downloadLocation);
    
    final updated = SecurityConfig.defaultConfig();
    await _saveConfig(updated);
    
    state = state.copyWith(
      isAppLocked: false,
      isAuthedForPrivateChats: false,
      isLoading: false,
    );
  }

  Future<String?> exportEncryptedBackup(String password) async {
    state = state.copyWith(clearBackupPath: true, isLoading: true);
    try {
      // 1. Gather all local configuration data maps
      final settingsMap = _ref.read(settingsControllerProvider).settings.toMap();
      
      final sessionsState = _ref.read(chatSessionsControllerProvider);
      final sessionsList = sessionsState.sessions.map((s) => s.toMap()).toList();
      
      final benchmarkState = _ref.read(benchmarkControllerProvider);
      final benchmarksList = benchmarkState.results.map((r) => r.toMap()).toList();

      final payload = {
        'settings': settingsMap,
        'sessions': sessionsList,
        'benchmarks': benchmarksList,
        'security': state.config.toMap(),
      };

      final plainJson = jsonEncode(payload);
      final encryptedBase64 = _service.encryptBackup(plainJson, password);

      // 2. Write to download location
      final settings = _ref.read(settingsControllerProvider).settings;
      String dirPath = settings.downloadLocation;
      if (dirPath.isEmpty || dirPath == '/localmind/models') {
        final appDir = await getApplicationDocumentsDirectory();
        dirPath = '${appDir.path}/localmind/exports';
      }

      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('$dirPath/nexa_secure_backup_${DateTime.now().millisecondsSinceEpoch}.nexa');
      await file.writeAsString(encryptedBase64);
      
      state = state.copyWith(
        lastBackupPath: file.path,
        isLoading: false,
      );
      return file.path;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create encrypted backup: $e',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final securityControllerProvider = StateNotifierProvider<SecurityController, SecurityState>((ref) {
  return SecurityController(ref);
});
