import 'package:localmind_ai/features/plugins/domain/entities/plugin_manifest.dart';

abstract class PluginRepository {
  Future<void> savePlugin(PluginManifest plugin);
  Future<void> deletePlugin(String pluginId);
  Future<List<PluginManifest>> getPlugins();
  Future<PluginManifest?> getPluginById(String pluginId);
}
