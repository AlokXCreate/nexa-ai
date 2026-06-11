import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseAnalytics analytics;
  late final FirebaseRemoteConfig remoteConfig;

  Future<void> init() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp();

      // Initialize Crashlytics
      if (!kIsWeb) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        // Enable Crashlytics collection in production/staging
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      }

      // Initialize Analytics
      analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(!kDebugMode);

      // Initialize Remote Config
      remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 12),
      ));
      
      // Set defaults for Remote Config
      await remoteConfig.setDefaults(const {
        'enable_cloud_inference': false,
        'model_marketplace_version': '1.0.0',
        'performance_overlay_refresh_ms': 500,
      });

      await remoteConfig.fetchAndActivate();
    } catch (e, stack) {
      debugPrint('Firebase initialization failed: $e');
      if (!kDebugMode && !kIsWeb) {
        try {
          await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Firebase Init Error');
        } catch (_) {}
      }
    }
  }
}
