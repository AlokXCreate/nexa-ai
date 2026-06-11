import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:localmind_ai/features/plugins/domain/repositories/plugin_repository.dart';
import 'package:localmind_ai/features/plugins/data/repositories/plugin_repository_impl.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/installed_model.dart';
import 'package:localmind_ai/features/chat/domain/entities/prompt_template.dart';
import 'package:localmind_ai/features/chat/domain/entities/knowledge_note.dart';
import 'package:localmind_ai/features/agents/data/services/agent_tool_service.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/prompt_library_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/knowledge_base_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';

class PluginManager {
  final PluginRepository _repository;
  final Ref _ref;

  PluginManager(this._repository, this._ref);

  Future<void> installPlugin(String id) async {
    final plugin = await _repository.getPluginById(id);
    if (plugin == null) return;

    final updated = plugin.copyWith(isInstalled: true, isEnabled: false);
    await _repository.savePlugin(updated);
  }

  Future<void> enablePlugin(String id) async {
    final plugin = await _repository.getPluginById(id);
    if (plugin == null) return;

    final updated = plugin.copyWith(isEnabled: true);
    await _repository.savePlugin(updated);

    // Inject dynamic content
    await _injectPluginContent(updated);
  }

  Future<void> disablePlugin(String id) async {
    final plugin = await _repository.getPluginById(id);
    if (plugin == null) return;

    final updated = plugin.copyWith(isEnabled: false);
    await _repository.savePlugin(updated);

    // Remove dynamic content
    await _removePluginContent(plugin);
  }

  Future<void> uninstallPlugin(String id) async {
    final plugin = await _repository.getPluginById(id);
    if (plugin == null) return;

    // If enabled, disable first to clean up
    if (plugin.isEnabled) {
      await disablePlugin(id);
    }

    final updated = plugin.copyWith(isInstalled: false, isEnabled: false);
    await _repository.savePlugin(updated);
  }

  Future<bool> verifyPermission(String pluginId, String permission) async {
    final plugin = await _repository.getPluginById(pluginId);
    if (plugin == null) return false;
    return plugin.isEnabled && plugin.permissions.contains(permission);
  }

  Future<void> _injectPluginContent(PluginManifest plugin) async {
    final content = plugin.content;

    switch (plugin.category) {
      case 'Themes':
        final primary = content['primary'] as String?;
        final accent = content['accent'] as String?;
        final background = content['background'] as String?;
        final surface = content['surface'] as String?;
        
        await _ref.read(settingsControllerProvider.notifier).updateCustomColors(
              primary: primary,
              accent: accent,
              bg: background,
              surface: surface,
            );
        break;

      case 'Models':
        if (content.containsKey('model')) {
          final modelData = content['model'] as Map;
          final installedModel = InstalledModel(
            id: modelData['id'] as String,
            localName: modelData['localName'] as String,
            developer: modelData['developer'] as String,
            version: modelData['version'] as String,
            sizeString: modelData['sizeString'] as String,
            sizeInGb: (modelData['sizeInGb'] as num).toDouble(),
            ramRequirement: modelData['ramRequirement'] as String,
            filePath: modelData['filePath'] as String,
            lastUsed: DateTime.now(),
          );
          
          final box = await Hive.openBox('installedModelsBox');
          await box.put(installedModel.id, installedModel.toMap());
          
          // Reload controller
          _ref.read(installedModelsControllerProvider.notifier).fetchInstalledModels();
        }
        break;

      case 'Prompts':
        if (content.containsKey('prompts')) {
          final promptsList = content['prompts'] as List;
          final box = await Hive.openBox('promptTemplatesBox');
          
          for (final pMap in promptsList) {
            final p = pMap as Map;
            final id = 'tpl_plugin_${plugin.id}_${p['title'].hashCode}';
            final tpl = PromptTemplate(
              id: id,
              title: p['title'] as String,
              content: p['content'] as String,
              isFavorite: false,
              isPinned: false,
              category: 'library',
              lastUsed: DateTime.now(),
              createdAt: DateTime.now(),
            );
            await box.put(id, tpl.toMap());
          }
          
          // Reload controller
          _ref.read(promptLibraryControllerProvider.notifier).loadTemplates();
        }
        break;

      case 'Knowledge':
        if (content.containsKey('articles')) {
          final articlesList = content['articles'] as List;
          final box = await Hive.openBox('knowledgeNotesBox');
          
          for (final aMap in articlesList) {
            final a = aMap as Map;
            final id = 'note_plugin_${plugin.id}_${a['title'].hashCode}';
            final tagsRaw = a['tags'] as List?;
            final List<String> tags = tagsRaw != null ? tagsRaw.map((e) => e.toString()).toList() : [];
            
            final note = KnowledgeNote(
              id: id,
              title: a['title'] as String,
              content: a['content'] as String,
              collectionId: null,
              category: 'Plugin Pack',
              tags: tags,
              isPinned: false,
              isFavorite: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await box.put(id, note.toMap());
          }
          
          // Reload controller
          _ref.read(knowledgeBaseControllerProvider.notifier).loadAll();
        }
        break;

      case 'Tools':
        if (content.containsKey('tool')) {
          final toolData = content['tool'] as Map;
          final paramsRaw = toolData['parameters'] as List?;
          final List<String> params = paramsRaw != null ? paramsRaw.map((e) => e.toString()).toList() : [];
          
          final tool = AgentTool(
            id: toolData['id'] as String,
            name: toolData['name'] as String,
            description: toolData['description'] as String,
            parameters: params,
          );
          AgentToolService.registerPluginTool(tool);
        }
        break;

      default:
        break;
    }
  }

  Future<void> _removePluginContent(PluginManifest plugin) async {
    final content = plugin.content;

    switch (plugin.category) {
      case 'Themes':
        await _ref.read(settingsControllerProvider.notifier).clearCustomColors();
        break;

      case 'Models':
        if (content.containsKey('model')) {
          final modelData = content['model'] as Map;
          final modelId = modelData['id'] as String;
          
          final box = await Hive.openBox('installedModelsBox');
          await box.delete(modelId);
          
          // Reload controller
          _ref.read(installedModelsControllerProvider.notifier).fetchInstalledModels();
        }
        break;

      case 'Prompts':
        if (content.containsKey('prompts')) {
          final promptsList = content['prompts'] as List;
          final box = await Hive.openBox('promptTemplatesBox');
          
          for (final pMap in promptsList) {
            final p = pMap as Map;
            final id = 'tpl_plugin_${plugin.id}_${p['title'].hashCode}';
            await box.delete(id);
          }
          
          // Reload controller
          _ref.read(promptLibraryControllerProvider.notifier).loadTemplates();
        }
        break;

      case 'Knowledge':
        if (content.containsKey('articles')) {
          final articlesList = content['articles'] as List;
          final box = await Hive.openBox('knowledgeNotesBox');
          
          for (final aMap in articlesList) {
            final a = aMap as Map;
            final id = 'note_plugin_${plugin.id}_${a['title'].hashCode}';
            await box.delete(id);
          }
          
          // Reload controller
          _ref.read(knowledgeBaseControllerProvider.notifier).loadAll();
        }
        break;

      case 'Tools':
        if (content.containsKey('tool')) {
          final toolData = content['tool'] as Map;
          final toolId = toolData['id'] as String;
          AgentToolService.unregisterPluginTool(toolId);
        }
        break;

      default:
        break;
    }
  }
}

final pluginRepositoryProvider = Provider<PluginRepository>((ref) {
  return PluginRepositoryImpl();
});

final pluginManagerProvider = Provider<PluginManager>((ref) {
  final repo = ref.watch(pluginRepositoryProvider);
  return PluginManager(repo, ref);
});
