import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_provider_config.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_usage_stats.dart';
import 'package:localmind_ai/features/plugins/domain/repositories/cloud_config_repository.dart';

class CloudConfigRepositoryImpl implements CloudConfigRepository {
  static const String configBoxName = 'cloudConfigsBox';
  static const String usageBoxName = 'cloudUsageStatsBox';

  Future<Box> _getConfigBox() async {
    if (!Hive.isBoxOpen(configBoxName)) {
      return await Hive.openBox(configBoxName);
    }
    return Hive.box(configBoxName);
  }

  Future<Box> _getUsageBox() async {
    if (!Hive.isBoxOpen(usageBoxName)) {
      return await Hive.openBox(usageBoxName);
    }
    return Hive.box(usageBoxName);
  }

  @override
  Future<void> saveConfig(CloudProviderConfig config) async {
    final box = await _getConfigBox();
    await box.put(config.id, config.toMap());
  }

  @override
  Future<CloudProviderConfig?> getConfigById(String providerId) async {
    final box = await _getConfigBox();
    final data = box.get(providerId);
    if (data == null) return null;
    return CloudProviderConfig.fromMap(data as Map);
  }

  @override
  Future<List<CloudProviderConfig>> getConfigs() async {
    final box = await _getConfigBox();
    if (box.isEmpty) {
      await _prepopulateDefaultConfigs(box);
    }
    return box.values.map((map) => CloudProviderConfig.fromMap(map as Map)).toList();
  }

  @override
  Future<void> saveUsage(CloudUsageStats usage) async {
    final box = await _getUsageBox();
    await box.add(usage.toMap());
  }

  @override
  Future<List<CloudUsageStats>> getUsageHistory() async {
    final box = await _getUsageBox();
    return box.values.map((map) => CloudUsageStats.fromMap(map as Map)).toList();
  }

  @override
  Future<void> clearUsage() async {
    final box = await _getUsageBox();
    await box.clear();
  }

  Future<void> _prepopulateDefaultConfigs(Box box) async {
    final defaults = [
      const CloudProviderConfig(
        id: 'openai',
        name: 'OpenAI Compatible API',
        apiKeyObfuscated: '',
        baseUrl: 'https://api.openai.com/v1',
        isEnabled: false,
        priority: 6,
        defaultModelId: 'gpt-4o-mini',
        timeoutSeconds: 15,
        maxRetries: 2,
      ),
      const CloudProviderConfig(
        id: 'anthropic',
        name: 'Anthropic Compatible API',
        apiKeyObfuscated: '',
        baseUrl: 'https://api.anthropic.com/v1',
        isEnabled: false,
        priority: 5,
        defaultModelId: 'claude-3-5-sonnet-20241022',
        timeoutSeconds: 15,
        maxRetries: 2,
      ),
      const CloudProviderConfig(
        id: 'gemini',
        name: 'Google Gemini API',
        apiKeyObfuscated: '',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        isEnabled: false,
        priority: 4,
        defaultModelId: 'gemini-1.5-flash',
        timeoutSeconds: 15,
        maxRetries: 2,
      ),
      const CloudProviderConfig(
        id: 'openrouter',
        name: 'OpenRouter AI API',
        apiKeyObfuscated: '',
        baseUrl: 'https://openrouter.ai/api/v1',
        isEnabled: false,
        priority: 3,
        defaultModelId: 'meta-llama/llama-3.1-8b-instruct:free',
        timeoutSeconds: 20,
        maxRetries: 2,
      ),
      const CloudProviderConfig(
        id: 'ollama',
        name: 'Ollama Local/Remote Server',
        apiKeyObfuscated: '',
        baseUrl: 'http://localhost:11434/api',
        isEnabled: false,
        priority: 2,
        defaultModelId: 'llama3',
        timeoutSeconds: 10,
        maxRetries: 1,
      ),
      const CloudProviderConfig(
        id: 'custom',
        name: 'Custom OpenAI-compatible Server',
        apiKeyObfuscated: '',
        baseUrl: '',
        isEnabled: false,
        priority: 1,
        defaultModelId: '',
        timeoutSeconds: 15,
        maxRetries: 2,
      ),
    ];

    for (final cfg in defaults) {
      await box.put(cfg.id, cfg.toMap());
    }
  }
}

final cloudConfigRepositoryProvider = Provider<CloudConfigRepository>((ref) {
  return CloudConfigRepositoryImpl();
});
