import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/plugins/domain/entities/performance_snapshot.dart';
import 'package:localmind_ai/features/developer/presentation/controllers/analytics_controller.dart';
import 'package:localmind_ai/features/developer/presentation/screens/widgets/custom_chart_painters.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final report = state.report;

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
        title: Text(
          'Unified Analytics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Purge Metrics Logs',
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            onPressed: () => _showClearConfirmation(context, controller),
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
                    const Color(0xFF060414),
                    const Color(0xFF0F0822),
                    const Color(0xFF020104),
                  ]
                : [
                    const Color(0xFFF1F3FB),
                    const Color(0xFFFAFBFC),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. Unified Analytics Summary HUD
                    _buildSummaryHUD(context, state),
                    const SizedBox(height: 20),

                    // 2. CSV / PDF Export tools
                    _buildExportToolbar(context, controller),
                    const SizedBox(height: 20),

                    // 3. Weekly & Monthly Reports expansion panels
                    _buildReportsPanel(context, state),
                    const SizedBox(height: 20),

                    // 4. Tab Selector for Charts
                    _buildTabSelector(context, state, controller),
                    const SizedBox(height: 16),

                    // 5. Active Chart Canvas
                    _buildChartCanvas(context, state),
                    const SizedBox(height: 24),

                    // 6. Historical Telemetry logs list
                    _buildInferenceLogs(context, state.history),
                  ],
                ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, AnalyticsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0E23),
        title: Text('Clear Telemetry Logs?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text(
          'This will purge all telemetry snapshots from the database logs. Active chat and download histories will remain unaffected.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              controller.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear Log'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHUD(BuildContext context, AnalyticsState state) {
    final report = state.report;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildHUDCard(context, 'MEAN RESPONSE TIME', '${(report.averageResponseTimeMs / 1000).toStringAsFixed(2)}s', Colors.cyanAccent, Icons.timer_rounded),
        _buildHUDCard(context, 'AVG INFERENCE SPEED', '${report.averageInferenceSpeed.toStringAsFixed(1)} T/s', Colors.amberAccent, Icons.speed_rounded),
        _buildHUDCard(context, 'ACTIVE STORAGE FOOTPRINT', '${report.totalStorageUsedGb.toStringAsFixed(2)} GB', Colors.greenAccent, Icons.storage_rounded),
        _buildHUDCard(context, 'CONVERSATIONS ENGAGED', '${report.totalConversations} (${report.totalMessages} msgs)', Colors.purpleAccent, Icons.chat_bubble_outline_rounded),
      ],
    );
  }

  Widget _buildHUDCard(BuildContext context, String label, String value, Color accentColor, IconData icon) {
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
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: theme.textTheme.labelMedium?.color?.withOpacity(0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 20, height: 2, color: accentColor),
        ],
      ),
    );
  }

  Widget _buildExportToolbar(BuildContext context, AnalyticsController controller) {
    final theme = Theme.of(context);
    return GlassContainer(
      borderRadius: 16,
      blur: 10,
      color: theme.colorScheme.surface.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DATA EXPORT TOOLBAR',
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  final path = await controller.exportCSV();
                  if (path != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('CSV Telemetry data exported to: $path'), backgroundColor: Colors.emerald),
                    );
                  }
                },
                icon: const Icon(Icons.file_download_outlined, size: 18, color: Colors.cyanAccent),
                label: const Text('CSV', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () async {
                  final path = await controller.exportPDF();
                  if (path != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF Report exported to: $path'), backgroundColor: Colors.emerald),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.purpleAccent),
                label: const Text('PDF', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsPanel(BuildContext context, AnalyticsState state) {
    final report = state.report;
    return Column(
      children: [
        _buildReportCard(
          context,
          'Weekly Summary Report',
          report.weeklyReportSummary,
          Colors.cyanAccent.withOpacity(0.1),
          Colors.cyanAccent,
        ),
        const SizedBox(height: 12),
        _buildReportCard(
          context,
          'Monthly Pruning Recommendation',
          report.monthlyReportSummary,
          Colors.purpleAccent.withOpacity(0.1),
          Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String content, Color bgColor, Color accentColor) {
    return GlassContainer(
      borderRadius: 16,
      blur: 8,
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: accentColor,
        collapsedIconColor: accentColor.withOpacity(0.7),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              content.isEmpty ? 'No telemetry logged for report.' : content,
              style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context, AnalyticsState state, AnalyticsController controller) {
    final tabs = ['Token Speed', 'Hardware Load', 'Storage / Prompt', 'Model Usage'];
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = state.selectedTab == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => controller.selectTab(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface.withOpacity(0.3),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartCanvas(BuildContext context, AnalyticsState state) {
    final theme = Theme.of(context);
    final history = state.history;

    if (history.isEmpty) {
      return GlassContainer(
        borderRadius: 20,
        blur: 10,
        color: theme.colorScheme.surface.withOpacity(0.4),
        height: 240,
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text('No historical snapshots available.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return GlassContainer(
      borderRadius: 24,
      blur: 12,
      color: theme.colorScheme.surface.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: _renderActiveChart(state),
      ),
    );
  }

  Widget _renderActiveChart(AnalyticsState state) {
    final history = state.history;
    final report = state.report;
    
    switch (state.selectedTab) {
      case 0: // Token Speed Line Chart
        final speeds = history.map((s) => s.tokenSpeed).toList();
        return CustomPaint(
          painter: LineChartPainter(
            dataPoints: speeds,
            label: 'Token Speed (T/s)',
            lineColor: Colors.cyanAccent,
          ),
        );

      case 1: // Hardware Loads (CPU & GPU) Area Charts
        final points = history
            .asMap()
            .entries
            .map((entry) => Offset(entry.key.toDouble(), entry.value.cpuUsagePercent))
            .toList();
        return CustomPaint(
          painter: AreaChartPainter(
            points: points,
            areaColor: Colors.purpleAccent,
          ),
        );

      case 2: // Storage Usage vs Prompt length density donut gauges
        final avgPrompt = report.averagePromptLengthWords / 200.0; // scale fraction
        return Row(
          children: [
            Expanded(
              child: CustomPaint(
                painter: DonutChartPainter(
                  percentage: avgPrompt.clamp(0.05, 1.0),
                  centerLabel: '${report.averagePromptLengthWords.toStringAsFixed(1)} w',
                  ringColor: Colors.amberAccent,
                ),
              ),
            ),
            Expanded(
              child: CustomPaint(
                painter: DonutChartPainter(
                  percentage: (report.totalStorageUsedGb / 128.0).clamp(0.05, 1.0), // 128GB capacity ratio representation
                  centerLabel: '${report.totalStorageUsedGb.toStringAsFixed(1)} GB',
                  ringColor: Colors.greenAccent,
                ),
              ),
            ),
          ],
        );

      case 3: // Model Usage Count Bar Chart
        final keys = report.modelUsageCounts.keys.toList();
        final vals = report.modelUsageCounts.values.map((v) => v.toDouble()).toList();

        // Standard placeholders if empty
        final barVals = vals.isNotEmpty ? vals : [24.0, 12.0];
        final barLabels = keys.isNotEmpty ? keys.map((k) => k.replaceAll('_', ' ').toUpperCase()).toList() : ['LLAMA 3.2 3B', 'DEEPSEEK 1.5B'];

        return CustomPaint(
          painter: BarChartPainter(
            values: barVals,
            labels: barLabels,
            barColor: Colors.cyanAccent,
          ),
        );

      default:
        return const Center(child: Text('Chart not found'));
    }
  }

  Widget _buildInferenceLogs(BuildContext context, List<PerformanceSnapshot> history) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'HISTORICAL INFERENCE LOGS',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (history.isEmpty)
          const Center(child: Text('No telemetry snapshots logged.', style: TextStyle(color: Colors.white38)))
        else
          ...history.reversed.map((s) {
            final speed = s.tokenSpeed.toStringAsFixed(1);
            final name = s.modelId == 'deepseek_coder' ? 'DeepSeek Coder 1.5B' : 'Llama 3.2 3B';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.white.withOpacity(0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.cyanAccent,
                    size: 20,
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                subtitle: Text(
                  'Size: ${s.promptLength} words • Latency: ${s.generationTimeMs}ms • RAM: ${s.memoryUsageMb.toStringAsFixed(0)}MB',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                trailing: Text(
                  '$speed T/s',
                  style: GoogleFonts.shareTechMono(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
