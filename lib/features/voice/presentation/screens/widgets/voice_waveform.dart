import 'dart:math';
import 'package:flutter/material.dart';
import 'package:localmind_ai/features/voice/data/services/voice_service.dart';

class VoiceWaveform extends StatefulWidget {
  final AssistantVoiceStatus status;
  final double soundLevel;
  final Color color;

  const VoiceWaveform({
    super.key,
    required this.status,
    required this.soundLevel,
    this.color = const Color(0xFF6C63FF),
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 120),
          painter: VoiceWaveformPainter(
            animationValue: _controller.value,
            status: widget.status,
            soundLevel: widget.soundLevel,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class VoiceWaveformPainter extends CustomPainter {
  final double animationValue;
  final AssistantVoiceStatus status;
  final double soundLevel;
  final Color color;

  VoiceWaveformPainter({
    required this.animationValue,
    required this.status,
    required this.soundLevel,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double midY = size.height / 2;
    final double width = size.width;

    // Adjust variables based on status
    double maxAmplitude = 0.0;
    double frequency = 1.0;
    double waveCount = 1;

    switch (status) {
      case AssistantVoiceStatus.idle:
        maxAmplitude = 2.0;
        frequency = 0.5;
        waveCount = 1;
        break;
      case AssistantVoiceStatus.listening:
        // SoundLevel reacts between 0.0 to 15.0+
        maxAmplitude = 4.0 + (soundLevel * 3.5).clamp(0.0, 50.0);
        frequency = 1.5;
        waveCount = 3;
        break;
      case AssistantVoiceStatus.thinking:
        // Pulsating slow wave
        maxAmplitude = 18.0 + sin(animationValue * 2 * pi) * 6.0;
        frequency = 0.8;
        waveCount = 2;
        break;
      case AssistantVoiceStatus.speaking:
        // Vocal cadence wave
        maxAmplitude = 24.0 + cos(animationValue * 4 * pi) * 12.0;
        frequency = 1.2;
        waveCount = 4;
        break;
    }

    // Draw multiple overlapping translucent waves
    for (int w = 0; w < waveCount; w++) {
      final path = Path();
      
      // Calculate opacity and scale factor for each wave layer
      final double waveFactor = 1.0 - (w * 0.25);
      final double phaseShift = w * (pi / 3) + (animationValue * 2 * pi * (w == 0 ? 1.5 : (w == 1 ? -1.0 : 0.8)));
      
      paint.color = color.withOpacity((0.6 * waveFactor).clamp(0.0, 1.0));
      paint.strokeWidth = w == 0 ? 2.5 : 1.5;

      path.moveTo(0, midY);

      for (double x = 0; x <= width; x++) {
        // Apply sine wave equation with horizontal boundaries scaling (bell curve style compression at ends)
        final double normalizedX = x / width;
        final double edgeCompression = sin(normalizedX * pi); // 0 at ends, 1 in middle
        
        final double y = midY + 
            sin(normalizedX * 2 * pi * frequency * 2.5 + phaseShift) * 
            maxAmplitude * 
            waveFactor * 
            edgeCompression;
            
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VoiceWaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.status != status ||
        oldDelegate.soundLevel != soundLevel;
  }
}
