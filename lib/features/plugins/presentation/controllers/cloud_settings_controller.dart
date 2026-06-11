import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/chat/data/services/cloud_inference_service.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_provider_config.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_usage_stats.dart';
import 'package:localmind_ai/features/plugins/domain/repositories/cloud_config_repository.dart';
import 'package:localmind_ai/features/plugins/data/repositories/cloud_config_repository_impl.dart';

class CloudSettingsState {
  final List<CloudProviderConfig> configs;
  final List<CloudUsageStats> usageHistory;
  final Map<String, String> connectionTestState; // 'idle' | 'testing' | 'success' | 'failed: <err>'
  final bool isLoading;
  final String? error;

  const CloudSettingsState({
    this.configs = const [],
    this.usageHistory = const [],
    this.connectionTestState = const {},
    this.isLoading = false,
    this.error,
  });

  CloudSettingsState copyWith({
    List<CloudProviderConfig>? configs,
    List<CloudUsageStats>? usageHistory,
    Map<String, String>? connectionTestState,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CloudSettingsState(
      configs: configs ?? this.configs,
      usageHistory: usageHistory ?? this.usageHistory,
      connectionTestState: connectionTestState ?? this.connectionTestState,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CloudSettingsController extends StateNotifier<CloudSettingsState> {
  final CloudConfigRepository _repository;
  final CloudInferenceService _cloudInference;

  CloudSettingsController(this._repository, this._cloudInference)
      : super(const CloudSettingsState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getConfigs();
      list.sort((a, b) => b.priority.compareTo(a.priority));

      final testStates = <String, String>{};
      for (final cfg in list) {
        testStates[cfg.id] = 'idle';
      }

      final usage = await _repository.getUsageHistory();

      state = state.copyWith(
        configs: list,
        usageHistory: usage,
        connectionTestState: testStates,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load cloud settings: $e');
    }
  }

  Future<void> updateApiKey(String id, String rawKey) async {
    try {
      final config = state.configs.firstWhere((c) => c.id == id);
      final updated = config.copyWith(apiKeyObfuscated: CloudProviderConfig.obfuscateKey(rawKey));
      await _repository.saveConfig(updated);
      await _refreshConfigs();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update API key: $e');
    }
  }

  Future<void> toggleProvider(String id, bool enabled) async {
    try {
      final config = state.configs.firstWhere((c) => c.id == id);
      final updated = config.copyWith(isEnabled: enabled);
      await _repository.saveConfig(updated);
      await _refreshConfigs();
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle provider: $e');
    }
  }

  Future<void> updatePriority(String id, int priority) async {
    try {
      final config = state.configs.firstWhere((c) => c.id == id);
      final updated = config.copyWith(priority: priority);
      await _repository.saveConfig(updated);
      await _refreshConfigs();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update priority: $e');
    }
  }

  Future<void> updateBaseUrl(String id, String baseUrl) async {
    try {
      final config = state.configs.firstWhere((c) => c.id == id);
      final updated = config.copyWith(baseUrl: baseUrl.trim());
      await _repository.saveConfig(updated);
      await _refreshConfigs();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update Base URL: $e');
    }
  }

  Future<void> updateDefaultModel(String id, String defaultModelId) async {
    try {
      final config = state.configs.firstWhere((c) => c.id == id);
      final updated = config.copyWith(defaultModelId: defaultModelId.trim());
      await _repository.saveConfig(updated);
      await _refreshConfigs();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update default model ID: $e');
    }
  }

  Future<void> updateTimeout(String id, int timeoutSeconds) async {
    try {
      final config = state.configs.firstWhere((c) => c.id == id);
      final updated = config.copyWith(timeoutSeconds: timeoutSeconds);
      await _repository.saveConfig(updated);
      await _refreshConfigs();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update timeout: $e');
    }
  }

  Future<void> updateMaxRetries(String id, int maxRetries) async {
    try {
      final config = state.configs.firstWhere((c) => c.id == id);
      final updated = config.copyWith(maxRetries: maxRetries);
      await _repository.saveConfig(updated);
      await _refreshConfigs();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update max retries: $e');
    }
  }

  Future<void> testConnection(String providerId) async {
    state = state.copyWith(
      connectionTestState: {...state.connectionTestState, providerId: 'testing'},
    );

    try {
      final config = state.configs.firstWhere((c) => c.id == providerId);
      
      // Attempt a simple ping stream with 1 token
      final testStream = _cloudInference.streamCloudInference(
        config: config,
        prompt: 'Say OK and nothing else',
        modelOverride: config.defaultModelId,
      );

      final completer = Completer<void>();
      StreamSubscription? sub;
      sub = testStream.listen(
        (token) {
          sub?.cancel();
          if (!completer.isCompleted) completer.complete();
        },
        onError: (err) {
          sub?.cancel();
          if (!completer.isCompleted) completer.completeError(err);
        },
        onDone: () {
          sub?.cancel();
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future.timeout(Duration(seconds: config.timeoutSeconds));
      
      state = state.copyWith(
        connectionTestState: {...state.connectionTestState, providerId: 'success'},
      );
    } catch (e) {
      state = state.copyWith(
        connectionTestState: {...state.connectionTestState, providerId: 'failed: $e'},
      );
    }
  }

  Future<void> loadUsageHistory() async {
    try {
      final usage = await _repository.getUsageHistory();
      state = state.copyWith(usageHistory: usage);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load usage history: $e');
    }
  }

  Future<void> clearUsageHistory() async {
    try {
      await _repository.clearUsage();
      state = state.copyWith(usageHistory: []);
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear usage logs: $e');
    }
  }

  Future<void> _refreshConfigs() async {
    final list = await _repository.getConfigs();
    list.sort((a, b) => b.priority.compareTo(a.priority));
    state = state.copyWith(configs: list);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final cloudSettingsControllerProvider =
    StateNotifierProvider<CloudSettingsController, CloudSettingsState>((ref) {
  final repo = ref.watch(cloudConfigRepositoryProvider);
  final inference = ref.watch(cloudInferenceServiceProvider);
  return CloudSettingsController(repo, inference);
});
