import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:localmind_ai/features/plugins/domain/repositories/plugin_repository.dart';
import 'package:localmind_ai/features/plugins/data/services/plugin_manager.dart';

class PluginsState {
  final List<PluginManifest> plugins;
  final bool isLoading;
  final String? error;
  final String selectedCategory; // 'All', 'Models', 'Themes', 'Widgets', 'Tools', 'Prompts', 'Knowledge'

  const PluginsState({
    this.plugins = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'All',
  });

  PluginsState copyWith({
    List<PluginManifest>? plugins,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) {
    return PluginsState(
      plugins: plugins ?? this.plugins,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class PluginsController extends StateNotifier<PluginsState> {
  final PluginRepository _repository;
  final PluginManager _pluginManager;

  PluginsController(this._repository, this._pluginManager) : super(const PluginsState()) {
    loadPlugins();
  }

  Future<void> loadPlugins() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repository.getPlugins();
      state = state.copyWith(plugins: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load plugins: $e');
    }
  }

  Future<void> installPlugin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _pluginManager.installPlugin(id);
      await loadPlugins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to install plugin: $e');
    }
  }

  Future<void> enablePlugin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _pluginManager.enablePlugin(id);
      await loadPlugins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to enable plugin: $e');
    }
  }

  Future<void> disablePlugin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _pluginManager.disablePlugin(id);
      await loadPlugins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to disable plugin: $e');
    }
  }

  Future<void> uninstallPlugin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _pluginManager.uninstallPlugin(id);
      await loadPlugins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to uninstall plugin: $e');
    }
  }

  Future<void> updatePlugin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plugin = await _repository.getPluginById(id);
      if (plugin != null) {
        // Mocking dynamic updates: increment patch version
        final parts = plugin.version.split('.');
        if (parts.length == 3) {
          final patch = int.tryParse(parts[2]) ?? 0;
          final newVersion = '${parts[0]}.${parts[1]}.${patch + 1}';
          final updated = plugin.copyWith(version: newVersion);
          await _repository.savePlugin(updated);
          
          // Re-inject if it was enabled so that contents are up-to-date
          if (plugin.isEnabled) {
            await _pluginManager.enablePlugin(id);
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 800)); // Premium update UX latency
      await loadPlugins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update plugin: $e');
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  List<PluginManifest> get filteredPlugins {
    if (state.selectedCategory == 'All') {
      return state.plugins;
    }
    return state.plugins.where((p) => p.category == state.selectedCategory).toList();
  }
}

final pluginsControllerProvider = StateNotifierProvider<PluginsController, PluginsState>((ref) {
  final repo = ref.watch(pluginRepositoryProvider);
  final manager = ref.watch(pluginManagerProvider);
  return PluginsController(repo, manager);
});
