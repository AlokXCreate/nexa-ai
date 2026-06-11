import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/navigation/app_router.dart';
import 'package:localmind_ai/core/services/remote_config_service.dart';
import 'package:localmind_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';
import 'package:localmind_ai/features/auth/domain/entities/user_model.dart';
import 'package:localmind_ai/features/developer/presentation/screens/emergency_screen.dart';

class FakeRemoteConfigService extends Fake implements RemoteConfigService {
  bool _isAppActive = true;
  
  @override
  bool get isAppActive => _isAppActive;
  
  @override
  String get emergencyReason => 'Scheduled maintenance in progress.';
  
  void setAppActive(bool active) {
    _isAppActive = active;
  }
}

class FakeSecurityState extends Fake implements SecurityState {
  @override
  bool get isAppLocked => false;
}

void main() {
  group('GoRouter & Redirection Integration Tests', () {
    late FakeRemoteConfigService fakeRemoteConfig;

    setUp(() {
      fakeRemoteConfig = FakeRemoteConfigService();
    });

    testWidgets('App functions normally when active', (tester) async {
      fakeRemoteConfig.setAppActive(true);

      final container = ProviderContainer(
        overrides: [
          remoteConfigServiceProvider.overrideWith((ref) => fakeRemoteConfig),
          authStateChangesProvider.overrideWith((ref) => const AsyncValue.data(
            UserModel(
              uid: 'user_123',
              email: 'test@example.com',
              isEmailVerified: true,
              isGuest: false,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(appRouterProvider),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify it did not redirect to EmergencyScreen
      expect(find.byType(EmergencyScreen), findsNothing);
    });

    testWidgets('App redirects and locks to /emergency when app active is false', (tester) async {
      fakeRemoteConfig.setAppActive(false);

      final container = ProviderContainer(
        overrides: [
          remoteConfigServiceProvider.overrideWith((ref) => fakeRemoteConfig),
          authStateChangesProvider.overrideWith((ref) => const AsyncValue.data(
            UserModel(
              uid: 'user_123',
              email: 'test@example.com',
              isEmailVerified: true,
              isGuest: false,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(appRouterProvider),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify it successfully intercepted navigation and loaded EmergencyScreen
      expect(find.byType(EmergencyScreen), findsOneWidget);
      expect(find.text('Scheduled maintenance in progress.'), findsOneWidget);
    });
  });
}
