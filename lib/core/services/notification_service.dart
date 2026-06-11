import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:localmind_ai/features/notifications/domain/repositories/notification_repository.dart';
import 'package:localmind_ai/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:localmind_ai/features/downloads/presentation/controllers/downloads_controller.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  late final Ref _ref;
  bool _initialized = false;
  
  ProviderSubscription<DownloadsState>? _downloadsSub;
  Timer? _smartChecksTimer;

  Future<void> init(Ref ref) async {
    if (_initialized) return;
    _ref = ref;
    _initialized = true;

    // Request permissions
    try {
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (_) {}

    // Local notifications setup
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: initSettingsAndroid, iOS: initSettingsIOS);
    
    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Handle notification tap actions
        },
      );
    } catch (_) {}

    // Foreground FCM listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Nexa AI Alert';
      final body = message.notification?.body ?? '';
      _showLocalNotification(
        message.messageId.hashCode,
        title,
        body,
      );
      
      _saveFcmToInbox(message);
    });

    // Start background checks
    _setupDownloadProgressListener();
    _startSmartChecks();
  }

  void dispose() {
    _downloadsSub?.close();
    _smartChecksTimer?.cancel();
  }

  void _setupDownloadProgressListener() {
    final Set<String> completedIds = {};
    _downloadsSub = _ref.listen<DownloadsState>(
      downloadsControllerProvider,
      (previous, current) {
        for (final task in current.queue) {
          if (task.status == DownloadStatus.completed && !completedIds.contains(task.id)) {
            completedIds.add(task.id);
            _triggerNotification(
              title: 'Download Completed',
              body: 'Model ${task.modelName} has finished downloading and is ready for offline execution.',
              type: NotificationType.download_complete,
              payload: {'modelId': task.id},
            );
          }
        }
      },
    );
  }

  void _startSmartChecks() {
    // Check once on init and schedule periodic scans every 4 hours
    _runSmartChecks();
    _smartChecksTimer = Timer.periodic(const Duration(hours: 4), (timer) {
      _runSmartChecks();
    });
  }

  Future<void> _runSmartChecks() async {
    try {
      // 1. Storage Warning check
      final settingsState = _ref.read(settingsControllerProvider);
      if (settingsState.storageFreeGb > 0 && settingsState.storageFreeGb < 20.0) {
        _triggerNotification(
          title: 'Low Disk Storage Warning',
          body: 'Your device has only ${settingsState.storageFreeGb.toStringAsFixed(1)} GB of free space remaining. Recommended to prune installed models.',
          type: NotificationType.storage_warning,
        );
      }

      // 2. Backup Reminder check
      final securityState = _ref.read(securityControllerProvider);
      if (securityState.lastBackupPath == null || securityState.lastBackupPath!.isEmpty) {
        _triggerNotification(
          title: 'Secure Backup Recommended',
          body: 'You haven\'t created an encrypted local backup of your conversation history yet. Go to Backup settings to secure your data.',
          type: NotificationType.backup_reminder,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveFcmToInbox(RemoteMessage message) async {
    final payload = Map<String, dynamic>.from(message.data);
    final typeStr = payload['type'] as String?;
    final type = NotificationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => NotificationType.model_update,
    );

    final notification = AppNotification(
      id: message.messageId ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      title: message.notification?.title ?? 'Remote Alert',
      body: message.notification?.body ?? '',
      type: type,
      payload: payload,
      timestamp: DateTime.now(),
    );

    await _ref.read(notificationRepositoryProvider).saveNotification(notification);
    _ref.read(notificationInboxProvider.notifier).loadNotifications();
  }

  Future<void> _triggerNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic> payload = const {},
  }) async {
    final notification = AppNotification(
      id: 'notif_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      payload: payload,
      timestamp: DateTime.now(),
    );

    await _ref.read(notificationRepositoryProvider).saveNotification(notification);
    _ref.read(notificationInboxProvider.notifier).loadNotifications();

    await _showLocalNotification(
      notification.id.hashCode,
      title,
      body,
    );
  }

  Future<void> _showLocalNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'nexa_channel_id',
      'Nexa Core Notifications',
      channelDescription: 'System warnings and local model updates.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    try {
      await _localNotifications.show(id, title, body, platformDetails);
    } catch (_) {}
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.init(ref);
  return service;
});
