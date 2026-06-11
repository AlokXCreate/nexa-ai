import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> logModelDownloadStarted(String modelId, String modelName) async {
    await logEvent('model_download_started', parameters: {
      'model_id': modelId,
      'model_name': modelName,
    });
  }

  Future<void> logModelDownloadCompleted(String modelId, String modelName, int sizeBytes) async {
    await logEvent('model_download_completed', parameters: {
      'model_id': modelId,
      'model_name': modelName,
      'size_bytes': sizeBytes,
    });
  }

  Future<void> logChatSessionCreated(String sessionId, String modelId) async {
    await logEvent('chat_session_created', parameters: {
      'session_id': sessionId,
      'model_id': modelId,
    });
  }

  Future<void> logSecurityPinSetup() async {
    await logEvent('security_pin_setup');
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(FirebaseAnalytics.instance);
});
