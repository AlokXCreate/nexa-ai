import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:localmind_ai/features/notifications/domain/repositories/notification_repository.dart';
import 'package:localmind_ai/features/notifications/data/repositories/notification_repository_impl.dart';

class NotificationInboxState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationInboxState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationInboxState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationInboxState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationInboxController extends StateNotifier<NotificationInboxState> {
  final NotificationRepository _repository;

  NotificationInboxController(this._repository) : super(const NotificationInboxState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getNotifications();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      final updatedList = state.notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      state = state.copyWith(notifications: updatedList);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update notification: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      final updatedList = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updatedList);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update notifications: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      final updatedList = state.notifications.where((n) => n.id != id).toList();
      state = state.copyWith(notifications: updatedList);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete notification: $e');
    }
  }

  Future<void> clearAll() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.clearAll();
      state = state.copyWith(notifications: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to clear notification logs: $e');
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

final notificationInboxProvider =
    StateNotifierProvider<NotificationInboxController, NotificationInboxState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationInboxController(repo);
});
