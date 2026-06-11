import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_session.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_sessions_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/plugins/presentation/controllers/cloud_settings_controller.dart';

class ParameterConfigPanel extends ConsumerStatefulWidget {
  final ChatSession session;

  const ParameterConfigPanel({super.key, required this.session});

  @override
  ConsumerState<ParameterConfigPanel> createState() => _ParameterConfigPanelState();
}

class _ParameterConfigPanelState extends ConsumerState<ParameterConfigPanel> {
  late TextEditingController _systemPromptController;
  late double _temperature;
  late double _topP;
  late double _maxTokens;
  late bool _useRag;

  @override
  void initState() {
    super.initState();
    _systemPromptController = TextEditingController(text: widget.session.systemPrompt ?? '');
    _temperature = widget.session.temperature ?? 0.7;
    _topP = widget.session.topP ?? 0.9;
    _maxTokens = (widget.session.maxTokens ?? 512).toDouble();
    _useRag = widget.session.useRag ?? true;
  }

  @override
  void didUpdateWidget(ParameterConfigPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id) {
      _systemPromptController.text = widget.session.systemPrompt ?? '';
      _temperature = widget.session.temperature ?? 0.7;
      _topP = widget.session.topP ?? 0.9;
      _maxTokens = (widget.session.maxTokens ?? 512).toDouble();
      _useRag = widget.session.useRag ?? true;
    }
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  void _saveParams() {
    ref.read(chatSessionsControllerProvider.notifier).updateSessionParams(
      widget.session.id,
      systemPrompt: _systemPromptController.text.trim().isEmpty ? null : _systemPromptController.text.trim(),
      temperature: _temperature,
      topP: _topP,
      maxTokens: _maxTokens.toInt(),
      useRag: _useRag,
      clearSystemPrompt: _systemPromptController.text.trim().isEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final installedState = ref.watch(installedModelsControllerProvider);
    final cloudState = ref.watch(cloudSettingsControllerProvider);

    final dropdownItems = <DropdownMenuItem<String>>[];

    // Local Models
    if (installedState.installedModels.isNotEmpty) {
      dropdownItems.add(const DropdownMenuItem<String>(
        enabled: false,
        value: '__local_header__',
        child: Text(
          'Local Offline Models (GGUF)',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ));
      for (final model in installedState.installedModels) {
        dropdownItems.add(DropdownMenuItem<String>(
          value: model.id,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(model.localName, style: const TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ));
      }
    }

    // Cloud Providers
    final activeCloudConfigs = cloudState.configs.where((c) => c.isEnabled).toList();
    if (activeCloudConfigs.isNotEmpty) {
      dropdownItems.add(const DropdownMenuItem<String>(
        enabled: false,
        value: '__cloud_header__',
        child: Text(
          'Cloud API Models',
          style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ));
      for (final config in activeCloudConfigs) {
        dropdownItems.add(DropdownMenuItem<String>(
          value: config.id,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text('${config.name} (${config.defaultModelId})', style: const TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ));
      }
    }

    final currentModelId = widget.session.modelId;
    final modelExists = dropdownItems.any((item) => item.value == currentModelId);
    if (!modelExists) {
      dropdownItems.insert(0, DropdownMenuItem<String>(
        value: currentModelId,
        child: Text(currentModelId.replaceAll('_', ' '), style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ));
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: 0,
        blur: 20,
        color: AppColors.background.withOpacity(0.95),
        padding: const EdgeInsets.only(top: kToolbarHeight + 10, left: 16, right: 16, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Session Parameters', style: AppTypography.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // Model Selection Dropdown
                  const Text('Active Model', style: TextStyle(color: Colors.white75, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentModelId,
                        dropdownColor: AppColors.surfaceElevated,
                        isExpanded: true,
                        items: dropdownItems,
                        onChanged: (val) {
                          if (val != null && !val.startsWith('__')) {
                            ref.read(chatSessionsControllerProvider.notifier).updateSessionModel(widget.session.id, val);
                          }
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 32),

                  // RAG toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Use Knowledge Base (RAG)', style: AppTypography.bodyLarge),
                          const Text('Search active documents in queries', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                      Switch(
                        value: _useRag,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _useRag = val);
                          _saveParams();
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // System Prompt
                  Text('System Instructions', style: AppTypography.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _systemPromptController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. You are a helpful, local programming assistant...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      fillColor: AppColors.surface.withOpacity(0.3),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                    onChanged: (_) => _saveParams(),
                  ),
                  const SizedBox(height: 24),

                  // Temperature
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Temperature: ${_temperature.toStringAsFixed(1)}', style: AppTypography.bodyMedium),
                      Text(
                        _temperature < 0.4 ? 'Focused' : (_temperature > 1.0 ? 'Creative' : 'Balanced'),
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _temperature,
                    min: 0.1,
                    max: 1.5,
                    divisions: 14,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _temperature = val);
                      _saveParams();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Top P
                  Text('Top-P: ${_topP.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                  Slider(
                    value: _topP,
                    min: 0.1,
                    max: 1.0,
                    divisions: 18,
                    activeColor: AppColors.secondary,
                    onChanged: (val) {
                      setState(() => _topP = val);
                      _saveParams();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Max Tokens
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Max Tokens: ${_maxTokens.toInt()}', style: AppTypography.bodyMedium),
                    ],
                  ),
                  Slider(
                    value: _maxTokens,
                    min: 64,
                    max: 2048,
                    divisions: 31,
                    activeColor: Colors.orangeAccent,
                    onChanged: (val) {
                      setState(() => _maxTokens = val);
                      _saveParams();
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Restore Defaults button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Restore Session Defaults'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _systemPromptController.clear();
                        _temperature = 0.7;
                        _topP = 0.9;
                        _maxTokens = 512;
                        _useRag = true;
                      });
                      _saveParams();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
