import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';

class PinGateScreen extends ConsumerStatefulWidget {
  final bool isConfirmMode;
  final ValueChanged<String>? onConfirmPin;
  
  const PinGateScreen({
    super.key, 
    this.isConfirmMode = false,
    this.onConfirmPin,
  });

  @override
  ConsumerState<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends ConsumerState<PinGateScreen> with SingleTickerProviderStateMixin {
  String _enteredDigits = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isBiometricScanInProgress = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Auto-trigger simulated biometric if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(securityControllerProvider);
      if (state.config.isBiometricEnabled && !widget.isConfirmMode) {
        _triggerBiometricAuth();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerBiometricAuth() async {
    setState(() {
      _isBiometricScanInProgress = true;
    });

    // Simulate native scanning dialog
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _isBiometricScanInProgress = false;
      });

      // Verification success
      final controller = ref.read(securityControllerProvider.notifier);
      // Simulate by verifying against the stored pin
      final success = controller.verifyPin(
        _deobfuscatePin(ref.read(securityControllerProvider).config.pinCodeObfuscated)
      );
      if (success) {
        context.go('/');
      } else {
        _shake();
      }
    }
  }

  void _shake() {
    _shakeController.forward(from: 0.0);
    setState(() {
      _enteredDigits = '';
    });
  }

  void _onKeyPress(String digit) {
    if (_enteredDigits.length >= 4) return;

    setState(() {
      _enteredDigits += digit;
    });

    if (_enteredDigits.length == 4) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_enteredDigits.isNotEmpty) {
      setState(() {
        _enteredDigits = _enteredDigits.substring(0, _enteredDigits.length - 1);
      });
    }
  }

  void _submitPin() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    if (widget.isConfirmMode) {
      if (widget.onConfirmPin != null) {
        widget.onConfirmPin!(_enteredDigits);
      }
      return;
    }

    final controller = ref.read(securityControllerProvider.notifier);
    final success = controller.verifyPin(_enteredDigits);
    if (success) {
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/');
      }
    } else {
      _shake();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              primaryColor.withOpacity(0.08),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            center: const Alignment(0.0, -0.4),
            radius: 1.2,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(Icons.lock_outline_rounded, color: primaryColor, size: 48),
                const SizedBox(height: 16),
                Text(
                  widget.isConfirmMode ? 'Setup Security PIN' : 'Access Restricted',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isConfirmMode 
                      ? 'Enter a 4-digit PIN code to secure your AI sessions' 
                      : 'Please authenticate to unlock Nexa AI',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // PIN indicator dots with shake animation
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final offset = sin(_shakeAnimation.value * pi * 2) * 8.0;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final isActive = index < _enteredDigits.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? primaryColor : Colors.white10,
                              border: Border.all(
                                color: isActive ? primaryColor : Colors.white30,
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (isActive)
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
                const Spacer(),

                // PIN Pad
                GlassContainer(
                  borderRadius: 24,
                  blur: 15,
                  color: Colors.white.withOpacity(0.02),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumKey('1'),
                          _buildNumKey('2'),
                          _buildNumKey('3'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumKey('4'),
                          _buildNumKey('5'),
                          _buildNumKey('6'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumKey('7'),
                          _buildNumKey('8'),
                          _buildNumKey('9'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Biometrics / Clear Key
                          _buildActionKey(
                            state.config.isBiometricEnabled && !widget.isConfirmMode
                                ? Icons.fingerprint_rounded
                                : Icons.clear_rounded,
                            state.config.isBiometricEnabled && !widget.isConfirmMode
                                ? _triggerBiometricAuth
                                : () => setState(() => _enteredDigits = ''),
                            color: state.config.isBiometricEnabled && !widget.isConfirmMode
                                ? primaryColor
                                : Colors.grey,
                          ),
                          _buildNumKey('0'),
                          _buildActionKey(Icons.backspace_outlined, _onBackspace, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_isBiometricScanInProgress) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fingerprint_rounded, size: 14, color: primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Simulating Fingerprint Sensor scan...',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumKey(String digit) {
    return GestureDetector(
      onTap: () => _onKeyPress(digit),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap, {required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

// Helper to verify pin deobfuscation internally
String _deobfuscatePin(String obfuscated) {
  if (obfuscated.trim().isEmpty) return '';
  try {
    final bytes = base64.decode(obfuscated.trim());
    final deobfuscated = bytes.map((b) => b ^ 99).toList();
    return utf8.decode(deobfuscated);
  } catch (_) {
    return '';
  }
}
