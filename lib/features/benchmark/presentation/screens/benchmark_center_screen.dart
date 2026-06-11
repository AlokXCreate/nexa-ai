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
import 'package:localmind_ai/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:localmind_ai/features/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';

class BenchmarkCenterScreen extends ConsumerStatefulWidget {
  const BenchmarkCenterScreen({super.key});

  @override
  ConsumerState<BenchmarkCenterScreen> createState() => _BenchmarkCenterScreenState();
}

class _BenchmarkCenterScreenState extends ConsumerState<BenchmarkCenterScreen> with TickerProviderStateMixin {
  String? _selectedModelId;
  late AnimationController _scanningController;
  late AnimationController _pulseController;
  String _comparisonMetric = 'tps'; // 'tps', 'latency', 'ram', 'battery'

  @override
  void initState() {
    super.initState();
    _scanningController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Fetch installed models
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(installedModelsControllerProvider.notifier).fetchInstalledModels();
      ref.read(benchmarkControllerProvider.notifier).loadResults();
    });
  }

  @override
  void dispose() {
    _scanningController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final installedState = ref.watch(installedModelsControllerProvider);
    final benchmarkState = ref.watch(benchmarkControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Set default selected model if not set
    if (_selectedModelId == null && installedState.installedModels.isNotEmpty) {
      _selectedModelId = installedState.installedModels.first.id;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('Benchmark Center', style: AppTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.grey),
            tooltip: 'Clear History',
            onPressed: () => _showClearConfirmation(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              primaryColor.withOpacity(0.08),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            center: const Alignment(0.6, -0.6),
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
            // 1. Selector & Sweep Runner Panel
            _buildRunnerPanel(installedState, benchmarkState),
            const SizedBox(height: 20),

            // 2. Live Active Run Visualizer (if benchmarking)
            if (benchmarkState.isBenchmarking && benchmarkState.activeRunMetrics != null) ...[
              _buildLiveRunDashboard(benchmarkState.activeRunMetrics!, benchmarkState.progress),
              const SizedBox(height: 20),
            ],

            // 3. Historical Analytics & Performance charts
            if (benchmarkState.results.isNotEmpty) ...[
              _buildAnalyticsSection(benchmarkState.results),
              const SizedBox(height: 20),
              
              _buildComparisonSection(benchmarkState.results),
              const SizedBox(height: 20),
              
              _buildRankingSection(benchmarkState.results),
              const SizedBox(height: 20),

              _buildExportSection(benchmarkState),
            ] else ...[
              _buildEmptyState(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRunnerPanel(InstalledModelsState installedState, BenchmarkState benchmarkState) {
    final models = installedState.installedModels;
    final isBenchmarking = benchmarkState.isBenchmarking;

    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model Evaluation Sweep',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Verify exact GGUF token generation speed, latency and RAM loads.',
            style: TextStyle(color: Colors.grey.shade450, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (models.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No models are downloaded locally. Please download models from the marketplace first.',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                      color: Colors.black12,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedModelId,
                        dropdownColor: Theme.of(context).cardTheme.color,
                        isExpanded: true,
                        hint: const Text('Select Model', style: TextStyle(fontSize: 13)),
                        items: models.map((m) {
                          return DropdownMenuItem<String>(
                            value: m.id,
                            child: Text(m.localName, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: isBenchmarking
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedModelId = val;
                                });
                              },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PremiumButton(
                  label: isBenchmarking ? 'Running...' : 'Run Sweep',
                  icon: isBenchmarking ? Icons.hourglass_empty_rounded : Icons.play_arrow_rounded,
                  onPressed: isBenchmarking || _selectedModelId == null
                      ? null
                      : () {
                          ref.read(benchmarkControllerProvider.notifier).runBenchmark(_selectedModelId!);
                        },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveRunDashboard(BenchmarkResult metrics, double progress) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return GlassContainer(
      borderRadius: 20,
      blur: 15,
      color: Colors.black.withOpacity(0.2),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE BENCHMARK RUN',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.black,
                  letterSpacing: 1.5,
                  color: accentColor,
                ),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.3 + (_pulseController.value * 0.7)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5 * _pulseController.value),
                          blurRadius: 6,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              metrics.modelName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 24),
          
          // Speed gauge meter
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              children: [
                Center(
                  child: AnimatedBuilder(
                    animation: _scanningController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: GaugePainter(
                          value: metrics.tokensPerSecond,
                          maxValue: 60.0,
                          angleOffset: _scanningController.value * 2 * pi,
                          color: accentColor,
                        ),
                        size: const Size(140, 140),
                      );
                    },
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        metrics.tokensPerSecond.toStringAsFixed(1),
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'TOK/SEC',
                        style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Progress indicator bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Grid values CPU/RAM/GPU/Battery/Latency
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: [
              _buildMiniMetricCard('CPU Load', '${metrics.cpuUsagePercent.toStringAsFixed(1)}%', Icons.memory_rounded, Colors.cyan),
              _buildMiniMetricCard('RAM Usage', '${(metrics.ramUsageMb / 1024.0).toStringAsFixed(2)} GB', Icons.storage_rounded, Colors.purple),
              _buildMiniMetricCard('GPU Load', '${metrics.gpuUsagePercent.toStringAsFixed(1)}%', Icons.developer_board_rounded, Colors.emerald),
              _buildMiniMetricCard('Battery Imp.', '${metrics.batteryImpactPercent.toStringAsFixed(2)} %/hr', Icons.battery_charging_full_rounded, Colors.amber),
              _buildMiniMetricCard('First Token', '${metrics.firstTokenLatencyMs} ms', Icons.timer_rounded, Colors.rose),
              _buildMiniMetricCard('Size in Disk', '${metrics.storageUsageGb.toStringAsFixed(2)} GB', Icons.save_rounded, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(List<BenchmarkResult> results) {
    final completedResults = results.where((r) => r.isCompleted).toList();
    if (completedResults.isEmpty) return const SizedBox.shrink();

    final primaryColor = Theme.of(context).colorScheme.primary;

    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance History',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tokens per second execution trajectory over past trials.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: LineChartPainter(
                results: completedResults,
                lineColor: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(List<BenchmarkResult> results) {
    final completedResults = results.where((r) => r.isCompleted).toList();
    if (completedResults.isEmpty) return const SizedBox.shrink();

    // Group by modelId, take the latest run per model
    final Map<String, BenchmarkResult> latestPerModel = {};
    for (final r in completedResults) {
      if (!latestPerModel.containsKey(r.modelId)) {
        latestPerModel[r.modelId] = r;
      }
    }
    final comparedModels = latestPerModel.values.toList();
    
    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Model Comparison',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _buildMetricSelector(),
            ],
          ),
          const SizedBox(height: 20),
          ...comparedModels.map((r) => _buildComparisonBar(r, comparedModels)),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    final textStyle = const TextStyle(fontSize: 11, fontWeight: FontWeight.bold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _comparisonMetric,
          dropdownColor: Theme.of(context).cardTheme.color,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 11),
          items: [
            DropdownMenuItem(value: 'tps', child: Text('Speed (Tps)', style: textStyle)),
            DropdownMenuItem(value: 'latency', child: Text('Latency (Ms)', style: textStyle)),
            DropdownMenuItem(value: 'ram', child: Text('RAM (Mb)', style: textStyle)),
            DropdownMenuItem(value: 'battery', child: Text('Battery (%/hr)', style: textStyle)),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _comparisonMetric = val;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildComparisonBar(BenchmarkResult r, List<BenchmarkResult> all) {
    double value = 0.0;
    double maxVal = 1.0;
    String displayStr = '';
    Color barColor = Colors.cyan;

    switch (_comparisonMetric) {
      case 'tps':
        value = r.tokensPerSecond;
        maxVal = all.map((m) => m.tokensPerSecond).reduce(max);
        displayStr = '${value.toStringAsFixed(1)} tps';
        barColor = Colors.cyan;
        break;
      case 'latency':
        value = r.firstTokenLatencyMs.toDouble();
        maxVal = all.map((m) => m.firstTokenLatencyMs.toDouble()).reduce(max);
        displayStr = '${r.firstTokenLatencyMs} ms';
        barColor = Colors.rose;
        break;
      case 'ram':
        value = r.ramUsageMb;
        maxVal = all.map((m) => m.ramUsageMb).reduce(max);
        displayStr = '${(value / 1024.0).toStringAsFixed(2)} GB';
        barColor = Colors.purple;
        break;
      case 'battery':
        value = r.batteryImpactPercent;
        maxVal = all.map((m) => m.batteryImpactPercent).reduce(max);
        displayStr = '${value.toStringAsFixed(2)} %/hr';
        barColor = Colors.amber;
        break;
    }

    if (maxVal == 0.0) maxVal = 1.0;
    final ratio = value / maxVal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.modelName,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                displayStr,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500),
                widthFactor: ratio.clamp(0.02, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        barColor.withOpacity(0.5),
                        barColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingSection(List<BenchmarkResult> results) {
    final completedResults = results.where((r) => r.isCompleted).toList();
    if (completedResults.isEmpty) return const SizedBox.shrink();

    // Group by model, take the highest score per model
    final Map<String, BenchmarkResult> bestPerModel = {};
    for (final r in completedResults) {
      final existing = bestPerModel[r.modelId];
      if (existing == null || r.performanceScore > existing.performanceScore) {
        bestPerModel[r.modelId] = r;
      }
    }

    final ranked = bestPerModel.values.toList();
    ranked.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));

    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hardware Performance Ranking',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Models ranked based on overall speed, latency and RAM loads.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ranked.length,
            itemBuilder: (context, idx) {
              final r = ranked[idx];
              final score = r.performanceScore;
              
              String medal = '';
              if (idx == 0) medal = '🥇';
              if (idx == 1) medal = '🥈';
              if (idx == 2) medal = '🥉';

              Widget badge = const SizedBox.shrink();
              if (idx == 0) {
                badge = _buildRankingBadge('SPEED CHAMP', Colors.cyan);
              } else if (r.ramUsageMb < 3000 && idx > 0) {
                badge = _buildRankingBadge('MEMORY EFFICIENT', Colors.purple);
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      alignment: Alignment.center,
                      child: Text(
                        medal.isNotEmpty ? medal : '${idx + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(r.modelName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              badge,
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.tokensPerSecond.toStringAsFixed(1)} tps  •  ${r.firstTokenLatencyMs}ms latency  •  ${(r.ramUsageMb / 1024.0).toStringAsFixed(1)}GB RAM',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          score.toStringAsFixed(0),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                        ),
                        const Text('SCORE', style: TextStyle(fontSize: 8, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildExportSection(BenchmarkState state) {
    return GlassContainer(
      borderRadius: 16,
      blur: 5,
      color: Theme.of(context).cardTheme.color!.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: 'Export CSV',
                  icon: Icons.table_chart_rounded,
                  isSecondary: true,
                  onPressed: () async {
                    final path = await ref.read(benchmarkControllerProvider.notifier).exportResultsCsv();
                    if (path != null && mounted) {
                      _showExportSuccessSnackBar(context, path);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumButton(
                  label: 'Export JSON',
                  icon: Icons.code_rounded,
                  isSecondary: true,
                  onPressed: () async {
                    final path = await ref.read(benchmarkControllerProvider.notifier).exportResultsJson();
                    if (path != null && mounted) {
                      _showExportSuccessSnackBar(context, path);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.speed_outlined, color: Colors.grey.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            Text(
              'No Benchmarks Run Yet',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select an installed model above and run a performance sweep.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text('Clear Records', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to permanently delete all benchmark logs?', style: TextStyle(fontSize: 13)),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Delete All', style: TextStyle(color: Colors.red)),
              onPressed: () {
                ref.read(benchmarkControllerProvider.notifier).clearAll();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showExportSuccessSnackBar(BuildContext context, String path) {
    final fileName = path.split('/').last.split('\\').last;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported: $fileName', style: const TextStyle(fontSize: 12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () {},
        ),
      ),
    );
  }
}

class AnimatedFractionallySizedBox extends StatefulWidget {
  final Widget child;
  final double widthFactor;
  final Duration duration;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.child,
    required this.widthFactor,
    required this.duration,
  });

  @override
  State<AnimatedFractionallySizedBox> createState() => _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState extends State<AnimatedFractionallySizedBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldFactor = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0.0, end: widget.widthFactor).animate(_controller);
    _controller.forward();
    _oldFactor = widget.widthFactor;
  }

  @override
  void didUpdateWidget(covariant AnimatedFractionallySizedBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widthFactor != widget.widthFactor) {
      _animation = Tween<double>(begin: _oldFactor, end: widget.widthFactor).animate(_controller);
      _controller.reset();
      _controller.forward();
      _oldFactor = widget.widthFactor;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FractionallySizedBox(
          widthFactor: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<BenchmarkResult> results;
  final Color lineColor;

  LineChartPainter({required this.results, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    // Find min/max values
    double maxVal = results.map((r) => r.tokensPerSecond).reduce(max);
    if (maxVal < 10.0) maxVal = 10.0;
    
    final points = <Offset>[];
    final double dx = size.width / (results.length > 1 ? results.length - 1 : 1);
    
    for (int i = 0; i < results.length; i++) {
      final r = results[results.length - 1 - i]; // chronological order (oldest first for chart)
      final double x = i * dx;
      final double y = size.height - (r.tokensPerSecond / maxVal) * size.height;
      points.add(Offset(x, y));
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw bezier line path
    final path = Path();
    final fillPath = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX = (p1.dx + p2.dx) / 2;
        path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
        fillPath.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
      }
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Apply gradient fill
      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.25),
          lineColor.withOpacity(0.0),
        ],
      );
      fillPaint.shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);

      // Draw the line itself
      canvas.drawPath(path, paint);

      // Draw point circles
      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final outerPointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (final p in points) {
        canvas.drawCircle(p, 4, outerPointPaint);
        canvas.drawCircle(p, 2, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}

class GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final double angleOffset;
  final Color color;

  GaugePainter({
    required this.value,
    required this.maxValue,
    required this.angleOffset,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    // Draw background track arc
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      pi * 0.75,
      pi * 1.5,
      false,
      trackPaint,
    );

    // Draw active value arc
    final activeAngle = (value / maxValue).clamp(0.0, 1.0) * pi * 1.5;
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      pi * 0.75,
      activeAngle,
      false,
      activePaint,
    );

    // Draw animating rotating ticks/dots inside for active scanning effect
    final dotPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = angleOffset + (i * pi / 4);
      final offset = Offset(
        center.dx + (radius - 18) * cos(angle),
        center.dy + (radius - 18) * sin(angle),
      );
      canvas.drawCircle(offset, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) => true;
}
