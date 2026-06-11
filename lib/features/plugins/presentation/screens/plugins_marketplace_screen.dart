import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:localmind_ai/features/plugins/presentation/controllers/plugins_controller.dart';

class PluginsMarketplaceScreen extends ConsumerStatefulWidget {
  const PluginsMarketplaceScreen({super.key});

  @override
  ConsumerState<PluginsMarketplaceScreen> createState() => _PluginsMarketplaceScreenState();
}

class _PluginsMarketplaceScreenState extends ConsumerState<PluginsMarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pluginsControllerProvider);
    final controller = ref.read(pluginsControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        title: const Text('Plugin Marketplace'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.textTheme.titleMedium?.color,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Browse Catalog'),
            Tab(text: 'Installed Plugins'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F0C20),
                    const Color(0xFF15102A),
                    const Color(0xFF06040A),
                  ]
                : [
                    const Color(0xFFF0F4FF),
                    const Color(0xFFF9FAFB),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildCategoryFilter(context, state, controller),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPluginGrid(context, controller, false), // Catalog
                          _buildPluginGrid(context, controller, true),  // Installed
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, PluginsState state, PluginsController controller) {
    final categories = ['All', 'Models', 'Themes', 'Widgets', 'Tools', 'Prompts', 'Knowledge'];
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = state.selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => controller.setCategory(cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        )
                      : null,
                  color: isSelected ? null : theme.colorScheme.surface.withOpacity(0.4),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Text(
                  cat,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPluginGrid(BuildContext context, PluginsController controller, bool showOnlyInstalled) {
    final allList = controller.filteredPlugins;
    final list = showOnlyInstalled
        ? allList.where((p) => p.isInstalled).toList()
        : allList.where((p) => !p.isInstalled).toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showOnlyInstalled ? Icons.extension_off_rounded : Icons.search_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              showOnlyInstalled ? 'No installed plugins found.' : 'All available plugins are installed!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final plugin = list[index];
        return _buildPluginCard(context, controller, plugin);
      },
    );
  }

  Widget _buildPluginCard(BuildContext context, PluginsController controller, PluginManifest plugin) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.2),
                          theme.colorScheme.secondary.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: Icon(
                      _getCategoryIcon(plugin.category),
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plugin.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'by ${plugin.author} • v${plugin.version}',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  plugin.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (plugin.isInstalled) ...[
                    Row(
                      children: [
                        Switch(
                          value: plugin.isEnabled,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            if (val) {
                              _showPermissionDialog(context, controller, plugin);
                            } else {
                              controller.disablePlugin(plugin.id);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plugin.isEnabled ? 'Active' : 'Disabled',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: plugin.isEnabled ? theme.colorScheme.primary : null,
                            fontWeight: plugin.isEnabled ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Simulate Update',
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          onPressed: () => controller.updatePlugin(plugin.id),
                        ),
                        IconButton(
                          tooltip: 'Uninstall',
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                          onPressed: () => controller.uninstallPlugin(plugin.id),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      plugin.category,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      onPressed: () => controller.installPlugin(plugin.id),
                      child: const Text('Install'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Models':
        return Icons.memory_rounded;
      case 'Themes':
        return Icons.palette_rounded;
      case 'Widgets':
        return Icons.widgets_rounded;
      case 'Tools':
        return Icons.construction_rounded;
      case 'Prompts':
        return Icons.menu_book_rounded;
      case 'Knowledge':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.extension_rounded;
    }
  }

  void _showPermissionDialog(BuildContext context, PluginsController controller, PluginManifest plugin) {
    if (plugin.permissions.isEmpty) {
      // Direct enable if no sensitive permissions needed
      controller.enablePlugin(plugin.id);
      return;
    }

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: theme.brightness == Brightness.dark 
                  ? const Color(0xFF141424).withOpacity(0.9) 
                  : Colors.white.withOpacity(0.9),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: Colors.orangeAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Authorize Plugin Permissions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The plugin "${plugin.name}" is requesting the following permissions to integrate into Nexa AI:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...plugin.permissions.map((perm) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: theme.colorScheme.error.withOpacity(0.05),
                          border: Border.all(
                            color: theme.colorScheme.error.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getPermissionTitle(perm),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getPermissionDesc(perm),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.textTheme.labelMedium?.color?.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            controller.enablePlugin(plugin.id);
                            Navigator.pop(context);
                          },
                          child: const Text('Authorize & Enable'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getPermissionTitle(String permission) {
    switch (permission) {
      case 'change_theme':
        return 'Override Visual Theme';
      case 'access_kb':
        return 'Modify Knowledge Base';
      case 'add_models':
        return 'Register Local AI Models';
      case 'register_tools':
        return 'Register Agent Tools';
      default:
        return 'Access System Capabilities';
    }
  }

  String _getPermissionDesc(String permission) {
    switch (permission) {
      case 'change_theme':
        return 'Allows this plugin to change the application primary and accent color schemes.';
      case 'access_kb':
        return 'Allows this plugin to pre-populate and modify articles inside your offline Knowledge Base.';
      case 'add_models':
        return 'Allows this plugin to register local GGUF models directly to the runtimes lists.';
      case 'register_tools':
        return 'Allows this plugin to extend the capabilities of active agents by registering offline tools.';
      default:
        return 'Allows custom integrations into core functionalities.';
    }
  }
}
