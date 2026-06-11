import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:localmind_ai/core/services/remote_config_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _downloadLocController = TextEditingController();
  bool _isAppearanceExpanded = true;
  bool _isAiSettingsExpanded = false;
  bool _isDevSettingsExpanded = false;
  bool _isStorageExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initialize text controller with current download location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsControllerProvider).settings;
      _downloadLocController.text = settings.downloadLocation;
    });
  }

  @override
  void dispose() {
    _downloadLocController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(settingsControllerProvider);
    final settings = state.settings;
    final installedModelsState = ref.watch(installedModelsControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(l10n.settings, style: AppTypography.titleMedium),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              primaryColor.withOpacity(0.08),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            center: const Alignment(-0.6, -0.6),
            radius: 1.5,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(
            top: kToolbarHeight + 40,
            bottom: 120,
            left: 16,
            right: 16,
          ),
          children: [
            // User Header Profile Card
            _buildProfileHeader(ref),
            const SizedBox(height: 12),

            // Announcement Banner from Remote Config
            Consumer(
              builder: (context, ref, child) {
                final service = ref.watch(remoteConfigServiceProvider);
                if (!service.announcementShow || service.announcementBannerText.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    borderRadius: 16,
                    blur: 10,
                    color: Colors.amberAccent.withOpacity(0.12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded, color: Colors.amberAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            service.announcementBannerText,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // 1. Appearance & Customization Section
            _buildExpandableSection(
              title: 'Appearance & Customization',
              icon: Icons.palette_outlined,
              isExpanded: _isAppearanceExpanded,
              onToggle: () => setState(() => _isAppearanceExpanded = !_isAppearanceExpanded),
              child: Column(
                children: [
                  _buildThemeSelector(settings),
                  const SizedBox(height: 16),
                  _buildAccentColorPicker(settings),
                  const SizedBox(height: 16),
                  _buildFontSizeSelector(settings),
                  const SizedBox(height: 16),
                  _buildAnimationSpeedSelector(settings),
                  const Divider(height: 24),
                  _buildLanguageSelector(settings, l10n),
                  const Divider(height: 24),
                  _buildHighContrastToggle(settings, l10n),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. AI Settings Section
            _buildExpandableSection(
              title: 'Local AI Settings',
              icon: Icons.psychology_outlined,
              isExpanded: _isAiSettingsExpanded,
              onToggle: () => setState(() => _isAiSettingsExpanded = !_isAiSettingsExpanded),
              child: Column(
                children: [
                  _buildDefaultModelSelector(settings, installedModelsState),
                  const SizedBox(height: 16),
                  _buildContextSizeSelector(settings),
                  const SizedBox(height: 16),
                  _buildInferenceModeSelector(settings),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Developer Console Section
            _buildExpandableSection(
              title: l10n.developerConsole,
              icon: Icons.developer_mode_outlined,
              isExpanded: _isDevSettingsExpanded,
              onToggle: () => setState(() => _isDevSettingsExpanded = !_isDevSettingsExpanded),
              child: Column(
                children: [
                  _buildToggleTile(
                    title: 'Performance Monitor Overlay',
                    subtitle: 'Show live inference speeds & RAM metrics',
                    value: settings.showPerformanceMonitor,
                    onChanged: (val) => ref.read(settingsControllerProvider.notifier).togglePerformanceMonitor(val),
                  ),
                  const Divider(height: 24),
                  _buildToggleTile(
                    title: 'Enable Debug Logger',
                    subtitle: 'Record system transactions in memory',
                    value: settings.enableDebugLogs,
                    onChanged: (val) => ref.read(settingsControllerProvider.notifier).toggleDebugLogs(val),
                  ),
                  const Divider(height: 24),
                  _buildToggleTile(
                    title: 'Token Counter Indicators',
                    subtitle: 'Display length indicators under messages',
                    value: settings.showTokenCounter,
                    onChanged: (val) => ref.read(settingsControllerProvider.notifier).toggleTokenCounter(val),
                  ),
                  if (settings.enableDebugLogs) ...[
                    const SizedBox(height: 16),
                    _buildDebugLogConsole(state),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Storage Analyzer & Settings Section
            _buildExpandableSection(
              title: 'Storage & Cache Settings',
              icon: Icons.storage_outlined,
              isExpanded: _isStorageExpanded,
              onToggle: () => setState(() => _isStorageExpanded = !_isStorageExpanded),
              child: Column(
                children: [
                  _buildDownloadLocationInput(settings),
                  const Divider(height: 24),
                  _buildCacheCleaner(state),
                  const Divider(height: 24),
                  _buildStorageAnalyzer(state),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Backup & Recovery Section
            GestureDetector(
              onTap: () => context.push('/backup'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.backup_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.backupRecovery,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            // 5.5. Community Marketplace Section
            GestureDetector(
              onTap: () => context.push('/community'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.people_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.community,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 5.6. Notifications Section
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.notifications_none_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.notificationInbox,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final unreadCount = ref.watch(notificationInboxProvider).unreadCount;
                        if (unreadCount == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 6. Plugin Marketplace Section
            GestureDetector(
              onTap: () => context.push('/plugins'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.extension_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Plugin Marketplace',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 6.5. Cloud Integrations Section
            GestureDetector(
              onTap: () => context.push('/cloud-settings'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cloud AI Integrations',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 7. Performance Analytics Section
            GestureDetector(
              onTap: () => context.push('/analytics'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Performance Analytics',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 7.5. Benchmark Center Section
            GestureDetector(
              onTap: () => context.push('/benchmark'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Benchmark Center',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 7.6. AI Device Optimizer Section
            GestureDetector(
              onTap: () => context.push('/optimizer'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.build_circle_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI Device Optimizer',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 7.7. Security & Privacy Center Section
            GestureDetector(
              onTap: () => context.push('/security'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.security_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Security & Privacy Center',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 7.8. Remote Config Overrides Section
            GestureDetector(
              onTap: () => context.push('/developer/remote-config'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.settings_suggest_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Remote Config Overrides',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 8. Developer Console Section
            GestureDetector(
              onTap: () => context.push('/developer'),
              child: GlassContainer(
                borderRadius: 16,
                blur: 5,
                color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.terminal_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.developerConsole,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            PremiumButton(
              label: l10n.signOut,
              icon: Icons.logout_rounded,
              isSecondary: true,
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: Theme.of(context).cardTheme.color!.withOpacity(0.5),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Icon(Icons.person_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.isGuest == true ? 'Guest User' : (user?.email ?? 'AI Explorer'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  user?.isGuest == true ? 'Offline Sandbox Mode' : 'LocalMind Account',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: GlassContainer(
            borderRadius: 16,
            blur: 5,
            color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color!.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerTheme.color!.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: child,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.themeMode,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildThemeOption('system', 'System', Icons.settings_brightness_rounded, settings.themeMode),
            const SizedBox(width: 8),
            _buildThemeOption('light', 'Light', Icons.wb_sunny_rounded, settings.themeMode),
            const SizedBox(width: 8),
            _buildThemeOption('dark', 'Dark', Icons.brightness_2_rounded, settings.themeMode),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(String modeValue, String label, IconData icon, String activeMode) {
    final isSelected = activeMode == modeValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(settingsControllerProvider.notifier).updateThemeMode(modeValue),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : (isDark ? Colors.white54.withOpacity(0.04) : Colors.black12.withOpacity(0.04)),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccentColorPicker(AppSettings settings) {
    final colors = {
      'purple': const Color(0xFF6C63FF),
      'cyan': const Color(0xFF00D4FF),
      'emerald': const Color(0xFF10B981),
      'amber': const Color(0xFFF59E0B),
      'rose': const Color(0xFFF43F5E),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.accentColor,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: colors.entries.map((entry) {
            final isSelected = settings.accentColor == entry.key;
            return GestureDetector(
              onTap: () => ref.read(settingsControllerProvider.notifier).updateAccentColor(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.value,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: entry.value.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontSizeSelector(AppSettings settings) {
    final sizes = ['small', 'medium', 'large'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.fontSize,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: sizes.map((size) {
            final isSelected = settings.fontSize == size;
            return Expanded(
              child: GestureDetector(
                onTap: () => ref.read(settingsControllerProvider.notifier).updateFontSize(size),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      size.toUpperCase(),
                      style: TextStyle(
                        fontSize: size == 'small' ? 10 : (size == 'medium' ? 12 : 14),
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnimationSpeedSelector(AppSettings settings) {
    final speeds = ['slow', 'normal', 'fast'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interface Transition Speed',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: speeds.map((speed) {
            final isSelected = settings.animationSpeed == speed;
            return Expanded(
              child: GestureDetector(
                onTap: () => ref.read(settingsControllerProvider.notifier).updateAnimationSpeed(speed),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      speed.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDefaultModelSelector(AppSettings settings, InstalledModelsState installedState) {
    final installed = installedState.installedModels;
    final activeId = settings.defaultModelId;
    final isSelectedValid = installed.any((m) => m.id == activeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Default Model',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: isSelectedValid ? activeId : null,
              hint: const Text('Auto-select active', style: TextStyle(color: Colors.grey, fontSize: 13)),
              dropdownColor: Theme.of(context).cardTheme.color,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Auto-Select Last Used', style: TextStyle(fontSize: 13)),
                ),
                ...installed.map((model) => DropdownMenuItem<String?>(
                      value: model.id,
                      child: Text(model.localName, style: const TextStyle(fontSize: 13)),
                    )),
              ],
              onChanged: (val) => ref.read(settingsControllerProvider.notifier).updateDefaultModelId(val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextSizeSelector(AppSettings settings) {
    final sizes = [1024, 2048, 4096, 8192];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maximum Context Size',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: sizes.map((size) {
            final isSelected = settings.maxContextSize == size;
            return Expanded(
              child: GestureDetector(
                onTap: () => ref.read(settingsControllerProvider.notifier).updateMaxContextSize(size),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${(size / 1024).round()}K',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInferenceModeSelector(AppSettings settings) {
    final modes = ['auto', 'cpu', 'gpu'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inference Engine Mode',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: modes.map((mode) {
            final isSelected = settings.inferenceMode == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => ref.read(settingsControllerProvider.notifier).updateInferenceMode(mode),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      mode.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      value: value,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildDebugLogConsole(SettingsState state) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DEBUG LOGS',
                  style: GoogleFonts.shareTechMono(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => ref.read(settingsControllerProvider.notifier).clearLogs(),
                  child: const Text('CLEAR', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.debugLogs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    state.debugLogs[index],
                    style: GoogleFonts.shareTechMono(color: Colors.greenAccent, fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadLocationInput(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Model Download Directory',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _downloadLocController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.save_rounded, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                final location = _downloadLocController.text.trim();
                ref.read(settingsControllerProvider.notifier).updateDownloadLocation(location);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download directory updated!'), duration: Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCacheCleaner(SettingsState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cache cleaner', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Temporary file space: ${state.cacheSize}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        SizedBox(
          height: 36,
          child: PremiumButton(
            label: state.isCleaning ? 'Cleaning...' : 'Clear Cache',
            isLoading: state.isCleaning,
            onPressed: () => ref.read(settingsControllerProvider.notifier).cleanCache(),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageAnalyzer(SettingsState state) {
    final usedFraction = state.storageTotalGb > 0 ? state.storageUsedGb / state.storageTotalGb : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Storage Analyzer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: state.isAnalyzing ? null : () => ref.read(settingsControllerProvider.notifier).analyzeStorage(),
              child: Icon(
                Icons.refresh_rounded, 
                size: 18, 
                color: state.isAnalyzing ? Colors.grey : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: usedFraction,
            minHeight: 8,
            backgroundColor: Colors.grey.withOpacity(0.2),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Used: ${state.storageUsedGb.toStringAsFixed(1)} GB',
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            Text(
              'Free: ${state.storageFreeGb.toStringAsFixed(1)} GB',
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total: ${state.storageTotalGb.toStringAsFixed(0)} GB',
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(AppSettings settings, AppLocalizations l10n) {
    final languages = {
      'en': 'English',
      'hi': 'हिन्दी (Hindi)',
      'es': 'Español (Spanish)',
      'fr': 'Français (French)',
      'de': 'Deutsch (German)',
      'ja': '日本語 (Japanese)',
      'ko': '한국어 (Korean)',
      'zh': '中文 (Chinese)',
      'ar': 'العربية (Arabic)',
      'pt': 'Português (Portuguese)',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.language,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              languages[settings.languageCode] ?? 'English',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        DropdownButton<String>(
          value: settings.languageCode,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          underline: const SizedBox(),
          dropdownColor: Theme.of(context).cardTheme.color,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          onChanged: (String? newLanguage) {
            if (newLanguage != null) {
              ref.read(settingsControllerProvider.notifier).updateLanguageCode(newLanguage);
            }
          },
          items: languages.entries.map<DropdownMenuItem<String>>((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHighContrastToggle(AppSettings settings, AppLocalizations l10n) {
    return _buildToggleTile(
      title: l10n.highContrast,
      subtitle: 'Optimize contrast for readability',
      value: settings.highContrast,
      onChanged: (val) {
        ref.read(settingsControllerProvider.notifier).toggleHighContrast(val);
      },
    );
  }
}
