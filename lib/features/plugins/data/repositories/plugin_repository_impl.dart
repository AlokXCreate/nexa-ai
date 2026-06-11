import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:localmind_ai/features/plugins/domain/repositories/plugin_repository.dart';

class PluginRepositoryImpl implements PluginRepository {
  static const String boxName = 'pluginsBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  @override
  Future<void> savePlugin(PluginManifest plugin) async {
    final box = await _getBox();
    await box.put(plugin.id, plugin.toMap());
  }

  @override
  Future<void> deletePlugin(String pluginId) async {
    final box = await _getBox();
    await box.delete(pluginId);
  }

  @override
  Future<PluginManifest?> getPluginById(String pluginId) async {
    final box = await _getBox();
    final data = box.get(pluginId);
    if (data == null) return null;
    return PluginManifest.fromMap(data as Map);
  }

  @override
  Future<List<PluginManifest>> getPlugins() async {
    final box = await _getBox();
    if (box.isEmpty) {
      await _prepopulateCatalog(box);
    }
    return box.values.map((map) => PluginManifest.fromMap(map as Map)).toList();
  }

  Future<void> _prepopulateCatalog(Box box) async {
    final catalog = [
      PluginManifest(
        id: 'cyberpunk_theme',
        name: 'Neon Cyberpunk Theme',
        version: '1.0.0',
        description: 'Switches app color scheme to neon cyberpunk palette (glowing cyan primary and hot magenta accents).',
        author: 'CyberLabs',
        category: 'Themes',
        permissions: ['change_theme'],
        content: {
          'primary': '0xFF00FFCC',
          'accent': '0xFFFF0055',
          'background': '0xFF0A0A12',
          'surface': '0xFF141424'
        },
        isEnabled: false,
        isInstalled: false,
      ),
      PluginManifest(
        id: 'pomodoro_widget',
        name: 'Pomodoro Timer Widget',
        version: '1.2.0',
        description: 'Adds an interactive Pomodoro timer block widget directly to the home screen dashboard.',
        author: 'FocusDevs',
        category: 'Widgets',
        permissions: [],
        content: {
          'widgetId': 'pomodoro_widget',
          'title': 'Timebox Focus Timer'
        },
        isEnabled: false,
        isInstalled: false,
      ),
      PluginManifest(
        id: 'writing_prompts',
        name: 'Writing Template Pack',
        version: '1.1.0',
        description: 'Injects 3 creative copywriting templates into the prompt templates library.',
        author: 'ScribeAuthors',
        category: 'Prompts',
        permissions: [],
        content: {
          'prompts': [
            {
              'title': 'Blog Opening Hook',
              'content': 'Write a catchy, attention-grabbing opening hook for a blog about [topic] in [tone] tone.'
            },
            {
              'title': 'Cold Sales Pitch',
              'content': 'Draft a persuasive sales outreach email for [product] targeting [audience], highlighting [benefit].'
            },
            {
              'title': 'Text Summarizer Pro',
              'content': 'Condense the following text into 3 bullet points with a bold takeaways line:\n\n[text]'
            }
          ]
        },
        isEnabled: false,
        isInstalled: false,
      ),
      PluginManifest(
        id: 'medical_kb',
        name: 'Medical Science Pack',
        version: '1.0.0',
        description: 'Pre-populates the Knowledge Base notes with introductory articles about cognitive sciences.',
        author: 'SciScholar',
        category: 'Knowledge',
        permissions: ['access_kb'],
        content: {
          'articles': [
            {
              'title': 'Neural Learning Architectures',
              'content': 'Local GGUF models process token weights using feed-forward network blocks and multi-head self-attention mechanisms. This lets models formulate contextual mappings offline.',
              'tags': ['AI', 'Science']
            },
            {
              'title': 'Cognitive Spaced Repetition',
              'content': 'Cognitive studies show active recall combined with spaced repetition structures optimal learning curves. Using study buddy agents to generate flashcards automates this recall cycle.',
              'tags': ['Cognitive', 'Study']
            }
          ]
        },
        isEnabled: false,
        isInstalled: false,
      ),
      PluginManifest(
        id: 'deepseek_config',
        name: 'DeepSeek Model Registry',
        version: '1.0.5',
        description: 'Registers DeepSeek-Coder-1.5B (GGUF) meta configurations inside the local marketplace installed index.',
        author: 'ModelPack',
        category: 'Models',
        permissions: ['add_models'],
        content: {
          'model': {
            'id': 'deepseek_coder',
            'localName': 'DeepSeek Coder (1.5B)',
            'developer': 'DeepSeek',
            'version': '1.0.0',
            'sizeString': '1.1 GB',
            'sizeInGb': 1.1,
            'ramRequirement': '2 GB',
            'filePath': '/localmind/models/deepseek_coder.gguf'
          }
        },
        isEnabled: false,
        isInstalled: false,
      ),
      PluginManifest(
        id: 'task_matrix_widget',
        name: 'Task Matrix Widget',
        version: '1.1.2',
        description: 'Adds an interactive Eisenhower Priority Matrix checklist card to the home screen dashboard.',
        author: 'FocusDevs',
        category: 'Widgets',
        permissions: [],
        content: {
          'widgetId': 'task_matrix_widget',
          'title': 'Task Matrix Checklist'
        },
        isEnabled: false,
        isInstalled: false,
      ),
      PluginManifest(
        id: 'pubmed_tool',
        name: 'Medical PubMed Search',
        version: '1.0.0',
        description: 'Registers PubMed search tool access on active research agents.',
        author: 'SciScholar',
        category: 'Tools',
        permissions: ['register_tools'],
        content: {
          'toolId': 'pubmed_search',
          'tool': {
            'id': 'pubmed_search',
            'name': 'PubMed Offline Search',
            'description': 'Simulates local search queries against PubMed databases for cognitive sciences.',
            'parameters': ['searchQuery']
          }
        },
        isEnabled: false,
        isInstalled: false,
      ),
    ];

    for (final plugin in catalog) {
      await box.put(plugin.id, plugin.toMap());
    }
  }
}
