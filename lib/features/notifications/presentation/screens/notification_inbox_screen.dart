import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:localmind_ai/features/notifications/presentation/controllers/notification_controller.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationInboxProvider);
    final controller = ref.read(notificationInboxProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3),
            ),
          ),
        ),
        title: Text(
          'Notifications Inbox',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (state.notifications.any((n) => !n.isRead))
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 16, color: Colors.cyanAccent),
              label: const Text('Read All', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => controller.markAllAsRead(),
            ),
          IconButton(
            tooltip: 'Clear Inbox Log',
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            onPressed: () => _showClearConfirmation(context, controller),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF070416),
                    const Color(0xFF0F0726),
                    const Color(0xFF020105),
                  ]
                : [
                    const Color(0xFFF0F2FA),
                    const Color(0xFFF5F6FC),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => controller.loadNotifications(),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.notifications.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.notifications.length,
                        itemBuilder: (context, index) {
                          final notif = state.notifications[index];
                          return _buildNotificationCard(context, ref, notif);
                        },
                      ),
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, NotificationInboxController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F0E23) : Colors.white,
        title: Text('Clear Inbox Logs?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        content: Text(
          'This will permanently delete all notification messages from your local inbox database.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              controller.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear Inbox'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Inbox is Clear',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'We will alert you when system updates occur.',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, AppNotification notif) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = _getNotificationConfig(notif.type);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final captionTextColor = isDark ? Colors.white38 : Colors.black38;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        ref.read(notificationInboxProvider.notifier).deleteNotification(notif.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(notificationInboxProvider.notifier).markAsRead(notif.id);
            _handleNotificationNavigation(context, notif);
          },
          child: GlassContainer(
            borderRadius: 16,
            blur: 10,
            color: notif.isRead 
                ? (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)) 
                : (isDark ? Colors.cyanAccent.withOpacity(0.04) : Colors.cyan.withOpacity(0.08)),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(config.icon, color: config.color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: GoogleFonts.outfit(
                                fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 13,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.cyanAccent : Colors.cyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(notif.timestamp),
                        style: TextStyle(color: captionTextColor, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _NotificationTypeConfig _getNotificationConfig(NotificationType type) {
    switch (type) {
      case NotificationType.model_update:
        return _NotificationTypeConfig(Icons.cloud_sync_rounded, Colors.purpleAccent);
      case NotificationType.plugin_update:
        return _NotificationTypeConfig(Icons.extension_rounded, Colors.pinkAccent);
      case NotificationType.download_complete:
        return _NotificationTypeConfig(Icons.download_done_rounded, Colors.greenAccent);
      case NotificationType.backup_reminder:
        return _NotificationTypeConfig(Icons.backup_rounded, Colors.blueAccent);
      case NotificationType.weekly_report:
        return _NotificationTypeConfig(Icons.analytics_rounded, Colors.cyanAccent);
      case NotificationType.storage_warning:
        return _NotificationTypeConfig(Icons.storage_rounded, Colors.redAccent);
      case NotificationType.new_model_recommended:
        return _NotificationTypeConfig(Icons.recommend_rounded, Colors.amberAccent);
      case NotificationType.trending_models:
        return _NotificationTypeConfig(Icons.trending_up_rounded, Colors.orangeAccent);
    }
  }

  String _formatTimestamp(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    }
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _handleNotificationNavigation(BuildContext context, AppNotification notif) {
    switch (notif.type) {
      case NotificationType.backup_reminder:
        context.push('/backup');
        break;
      case NotificationType.download_complete:
        context.push('/installed-models');
        break;
      case NotificationType.new_model_recommended:
      case NotificationType.trending_models:
        final modelId = notif.payload['modelId'] as String?;
        if (modelId != null) {
          context.push('/marketplace/model-details/$modelId');
        } else {
          context.push('/marketplace');
        }
        break;
      case NotificationType.weekly_report:
        context.push('/analytics');
        break;
      default:
        // Do nothing, just close card
        break;
    }
  }
}

class _NotificationTypeConfig {
  final IconData icon;
  final Color color;
  const _NotificationTypeConfig(this.icon, this.color);
}
