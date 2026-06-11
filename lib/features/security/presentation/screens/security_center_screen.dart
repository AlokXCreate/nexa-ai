import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_sessions_controller.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_session.dart';
import 'package:localmind_ai/features/security/presentation/screens/pin_gate_screen.dart';

class SecurityCenterScreen extends ConsumerStatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  ConsumerState<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends ConsumerState<SecurityCenterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnimation;
  final TextEditingController _passwordController = TextEditingController();
  final _backupFormKey = GlobalKey<FormState>();
  bool _isSessionsExpanded = false;

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOutCubic),
    );

    // Trigger initial score animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final score = ref.read(securityControllerProvider).securityScore;
      _animateToScore(score);
    });
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _animateToScore(double score) {
    final target = score / 100.0;
    _scoreAnimation = Tween<double>(
      begin: _scoreAnimation.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOutCubic),
    );
    _scoreAnimController.forward(from: 0.0);
  }

  Color _getScoreColor(double progress) {
    if (progress < 0.4) {
      return AppColors.error;
    } else if (progress < 0.75) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  String _getScoreLabel(double progress) {
    if (progress < 0.4) {
      return 'VULNERABLE';
    } else if (progress < 0.75) {
      return 'MODERATE';
    } else {
      return 'SECURED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityControllerProvider);
    final sessionsState = ref.watch(chatSessionsControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Listen to changes in security score to update animation
    ref.listen<SecurityState>(securityControllerProvider, (previous, next) {
      if (previous?.securityScore != next.securityScore) {
        _animateToScore(next.securityScore);
      }

      // Show success or errors reactively
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(securityControllerProvider.notifier).clearError();
      }

      if (next.lastBackupPath != null && previous?.lastBackupPath != next.lastBackupPath) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup encrypted & exported successfully to:\n${next.lastBackupPath}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('Security & Privacy', style: AppTypography.titleMedium),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(0.08),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                center: const Alignment(0.4, -0.6),
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
                // 1. Animated Canvas Gauge
                Center(
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _scoreAnimation,
                        builder: (context, child) {
                          final progress = _scoreAnimation.value;
                          final activeColor = _getScoreColor(progress);
                          return Container(
                            width: 180,
                            height: 180,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(180, 180),
                                  painter: SecurityScorePainter(
                                    progress: progress,
                                    activeColor: activeColor,
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 14),
                                    Text(
                                      '${(progress * 100).round()}%',
                                      style: GoogleFonts.outfit(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _getScoreLabel(progress),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: activeColor,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Device protection level evaluated from locks, modes, and configurations.',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Core Security Configurations
                Text('Shield Settings', style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                
                // PIN Lock Toggle
                _buildOptionTile(
                  icon: Icons.pin_rounded,
                  title: 'PIN Access Lock',
                  subtitle: securityState.config.isPinEnabled ? 'PIN protection is active' : 'Secure app launch and private chats',
                  trailing: Switch(
                    value: securityState.config.isPinEnabled,
                    activeColor: primaryColor,
                    onChanged: (val) => _handlePinToggle(val),
                  ),
                ),
                const SizedBox(height: 12),

                // Biometrics Toggle
                _buildOptionTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Scanner fallback',
                  subtitle: 'Use face or fingerprint when available',
                  trailing: Switch(
                    value: securityState.config.isBiometricEnabled,
                    activeColor: primaryColor,
                    onChanged: (val) => _handleBiometricToggle(val),
                  ),
                ),
                const SizedBox(height: 12),

                // Incognito Mode Toggle
                _buildOptionTile(
                  icon: Icons.visibility_off_rounded,
                  title: 'Incognito Mode',
                  subtitle: 'Do not save session logs or history to disk',
                  trailing: Switch(
                    value: securityState.config.isIncognitoActive,
                    activeColor: primaryColor,
                    onChanged: (val) {
                      ref.read(securityControllerProvider.notifier).toggleIncognitoMode(val);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Permission Manager
                Text('Device Permissions Manager', style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                _buildPermissionGrid(securityState),
                const SizedBox(height: 24),

                // 4. Private Sessions Config
                _buildPrivateSessionsAccordion(sessionsState.sessions, securityState),
                const SizedBox(height: 24),

                // 5. Danger Zone / Advanced Crypt
                Text('Danger Zone & Snapshots', style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                _buildDangerZoneCard(),
              ],
            ),
          ),

          // Loading Overlay
          if (securityState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: GlassContainer(
                  borderRadius: 20,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        'Executing secure database operations...',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.05),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildPermissionGrid(SecurityState state) {
    final perms = ['Microphone', 'Storage', 'Notifications'];
    final icons = {
      'Microphone': Icons.mic_none_rounded,
      'Storage': Icons.folder_open_rounded,
      'Notifications': Icons.notifications_none_rounded,
    };

    return Row(
      children: perms.map((name) {
        final status = state.permissions[name] ?? 'denied';
        final isGranted = status == 'granted';
        final activeColor = isGranted ? AppColors.success : AppColors.error;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              ref.read(securityControllerProvider.notifier).requestPermission(name);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Column(
                  children: [
                    Icon(icons[name], color: isGranted ? activeColor : Colors.grey, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGranted ? 'GRANTED' : 'DENIED',
                        style: TextStyle(color: activeColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivateSessionsAccordion(List<ChatSession> sessions, SecurityState state) {
    final privateList = state.config.privateSessionIds;

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isSessionsExpanded = !_isSessionsExpanded),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.vpn_key_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Private Chat Rooms',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${privateList.length} rooms guarded behind locks',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isSessionsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _isSessionsExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: sessions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No chat rooms configured. Create a chat session first.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: sessions.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            final isPrivate = privateList.contains(session.id);
                            return ListTile(
                              leading: Icon(
                                isPrivate ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                                color: isPrivate ? AppColors.warning : Colors.grey,
                                size: 20,
                              ),
                              title: Text(
                                session.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Model: ${session.modelId}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              trailing: Switch(
                                value: isPrivate,
                                activeColor: Theme.of(context).colorScheme.primary,
                                onChanged: (val) {
                                  ref.read(securityControllerProvider.notifier).toggleSessionPrivacy(session.id, val);
                                },
                              ),
                            );
                          },
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDangerZoneCard() {
    return GlassContainer(
      borderColor: Colors.redAccent.withOpacity(0.3),
      color: Colors.red.withOpacity(0.02),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Irreversible Controls',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Export fully encrypted data snapshot logs or completely reset local data files.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: 'Secure Snapshot',
                  icon: Icons.shield_rounded,
                  onPressed: () => _showBackupDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumButton(
                  label: 'Wipe Sandbox',
                  icon: Icons.delete_sweep_rounded,
                  isSecondary: true,
                  onPressed: () => _showWipeConfirmation(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handlePinToggle(bool enabled) {
    if (enabled) {
      // Setup new PIN
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PinGateScreen(
            isConfirmMode: true,
            onConfirmPin: (pin) async {
              await ref.read(securityControllerProvider.notifier).setPinCode(pin);
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else {
      // Disable PIN
      ref.read(securityControllerProvider.notifier).disablePin();
    }
  }

  void _handleBiometricToggle(bool enabled) {
    final hasPin = ref.read(securityControllerProvider).config.isPinEnabled;
    if (enabled && !hasPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable PIN Lock first before setting up Biometrics.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.read(securityControllerProvider.notifier).toggleBiometrics(enabled);
  }

  void _showBackupDialog() {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Export Encrypted Backup', style: AppTypography.titleMedium),
        content: Form(
          key: _backupFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a password to encrypt your chats, benchmarks, and configuration keys.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Encryption Password',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_backupFormKey.currentState!.validate()) {
                final password = _passwordController.text;
                Navigator.of(context).pop();
                await ref.read(securityControllerProvider.notifier).exportEncryptedBackup(password);
              }
            },
            child: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showWipeConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text('Purge All Local Sandbox?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'WARNING: This will delete all chat history databases, active benchmark logs, app settings, and cached local GGUF models from disk.\n\nThis action is irreversible.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(securityControllerProvider.notifier).purgeAllData();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('WIPE EVERYTHING', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class SecurityScorePainter extends CustomPainter {
  final double progress;
  final Color activeColor;

  SecurityScorePainter({required this.progress, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    const startAngle = 3 * pi / 4;
    const sweepAngle = 3 * pi / 2;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    if (progress > 0) {
      // Draw progress arc
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            activeColor.withOpacity(0.4),
            activeColor,
          ],
          stops: const [0.0, 1.0],
          transform: const GradientRotation(3 * pi / 4),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle * progress, false, progressPaint);

      // Add glowing shadow under progress arc
      final shadowPaint = Paint()
        ..color = activeColor.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle * progress, false, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SecurityScorePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.activeColor != activeColor;
  }
}
