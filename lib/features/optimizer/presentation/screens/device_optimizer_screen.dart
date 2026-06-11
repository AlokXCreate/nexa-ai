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
import 'package:localmind_ai/features/optimizer/presentation/controllers/device_optimizer_controller.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';

class DeviceOptimizerScreen extends ConsumerStatefulWidget {
  const DeviceOptimizerScreen({super.key});

  @override
  ConsumerState<DeviceOptimizerScreen> createState() => _DeviceOptimizerScreenState();
}

class _DeviceOptimizerScreenState extends ConsumerState<DeviceOptimizerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceOptimizerControllerProvider);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('AI Device Optimizer', style: AppTypography.titleMedium),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              accentColor.withOpacity(0.08),
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
            // 1. Diagnostics Radar Scanner Card
            _buildScannerCard(state, accentColor),
            const SizedBox(height: 20),

            // If scanned, show diagnostics details
            if (!state.isScanning && state.deviceInfo.totalRamGb > 0) ...[
              // 2. Hardware Diagnostics Ring Grid
              _buildHardwareGrid(state),
              const SizedBox(height: 20),

              // 3. Recommended Parameters Section
              _buildRecommendationsSection(state),
              const SizedBox(height: 20),

              // 4. Perfect Fit Marketplace Models
              _buildPerfectFitSection(state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScannerCard(DeviceOptimizerState state, Color color) {
    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Performance Profiler',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Analyze system RAM, storage limits, and silicon architecture to compute optimized model parameters.',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (state.isScanning) ...[
            SizedBox(
              height: 140,
              width: 140,
              child: AnimatedBuilder(
                animation: _scannerController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RadarScannerPainter(
                      progress: _scannerController.value,
                      color: color,
                    ),
                    size: const Size(140, 140),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  'Scanning Diagnostics... ${(state.scanProgress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDiagnosticRow('OS Environment', state.deviceInfo.androidVersion, Icons.android_rounded),
                _buildDiagnosticRow('Hardware SoC', state.deviceInfo.cpuName, Icons.memory_rounded),
                _buildDiagnosticRow('GPU Accelerators', state.deviceInfo.gpuName, Icons.developer_board_rounded),
                const SizedBox(height: 20),
                PremiumButton(
                  label: 'Re-scan Device',
                  icon: Icons.sync_rounded,
                  onPressed: () {
                    ref.read(deviceOptimizerControllerProvider.notifier).scanDevice();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareGrid(DeviceOptimizerState state) {
    final info = state.deviceInfo;
    final usedRam = info.totalRamGb - info.freeRamGb;
    final ramPercentage = usedRam / info.totalRamGb;
    
    final usedStorage = info.totalStorageGb - info.freeStorageGb;
    final storagePercentage = usedStorage / info.totalStorageGb;

    return Row(
      children: [
        Expanded(
          child: _buildRingCard(
            title: 'RAM Capacity',
            valueText: '${(info.freeRamGb).toStringAsFixed(1)} GB Free',
            subText: 'Total: ${info.totalRamGb.toStringAsFixed(0)} GB',
            percentage: ramPercentage,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRingCard(
            title: 'Storage Space',
            valueText: '${(info.freeStorageGb).toStringAsFixed(0)} GB Free',
            subText: 'Total: ${info.totalStorageGb.toStringAsFixed(0)} GB',
            percentage: storagePercentage,
            color: Colors.emerald,
          ),
        ),
      ],
    );
  }

  Widget _buildRingCard({
    required String title,
    required String valueText,
    required String subText,
    required double percentage,
    required Color color,
  }) {
    return GlassContainer(
      borderRadius: 16,
      blur: 5,
      color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            width: 64,
            child: CustomPaint(
              painter: DiagnosticRingPainter(percentage: percentage, color: color),
              child: Center(
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            valueText,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Text(
            subText,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(DeviceOptimizerState state) {
    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Local Tunings',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildParamCard(
            title: 'Recommended Quantization',
            val: state.recommendedQuantization,
            desc: 'Maximizes execution speeds without critical cognitive dropoffs.',
            icon: Icons.compress_rounded,
            color: Colors.cyan,
          ),
          const SizedBox(height: 12),
          _buildParamCard(
            title: 'Maximum Context Length',
            val: '${state.recommendedContextSize} Tokens',
            desc: 'Safe limit to prevent device crash/out-of-memory errors.',
            icon: Icons.short_text_rounded,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildParamCard(
            title: 'Safe Memory Allocation',
            val: '${state.safeMemoryAllocationGb.toStringAsFixed(1)} GB',
            desc: 'Dedicated memory boundary for local neural loads.',
            icon: Icons.sd_card_rounded,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildParamCard({
    required String title,
    required String val,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(val, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfectFitSection(DeviceOptimizerState state) {
    final models = state.recommendedModels;
    if (models.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Recommended Local Models ("Perfect Fit")',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: models.length,
            itemBuilder: (context, idx) {
              final model = models[idx];
              return _buildRecommendedModelCard(model);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedModelCard(MarketplaceModel model) {
    return GestureDetector(
      onTap: () => context.push('/marketplace/model-details/${model.id}'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color!.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: Text(model.logo, style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.emerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.emerald.withOpacity(0.3)),
                  ),
                  child: const Text('SAFE', style: TextStyle(color: Colors.emerald, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              model.name,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              model.developer,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.psychology_outlined, size: 10, color: Colors.grey),
                const SizedBox(width: 4),
                Text(model.ramRequirement, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                const Spacer(),
                Text(
                  model.downloadSize,
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RadarScannerPainter extends CustomPainter {
  final double progress;
  final Color color;

  RadarScannerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.0), color.withOpacity(0.25)],
        stops: const [0.75, 1.0],
        transform: GradientRotation(progress * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 0.5;

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), linePaint);

    canvas.drawCircle(center, radius * 0.3, borderPaint);
    canvas.drawCircle(center, radius * 0.6, borderPaint);
    canvas.drawCircle(center, radius * 0.9, borderPaint);

    canvas.drawCircle(center, radius * 0.9, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant RadarScannerPainter oldDelegate) => true;
}

class DiagnosticRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  DiagnosticRingPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius - 3, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 3),
      -pi / 2,
      percentage * 2 * pi,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant DiagnosticRingPainter oldDelegate) => true;
}
