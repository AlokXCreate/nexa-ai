import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_provider_config.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_usage_stats.dart';
import 'package:localmind_ai/features/plugins/presentation/controllers/cloud_settings_controller.dart';

class CloudSettingsScreen extends ConsumerStatefulWidget {
  const CloudSettingsScreen({super.key});

  @override
  ConsumerState<CloudSettingsScreen> createState() => _CloudSettingsScreenState();
}

class _CloudSettingsScreenState extends ConsumerState<CloudSettingsScreen> {
  final Map<String, bool> _obscureKeys = {};
  String? _expandedProviderId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cloudSettingsControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Build the sorted chain for display
    final activeChain = state.configs.where((c) => c.isEnabled).toList();
    activeChain.sort((a, b) => b.priority.compareTo(a.priority));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('Cloud AI Integrations', style: AppTypography.titleMedium),
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
            bottom: 60,
            left: 16,
            right: 16,
          ),
          children: [
            _buildIntroductionCard(),
            const SizedBox(height: 20),
            
            _buildSectionHeader('Fallback Execution Order'),
            const SizedBox(height: 10),
            _buildFallbackOrderCard(activeChain),
            const SizedBox(height: 24),

            _buildSectionHeader('API Providers'),
            const SizedBox(height: 10),
            if (state.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else
              ...state.configs.map((config) => _buildProviderSettingsCard(config, state)),

            const SizedBox(height: 24),
            _buildSectionHeader('Usage Statistics & Costs'),
            const SizedBox(height: 10),
            _buildUsageStatsCard(state.usageHistory),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.9),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildIntroductionCard() {
    return GlassContainer(
      borderRadius: 16,
      blur: 8,
      color: AppColors.surface.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hybrid Offline & Cloud Architecture',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect commercial remote services below. Nexa AI executes remote requests securely using client obfuscation. If connection failures occur, the system falls back to the next priority provider, terminating at the local GGUF model offline.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackOrderCard(List<CloudProviderConfig> activeChain) {
    return GlassContainer(
      borderRadius: 16,
      blur: 8,
      color: AppColors.surface.withOpacity(0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeChain.isEmpty)
            const Text(
              'No cloud APIs enabled. Always executing locally in GGUF sandbox.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
            )
          else ...[
            Text(
              'Active Fallback Chain:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < activeChain.length; i++) ...[
                    _buildChainNode(activeChain[i], i + 1),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.border, size: 16),
                  ],
                  _buildLocalOfflineNode(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChainNode(CloudProviderConfig config, int rank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '#$rank: ${config.name.split(' ').first}',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Priority: ${config.priority}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalOfflineNode() {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.emerald.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.emerald.withOpacity(0.3), width: 0.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Offline GGUF',
            style: TextStyle(color: Colors.emeraldAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          Text(
            'Final Target',
            style: TextStyle(color: Colors.grey, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSettingsCard(CloudProviderConfig config, CloudSettingsState state) {
    final isExpanded = _expandedProviderId == config.id;
    final testState = state.connectionTestState[config.id] ?? 'idle';
    final controller = ref.read(cloudSettingsControllerProvider.notifier);

    // Track obscured state locally
    if (!_obscureKeys.containsKey(config.id)) {
      _obscureKeys[config.id] = true;
    }

    final hasApiKey = config.id != 'ollama';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 16,
        blur: 10,
        color: config.isEnabled
            ? AppColors.surfaceElevated.withOpacity(0.5)
            : AppColors.surface.withOpacity(0.2),
        borderColor: config.isEnabled ? AppColors.primary.withOpacity(0.2) : AppColors.border,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Toggle row
            Row(
              children: [
                Icon(
                  _getProviderIcon(config.id),
                  color: config.isEnabled ? AppColors.primary : AppColors.textMuted,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      Text(
                        config.isEnabled ? 'Enabled (Priority: ${config.priority})' : 'Disabled',
                        style: TextStyle(
                            fontSize: 10,
                            color: config.isEnabled ? AppColors.primary : AppColors.textMuted,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: config.isEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    controller.toggleProvider(config.id, val);
                  },
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedProviderId = isExpanded ? null : config.id;
                    });
                  },
                ),
              ],
            ),

            // Settings body accordion
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 24, color: AppColors.border),

                        // API Key input (if applicable)
                        if (hasApiKey) ...[
                          const Text('API Access Key', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            obscureText: _obscureKeys[config.id]!,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: config.apiKeyObfuscated.isNotEmpty
                                  ? '••••••••••••••••••••••••••••••••'
                                  : 'Enter credentials key...',
                              hintStyle: const TextStyle(color: AppColors.textMuted),
                              fillColor: AppColors.background.withOpacity(0.5),
                              filled: true,
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureKeys[config.id]! ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureKeys[config.id] = !_obscureKeys[config.id]!;
                                  });
                                },
                              ),
                            ),
                            onChanged: (val) => controller.updateApiKey(config.id, val),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Endpoint base URL
                        const Text('API Base Endpoint URL', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: config.baseUrl,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            fillColor: AppColors.background.withOpacity(0.5),
                            filled: true,
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => controller.updateBaseUrl(config.id, val),
                        ),
                        const SizedBox(height: 14),

                        // Default model ID
                        const Text('Default Model ID', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: config.defaultModelId,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            fillColor: AppColors.background.withOpacity(0.5),
                            filled: true,
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => controller.updateDefaultModel(config.id, val),
                        ),
                        const SizedBox(height: 14),

                        // Sliders row (Priority & Timeout)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Priority Rank: ${config.priority}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Slider(
                                    value: config.priority.toDouble(),
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) => controller.updatePriority(config.id, val.toInt()),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Timeout: ${config.timeoutSeconds}s', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Slider(
                                    value: config.timeoutSeconds.toDouble(),
                                    min: 5,
                                    max: 60,
                                    divisions: 11,
                                    activeColor: Colors.orangeAccent,
                                    onChanged: (val) => controller.updateTimeout(config.id, val.toInt()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Max retries
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Auto-Retry limit on 429: ${config.maxRetries}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            SizedBox(
                              width: 140,
                              child: Slider(
                                value: config.maxRetries.toDouble(),
                                min: 0,
                                max: 5,
                                divisions: 5,
                                activeColor: Colors.emeraldAccent,
                                onChanged: (val) => controller.updateMaxRetries(config.id, val.toInt()),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Test connection widget
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTestConnectionStatusBadge(testState),
                            OutlinedButton.icon(
                              icon: testState == 'testing'
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                    )
                                  : const Icon(Icons.flash_on_rounded, size: 14),
                              label: const Text('Test Connection', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: testState == 'testing' ? null : () => controller.testConnection(config.id),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestConnectionStatusBadge(String testState) {
    if (testState == 'idle') {
      return const Text('Not tested', style: TextStyle(color: AppColors.textMuted, fontSize: 10));
    }
    if (testState == 'testing') {
      return const Text('Connecting endpoint...', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold));
    }
    if (testState == 'success') {
      return const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.emeraldAccent, size: 14),
          SizedBox(width: 4),
          Text('Connected successfully', style: TextStyle(color: Colors.emeraldAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            testState.replaceAll('failed: ', ''),
            style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageStatsCard(List<CloudUsageStats> usage) {
    final controller = ref.read(cloudSettingsControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalPrompt = usage.fold<int>(0, (sum, u) => sum + u.promptTokens);
    final totalGen = usage.fold<int>(0, (sum, u) => sum + u.generationTokens);
    final totalCost = usage.fold<double>(0.0, (sum, u) => sum + u.estimatedCost);

    return GlassContainer(
      borderRadius: 16,
      blur: 10,
      color: AppColors.surface.withOpacity(0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated Cloud Costs', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  Text(
                    '\$${totalCost.toStringAsFixed(5)}',
                    style: GoogleFonts.shareTechMono(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                label: const Text('Clear Stats', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: usage.isEmpty ? null : () => controller.clearUsageHistory(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatsBadge('Prompt Tokens', totalPrompt.toString()),
              const SizedBox(width: 8),
              _buildStatsBadge('Generated Tokens', totalGen.toString()),
              const SizedBox(width: 8),
              _buildStatsBadge('Total Calls', usage.length.toString()),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Recent Request Transactions', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: usage.isEmpty
                ? const Center(child: Text('No transactions recorded', style: TextStyle(color: AppColors.textMuted, fontSize: 11)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: usage.length,
                    itemBuilder: (context, index) {
                      final item = usage[usage.length - 1 - index]; // Descending
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.providerId.toUpperCase()} - ${item.modelId}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(
                                  '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')} • ${item.timestamp.day}/${item.timestamp.month}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${item.promptTokens + item.generationTokens} tokens', style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 10)),
                                Text('\$${item.estimatedCost.toStringAsFixed(6)}', style: GoogleFonts.shareTechMono(color: AppColors.primary, fontSize: 9)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadge(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(String providerId) {
    switch (providerId) {
      case 'openai':
        return Icons.auto_awesome_rounded;
      case 'anthropic':
        return Icons.psychology_rounded;
      case 'gemini':
        return Icons.rocket_launch_rounded;
      case 'openrouter':
        return Icons.router_rounded;
      case 'ollama':
        return Icons.terminal_rounded;
      case 'custom':
      default:
        return Icons.settings_input_component_rounded;
    }
  }
}
