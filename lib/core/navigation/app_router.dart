import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:localmind_ai/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:localmind_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:localmind_ai/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:localmind_ai/features/auth/presentation/screens/register_screen.dart';
import 'package:localmind_ai/features/auth/presentation/screens/splash_screen.dart';
import 'package:localmind_ai/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:localmind_ai/features/dashboard/presentation/screens/dashboard_shell.dart';
import 'package:localmind_ai/features/home/presentation/screens/home_screen.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/screens/marketplace_screen.dart';
import 'package:localmind_ai/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:localmind_ai/features/chat/presentation/screens/knowledge_base_screen.dart';
import 'package:localmind_ai/features/chat/presentation/screens/multi_model_chat_screen.dart';
import 'package:localmind_ai/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:localmind_ai/features/profile/presentation/screens/profile_screen.dart';
import 'package:localmind_ai/features/settings/presentation/screens/backup_screen.dart';
import 'package:localmind_ai/features/agents/presentation/screens/agents_dashboard_screen.dart';
import 'package:localmind_ai/features/agents/presentation/screens/agent_chat_screen.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/screens/installed_models_screen.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/screens/model_details_screen.dart';
import 'package:localmind_ai/features/search/presentation/screens/search_screen.dart';
import 'package:localmind_ai/features/plugins/presentation/screens/plugins_marketplace_screen.dart';
import 'package:localmind_ai/features/plugins/presentation/screens/cloud_settings_screen.dart';
import 'package:localmind_ai/features/developer/presentation/screens/developer_dashboard_screen.dart';
import 'package:localmind_ai/features/developer/presentation/screens/analytics_dashboard_screen.dart';
import 'package:localmind_ai/features/benchmark/presentation/screens/benchmark_center_screen.dart';
import 'package:localmind_ai/features/optimizer/presentation/screens/device_optimizer_screen.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';
import 'package:localmind_ai/features/security/presentation/screens/security_center_screen.dart';
import 'package:localmind_ai/features/security/presentation/screens/pin_gate_screen.dart';
import 'package:localmind_ai/features/community/presentation/screens/community_marketplace_screen.dart';
import 'package:localmind_ai/features/community/presentation/screens/upload_model_screen.dart';
import 'package:localmind_ai/features/community/presentation/screens/collection_details_screen.dart';
import 'package:localmind_ai/features/community/presentation/screens/developer_details_screen.dart';
import 'package:localmind_ai/features/notifications/presentation/screens/notification_inbox_screen.dart';
import 'package:localmind_ai/features/developer/presentation/screens/remote_config_admin_screen.dart';
import 'package:localmind_ai/features/developer/presentation/screens/emergency_screen.dart';
import 'package:localmind_ai/core/services/remote_config_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();
final _marketNavigatorKey = GlobalKey<NavigatorState>();
final _chatNavigatorKey = GlobalKey<NavigatorState>();
final _knowledgeNavigatorKey = GlobalKey<NavigatorState>();
final _downloadNavigatorKey = GlobalKey<NavigatorState>();
final _profileNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final securityState = ref.watch(securityControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/installed-models',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InstalledModelsScreen(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/multi-model-compare',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MultiModelChatScreen(),
      ),
      GoRoute(
        path: '/backup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: '/agents',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AgentsDashboardScreen(),
      ),
      GoRoute(
        path: '/agent-chat/:agentId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final agentId = state.pathParameters['agentId']!;
          return AgentChatScreen(agentId: agentId);
        },
      ),
      GoRoute(
        path: '/plugins',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PluginsMarketplaceScreen(),
      ),
      GoRoute(
        path: '/cloud-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CloudSettingsScreen(),
      ),
      GoRoute(
        path: '/developer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeveloperDashboardScreen(),
      ),
      GoRoute(
        path: '/analytics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: '/benchmark',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BenchmarkCenterScreen(),
      ),
      GoRoute(
        path: '/optimizer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeviceOptimizerScreen(),
      ),
      GoRoute(
        path: '/security',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SecurityCenterScreen(),
      ),
      GoRoute(
        path: '/pin-gate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PinGateScreen(),
      ),
      GoRoute(
        path: '/community',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommunityMarketplaceScreen(),
      ),
      GoRoute(
        path: '/community/upload',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UploadModelScreen(),
      ),
      GoRoute(
        path: '/community/collection/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CollectionDetailsScreen(collectionId: id);
        },
      ),
      GoRoute(
        path: '/community/developer/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DeveloperDetailsScreen(developerId: id);
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationInboxScreen(),
      ),
      GoRoute(
        path: '/developer/remote-config',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RemoteConfigAdminScreen(),
      ),
      GoRoute(
        path: '/emergency',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmergencyScreen(),
      ),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _marketNavigatorKey,
            routes: [
              GoRoute(
                path: '/marketplace',
                builder: (context, state) => const MarketplaceScreen(),
                routes: [
                  GoRoute(
                    path: 'model-details/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ModelDetailsScreen(modelId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _chatNavigatorKey,
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _knowledgeNavigatorKey,
            routes: [
              GoRoute(
                path: '/knowledge-base',
                builder: (context, state) => const KnowledgeBaseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _downloadNavigatorKey,
            routes: [
              GoRoute(
                path: '/downloads',
                builder: (context, state) => const DownloadsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isAppActive = ref.read(remoteConfigServiceProvider).isAppActive;
      if (!isAppActive) {
        if (state.matchedLocation != '/emergency') {
          return '/emergency';
        }
        return null;
      }
      if (state.matchedLocation == '/emergency') {
        return '/';
      }

      if (authState.isLoading) return null;

      final user = authState.value;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/splash';

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        if (!user.isEmailVerified && !user.isGuest) {
          return '/verify-email';
        }
        if (securityState.isAppLocked) {
          return '/pin-gate';
        }
        return '/';
      }

      if (!user.isEmailVerified && !user.isGuest && state.matchedLocation != '/verify-email') {
        return '/verify-email';
      }

      // App Lock Gate: If PIN lock is active and app is locked, force to pin-gate
      if (securityState.isAppLocked && state.matchedLocation != '/pin-gate') {
        return '/pin-gate';
      }

      return null;
    },
  );
});
