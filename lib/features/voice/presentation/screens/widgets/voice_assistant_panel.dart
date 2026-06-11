import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/voice/data/services/voice_service.dart';
import 'package:localmind_ai/features/voice/presentation/controllers/voice_controller.dart';
import 'package:localmind_ai/features/voice/presentation/screens/widgets/voice_waveform.dart';

class VoiceAssistantPanel extends ConsumerStatefulWidget {
  const VoiceAssistantPanel({super.key});

  @override
  ConsumerState<VoiceAssistantPanel> createState() => _VoiceAssistantPanelState();
}

class _VoiceAssistantPanelState extends ConsumerState<VoiceAssistantPanel> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  final ScrollController _transcriptScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _transcriptScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_transcriptScrollController.hasClients) {
        _transcriptScrollController.animateTo(
          _transcriptScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Scroll transcript box when text updates
    ref.listen<VoiceState>(voiceControllerProvider, (prev, next) {
      if (prev?.userTranscript != next.userTranscript || prev?.aiTranscript != next.aiTranscript) {
        _scrollToBottom();
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.85),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle indicator
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Top Status Bar & Cancel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusPill(state.status),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () {
                      ref.read(voiceControllerProvider.notifier).cancelVoiceAssistant();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // Waveform visualizer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VoiceWaveform(
                status: state.status,
                soundLevel: state.soundLevel,
                color: primaryColor,
              ),
            ),

            // Conversation Transcript Display Box
            Container(
              height: 140,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Scrollbar(
                controller: _transcriptScrollController,
                child: ListView(
                  controller: _transcriptScrollController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (state.userTranscript.isNotEmpty) ...[
                      Text(
                        'You',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.userTranscript,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (state.aiTranscript.isNotEmpty) ...[
                      const Text(
                        'LocalMind AI',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.aiTranscript,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                    if (state.userTranscript.isEmpty && state.aiTranscript.isEmpty)
                      Center(
                        child: Text(
                          state.status == AssistantVoiceStatus.listening
                              ? 'Listening... Start speaking'
                              : 'Tap mic button below to talk',
                          style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Floating Animated Voice Button
            _buildVoiceMicButton(state),

            // Settings panel: speed rate, hands-free toggle, voice profile picker
            const SizedBox(height: 12),
            _buildInteractiveSettings(state),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(AssistantVoiceStatus status) {
    String label = '';
    Color color = Colors.grey;
    IconData icon = Icons.circle;

    switch (status) {
      case AssistantVoiceStatus.idle:
        label = 'READY';
        color = Colors.grey;
        icon = Icons.keyboard_voice_rounded;
        break;
      case AssistantVoiceStatus.listening:
        label = 'LISTENING';
        color = Theme.of(context).colorScheme.primary;
        icon = Icons.mic_rounded;
        break;
      case AssistantVoiceStatus.thinking:
        label = 'THINKING';
        color = Colors.amber;
        icon = Icons.autorenew_rounded;
        break;
      case AssistantVoiceStatus.speaking:
        label = 'SPEAKING';
        color = AppColors.success;
        icon = Icons.volume_up_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMicButton(VoiceState state) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    // Choose icon representation based on state
    IconData iconData = Icons.mic_rounded;
    Color buttonColor = primaryColor;
    bool isGlowing = false;

    if (state.status == AssistantVoiceStatus.listening) {
      iconData = Icons.stop_rounded;
      buttonColor = Colors.redAccent;
      isGlowing = true;
    } else if (state.status == AssistantVoiceStatus.speaking) {
      iconData = Icons.close_rounded;
      buttonColor = Colors.grey[800]!;
    } else if (state.status == AssistantVoiceStatus.thinking) {
      iconData = Icons.hourglass_empty_rounded;
      buttonColor = Colors.amber;
      isGlowing = true;
    }

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            final controller = ref.read(voiceControllerProvider.notifier);
            if (state.status == AssistantVoiceStatus.idle) {
              controller.startListening();
            } else if (state.status == AssistantVoiceStatus.listening) {
              controller.stopListening();
            } else {
              controller.cancelVoiceAssistant();
            }
          },
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: buttonColor,
              boxShadow: [
                if (isGlowing)
                  BoxShadow(
                    color: buttonColor.withOpacity(0.5),
                    blurRadius: 15.0 + (_glowController.value * 12.0),
                    spreadRadius: 2.0 + (_glowController.value * 4.0),
                  ),
              ],
            ),
            child: Center(
              child: Icon(
                iconData,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveSettings(VoiceState state) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Row 1: Hands free toggle & Speech Speed Slider
          Row(
            children: [
              // Hands-Free Switch
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.settings.isHandsFree 
                            ? Icons.record_voice_over_rounded 
                            : Icons.keyboard_voice_outlined, 
                        color: state.settings.isHandsFree ? primaryColor : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hands-Free',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Switch.adaptive(
                        value: state.settings.isHandsFree,
                        activeColor: primaryColor,
                        onChanged: (val) {
                          ref.read(voiceControllerProvider.notifier).toggleHandsFree(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Speech Speed Slider
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Speed Rate',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${state.settings.speechRate.toStringAsFixed(1)}x',
                            style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                          activeTrackColor: primaryColor,
                          thumbColor: primaryColor,
                        ),
                        child: Slider(
                          value: state.settings.speechRate,
                          min: 0.5,
                          max: 1.5,
                          onChanged: (val) {
                            ref.read(voiceControllerProvider.notifier).updateSpeechRate(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Offline TTS voice profile picker
          if (state.availableVoices.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.face_unlock_rounded, color: Colors.grey, size: 18),
                  const SizedBox(width: 12),
                  const Text(
                    'Voice Assistant Profile',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: state.settings.voiceName,
                      hint: const Text('Default Voice', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      dropdownColor: AppColors.surfaceElevated,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('System Voice'),
                        ),
                        ...state.availableVoices.map((voice) {
                          final name = voice['name']!;
                          final displayName = name.length > 20 ? '${name.substring(0, 18)}...' : name;
                          return DropdownMenuItem<String?>(
                            value: name,
                            child: Text(displayName),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(voiceControllerProvider.notifier).updateVoice(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
