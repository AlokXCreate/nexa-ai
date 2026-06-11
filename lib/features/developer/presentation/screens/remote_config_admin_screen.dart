import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/services/remote_config_service.dart';

class RemoteConfigAdminScreen extends ConsumerStatefulWidget {
  const RemoteConfigAdminScreen({super.key});

  @override
  ConsumerState<RemoteConfigAdminScreen> createState() => _RemoteConfigAdminScreenState();
}

class _RemoteConfigAdminScreenState extends ConsumerState<RemoteConfigAdminScreen> {
  final _announcementTextCtrl = TextEditingController();
  final _emergencyReasonCtrl = TextEditingController();
  double _rolloutPercent = 50.0;
  String _abTestLayout = 'A';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(remoteConfigServiceProvider);
      _announcementTextCtrl.text = service.announcementBannerText;
      _emergencyReasonCtrl.text = service.emergencyReason;
      _abTestLayout = service.abTestChatLayout;
    });
  }

  @override
  void dispose() {
    _announcementTextCtrl.dispose();
    _emergencyReasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(remoteConfigServiceProvider);
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
        title: Text('Remote Config Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () async {
              await service.clearAllOverrides();
              setState(() {
                _announcementTextCtrl.text = service.announcementBannerText;
                _emergencyReasonCtrl.text = service.emergencyReason;
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All local overrides cleared!'), backgroundColor: Colors.cyan),
                );
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Simulate Firebase Remote Config parameters locally. Overrides are cached and take precedence over cloud values.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // 1. Emergency Kill Switches
              _buildSectionTitle('Emergency Switches', Icons.warning_amber_rounded, Colors.redAccent),
              const SizedBox(height: 8),
              GlassContainer(
                borderRadius: 20,
                blur: 10,
                color: Colors.redAccent.withOpacity(0.04),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('App Active Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      subtitle: const Text('Deactivating blocks user access immediately.', style: TextStyle(fontSize: 10, color: Colors.white54)),
                      value: service.isAppActive,
                      onChanged: (val) async {
                        await service.setOverride('is_app_active', val);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emergencyReasonCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Emergency Reason Message',
                        labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (val) async {
                        await service.setOverride('emergency_reason', val);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Feature Flags
              _buildSectionTitle('Feature Flags', Icons.toggle_on_outlined, Colors.cyanAccent),
              const SizedBox(height: 8),
              GlassContainer(
                borderRadius: 20,
                blur: 10,
                color: Colors.white.withOpacity(0.02),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      'Enable Cloud Inference',
                      'Allows cloud offloading when device runs hot.',
                      service.enableCloudInference,
                      (val) => service.setOverride('enable_cloud_inference', val),
                    ),
                    const Divider(color: Colors.white10),
                    _buildSwitchTile(
                      'Enable Community Marketplace',
                      'Toggle the custom community tab in marketplace.',
                      service.enableCommunityMarketplace,
                      (val) => service.setOverride('enable_community_marketplace', val),
                    ),
                    const Divider(color: Colors.white10),
                    _buildSwitchTile(
                      'Enable Voice Chat',
                      'Toggle voice messaging capabilities.',
                      service.enableVoiceChat,
                      (val) => service.setOverride('enable_voice_chat', val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Announcement Banners
              _buildSectionTitle('Announcement Banners', Icons.campaign_rounded, Colors.amberAccent),
              const SizedBox(height: 8),
              GlassContainer(
                borderRadius: 20,
                blur: 10,
                color: Colors.white.withOpacity(0.02),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show Announcement Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      value: service.announcementShow,
                      onChanged: (val) async {
                        await service.setOverride('announcement_show', val);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _announcementTextCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Banner Message Text',
                        labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (val) async {
                        await service.setOverride('announcement_banner_text', val);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. A/B Testing & Rollout
              _buildSectionTitle('A/B Testing & Rollouts', Icons.shuffle_rounded, Colors.purpleAccent),
              const SizedBox(height: 8),
              GlassContainer(
                borderRadius: 20,
                blur: 10,
                color: Colors.white.withOpacity(0.02),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AB Test Chat Layout Bucket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        DropdownButton<String>(
                          dropdownColor: const Color(0xFF0F0E23),
                          value: _abTestLayout,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          items: ['A', 'B'].map((val) {
                            return DropdownMenuItem(value: val, child: Text('Layout $val'));
                          }).toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              await service.setOverride('ab_test_chat_layout', val);
                              setState(() {
                                _abTestLayout = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    Text(
                      'Feature Rollout Percentage: ${_rolloutPercent.round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    Slider(
                      value: _rolloutPercent,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      activeColor: Colors.purpleAccent,
                      onChanged: (val) {
                        setState(() {
                          _rolloutPercent = val;
                        });
                      },
                      onChangeEnd: (val) async {
                        await service.setOverride('rollout_percent', val.round());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Future<void> Function(bool) onToggle) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      value: value,
      onChanged: (val) async {
        await onToggle(val);
        setState(() {});
      },
    );
  }
}
