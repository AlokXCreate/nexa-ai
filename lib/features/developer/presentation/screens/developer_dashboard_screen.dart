import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';
import 'package:localmind_ai/features/developer/presentation/controllers/developer_controller.dart';

class DeveloperDashboardScreen extends ConsumerWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devState = ref.watch(developerControllerProvider);
    final devController = ref.read(developerControllerProvider.notifier);
    final runtimeState = ref.watch(localRuntimeControllerProvider);
    final installedState = ref.watch(installedModelsControllerProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve Active Model Name
    final activeModel = installedState.installedModels.firstWhere(
      (m) => m.id == runtimeState.activeModelId,
      orElse: () => installedState.installedModels.isNotEmpty 
          ? installedState.installedModels.first 
          : const dynamic, // Fallback
    );
    final modelName = runtimeState.isModelLoaded ? activeModel.localName : 'No Active Model Loaded';

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
        title: const Text('Developer Console'),
        actions: [
          IconButton(
            tooltip: 'Trigger Test Inference',
            icon: const Icon(Icons.play_circle_outline_rounded),
            onPressed: runtimeState.isModelLoaded && !runtimeState.isGenerating
                ? () => ref.read(localRuntimeControllerProvider.notifier).generateText(
                    'Explain GGUF quantizations in one paragraph.',
                  )
                : null,
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
                    const Color(0xFF070514),
                    const Color(0xFF0F0B26),
                    const Color(0xFF020105),
                  ]
                : [
                    const Color(0xFFF3F5FC),
                    const Color(0xFFFAFBFC),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Current Loaded Model Banner
              _buildModelBanner(context, runtimeState, modelName),
              const SizedBox(height: 16),

              // 2. Hardware Resource Telemetry Grid
              _buildTelemetryGrid(context, devState),
              const SizedBox(height: 16),

              // 3. Execution Metrics & Tokens Statistics
              _buildMetricsPanel(context, devState),
              const SizedBox(height: 16),

              // 4. Benchmarking Panel
              _buildBenchmarkPanel(context, devState, devController),
              const SizedBox(height: 16),

              // 5. System Logs Terminal Console
              _buildLogsTerminal(context, devController, settingsState, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelBanner(BuildContext context, LocalRuntimeState state, String modelName) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: theme.colorScheme.surface.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: state.isModelLoaded ? primaryColor.withOpacity(0.15) : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              state.isModelLoaded ? Icons.psychology_rounded : Icons.psychology_outlined,
              color: state.isModelLoaded ? primaryColor : Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RUNTIME MODEL',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  modelName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (state.isModelLoaded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.emerald.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.emerald.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.emerald, size: 8),
                  SizedBox(width: 6),
                  Text(
                    'ACTIVE',
                    style: TextStyle(color: Colors.emerald, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(BuildContext context, DeveloperState state) {
    final t = state.telemetry;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildTelemetryCard(
          context: context,
          label: 'CPU USAGE',
          value: '${t.cpuUsagePercent.toStringAsFixed(1)}%',
          fraction: t.cpuUsagePercent / 100.0,
          color: Colors.cyanAccent,
          icon: Icons.cpu_rounded,
        ),
        _buildTelemetryCard(
          context: context,
          label: 'GPU LOAD',
          value: '${t.gpuUsagePercent.toStringAsFixed(1)}%',
          fraction: t.gpuUsagePercent / 100.0,
          color: Colors.purpleAccent,
          icon: Icons.developer_board_rounded,
        ),
        _buildTelemetryCard(
          context: context,
          label: 'RAM USAGE',
          value: '${(t.ramUsageMb / 1024.0).toStringAsFixed(2)} GB',
          fraction: (t.ramUsageMb / 4096.0).clamp(0.0, 1.0), // Max 4GB representation
          color: Colors.amberAccent,
          icon: Icons.memory_rounded,
        ),
        _buildTelemetryCard(
          context: context,
          label: 'LOCAL STORAGE',
          value: '${t.storageUsageGb.toStringAsFixed(1)} GB',
          fraction: (t.storageUsageGb / 256.0).clamp(0.0, 1.0), // Max 256GB representation
          color: Colors.emeraldAccent,
          icon: Icons.storage_rounded,
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required BuildContext context,
    required String label,
    required String value,
    required double fraction,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return GlassContainer(
      borderRadius: 16,
      blur: 8,
      color: theme.colorScheme.surface.withOpacity(0.3),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.textTheme.labelMedium?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsPanel(BuildContext context, DeveloperState state) {
    final t = state.telemetry;
    final theme = Theme.of(context);

    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: theme.colorScheme.surface.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFERENCE TELEMETRY METRICS',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(context, 'Tokens/s', t.tokensPerSecond.toStringAsFixed(1), Colors.cyanAccent),
              _buildMetricItem(context, 'Inference Speed', '${t.timeToFirstTokenMs} ms', Colors.purpleAccent),
              _buildMetricItem(context, 'Session Tokens', '${t.conversationTokens}', Colors.amberAccent),
              _buildMetricItem(context, 'Context Window', '${t.contextSize} / 8K', Colors.emeraldAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, Color accentColor) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 10,
              color: theme.textTheme.labelMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 2,
            color: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkPanel(BuildContext context, DeveloperState state, DeveloperController controller) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: theme.colorScheme.surface.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, color: theme.colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'GGUF PERFORMANCE BENCHMARKS',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isBenchmarking) ...[
            Column(
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  state.benchmarkStep,
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ] else if (state.benchmarkResult != null) ...[
            _buildBenchmarkResultCard(context, state.benchmarkResult!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => controller.runBenchmark(),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Re-Run Telemetry Benchmark'),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Run a multi-step execution benchmark testing single-thread speeds and memory bandwidth limits.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () => controller.runBenchmark(),
                  child: const Text('Run Benchmark'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenchmarkResultCard(BuildContext context, BenchmarkResult res) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPOSITE GRADE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.labelMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      res.grade,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'CORTEX SCORE',
                    style: theme.textTheme.labelMedium?.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${res.overallScore}',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBenchmarkStat('Single-Thread', '${res.singleThreadSpeed.toStringAsFixed(1)} T/s'),
              _buildBenchmarkStat('Multi-Thread', '${res.multiThreadSpeed.toStringAsFixed(1)} T/s'),
              _buildBenchmarkStat('Mem Bandwidth', '${res.memoryBandwidth.toStringAsFixed(1)} GB/s'),
              _buildBenchmarkStat('RAM Peak', '${(res.ramPeakMb / 1024.0).toStringAsFixed(1)} GB'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLogsTerminal(
    BuildContext context,
    DeveloperController controller,
    SettingsState settingsState,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final logs = settingsState.debugLogs;

    return GlassContainer(
      borderRadius: 20,
      blur: 10,
      color: theme.colorScheme.surface.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SYSTEM TRANSACTION LOGS',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Export Log File',
                    icon: const Icon(Icons.ios_share_rounded, size: 20, color: Colors.cyanAccent),
                    onPressed: () async {
                      final path = await controller.exportLogs();
                      if (path != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Logs exported successfully to: $path'),
                            backgroundColor: Colors.emerald,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Clear History',
                    icon: const Icon(Icons.clear_all_rounded, size: 20, color: Colors.redAccent),
                    onPressed: () => ref.read(settingsControllerProvider.notifier).clearLogs(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No transaction logs registered.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          logs[index],
                          style: GoogleFonts.shareTechMono(
                            color: Colors.greenAccent,
                            fontSize: 11.5,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
