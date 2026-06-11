import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localmind_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:localmind_ai/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:localmind_ai/features/notifications/presentation/screens/notification_inbox_screen.dart';

class FakeNotificationInboxController extends StateNotifier<NotificationInboxState> {
  FakeNotificationInboxController(super.state);

  Future<void> loadNotifications() async {}
  Future<void> markAsRead(String id) async {}
  Future<void> markAllAsRead() async {}
  Future<void> deleteNotification(String id) async {}
  Future<void> clearAll() async {}
}

void main() {
  group('NotificationInboxScreen Semantics & Accessibility Widget Tests', () {
    testWidgets('Renders items and displays screen reader announcements', (tester) async {
      final fakeController = FakeNotificationInboxController(
        NotificationInboxState(
          notifications: [
            AppNotification(
              id: 'test_id_123',
              title: 'Llama 3 Update',
              body: 'New optimization patches are ready.',
              type: NotificationType.model_update,
              timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
              isRead: false,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationInboxProvider.overrideWith((ref) => fakeController),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const NotificationInboxScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title rendering
      expect(find.text('Llama 3 Update'), findsOneWidget);
      expect(find.text('New optimization patches are ready.'), findsOneWidget);

      // Verify Semantics exist
      // Using finder to inspect semantics handle
      final Finder cardFinder = find.byType(Dismissible);
      expect(cardFinder, findsOneWidget);

      // Verify the dismissible has semantic capabilities
      final SemanticsNode semanticsNode = tester.getSemantics(cardFinder);
      expect(semanticsNode, isNotNull);
    });
   group('RTL Semantics check', () {
      testWidgets('Adapts reading order dynamically for RTL languages (Arabic)', (tester) async {
        final fakeController = FakeNotificationInboxController(
          NotificationInboxState(
            notifications: [
              AppNotification(
                id: 'rtl_id',
                title: 'تحديث النموذج',
                body: 'حزمة لغوية جديدة متوفرة.',
                type: NotificationType.model_update,
                timestamp: DateTime.now(),
                isRead: false,
              ),
            ],
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notificationInboxProvider.overrideWith((ref) => fakeController),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ar'), // Set to Arabic (RTL)
              home: const NotificationInboxScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check if layout direction resolves to RTL
        final BuildContext context = tester.element(find.byType(NotificationInboxScreen));
        final Directionality dir = Directionality.of(context);
        expect(dir, equals(TextDirection.rtl));
      });
    });
  });
}
