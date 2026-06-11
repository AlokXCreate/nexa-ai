import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  static const String overridesBoxName = 'remoteConfigOverrides';

  RemoteConfigService(this._remoteConfig);

  Future<Box> _getOverridesBox() async {
    if (!Hive.isBoxOpen(overridesBoxName)) {
      return await Hive.openBox(overridesBoxName);
    }
    return Hive.box(overridesBoxName);
  }

  T _getValue<T>(String key, T defaultValue, T Function(String) remoteGetter) {
    if (Hive.isBoxOpen(overridesBoxName)) {
      final box = Hive.box(overridesBoxName);
      if (box.containsKey(key)) {
        return box.get(key) as T;
      }
    }
    try {
      return remoteGetter(key);
    } catch (_) {
      return defaultValue;
    }
  }

  bool get enableCloudInference => _getValue<bool>(
        'enable_cloud_inference',
        false,
        (k) => _remoteConfig.getBool(k),
      );

  bool get enableCommunityMarketplace => _getValue<bool>(
        'enable_community_marketplace',
        true,
        (k) => _remoteConfig.getBool(k),
      );

  bool get enableVoiceChat => _getValue<bool>(
        'enable_voice_chat',
        true,
        (k) => _remoteConfig.getBool(k),
      );

  String get modelMarketplaceVersion => _getValue<String>(
        'model_marketplace_version',
        '1.0.0',
        (k) => _remoteConfig.getString(k),
      );

  int get performanceOverlayRefreshMs => _getValue<int>(
        'performance_overlay_refresh_ms',
        500,
        (k) => _remoteConfig.getInt(k),
      );

  String get remoteAccentColor => _getValue<String>(
        'remote_accent_color',
        'purple',
        (k) => _remoteConfig.getString(k),
      );

  String get remoteThemeMode => _getValue<String>(
        'remote_theme_mode',
        'system',
        (k) => _remoteConfig.getString(k),
      );

  String get announcementBannerText => _getValue<String>(
        'announcement_banner_text',
        '',
        (k) => _remoteConfig.getString(k),
      );

  bool get announcementShow => _getValue<bool>(
        'announcement_show',
        false,
        (k) => _remoteConfig.getBool(k),
      );

  bool get isAppActive => _getValue<bool>(
        'is_app_active',
        true,
        (k) => _remoteConfig.getBool(k),
      );

  String get emergencyReason => _getValue<String>(
        'emergency_reason',
        'System maintenance in progress. Please check back later.',
        (k) => _remoteConfig.getString(k),
      );

  String get abTestChatLayout => _getValue<String>(
        'ab_test_chat_layout',
        'A',
        (k) => _remoteConfig.getString(k),
      );

  List<String> get experimentalFeatures => _getValue<String>(
        'experimental_features_list',
        '',
        (k) => _remoteConfig.getString(k),
      ).split(',').where((s) => s.isNotEmpty).toList();

  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {}
  }

  Future<void> setOverride(String key, dynamic value) async {
    final box = await _getOverridesBox();
    await box.put(key, value);
  }

  Future<void> removeOverride(String key) async {
    final box = await _getOverridesBox();
    await box.delete(key);
  }

  Future<void> clearAllOverrides() async {
    final box = await _getOverridesBox();
    await box.clear();
  }

  bool isFeatureActiveForUser(String userId, String featureKey, int rolloutPercent) {
    if (userId.isEmpty) return false;
    int hash = 0;
    for (int i = 0; i < userId.length; i++) {
      hash += userId.codeUnitAt(i);
    }
    final bucket = hash % 100;
    return bucket < rolloutPercent;
  }
}

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService(FirebaseRemoteConfig.instance);
});
