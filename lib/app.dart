import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/navigation/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localmind_ai/core/theme/app_theme.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/backup_controller.dart';
import 'package:localmind_ai/core/services/notification_service.dart';

class LocalMindApp extends ConsumerWidget {
  const LocalMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final settings = settingsState.settings;

    // Trigger automatic scheduled backup check and notification init on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider);
      ref.read(backupServiceProvider).runAutomaticScheduledBackup();
    });

    final lightTheme = AppTheme.getThemeData(settings, Brightness.light);
    final darkTheme = AppTheme.getThemeData(settings, Brightness.dark);

    ThemeMode themeMode;
    switch (settings.themeMode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'LocalMind AI',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(settings.languageCode),
    );
  }
}
