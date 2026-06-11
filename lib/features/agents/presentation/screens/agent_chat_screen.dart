import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/chat_messages_controller.dart';
import 'package:localmind_ai/features/chat/presentation/controllers/local_runtime_controller.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/agents/presentation/controllers/agents_controller.dart';
import 'package:localmind_ai/features/agents/data/services/agent_tool_service.dart';

class AgentChatScreen extends ConsumerStatefulWidget {
  final String agentId;

  const AgentChatScreen({
    super.key,
    required this.agentId,
  });

  @override
  ConsumerState<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends ConsumerState<AgentChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentsControllerProvider);
    final messagesState = ref.watch(chatMessagesControllerProvider);
    final runtimeState = ref.watch(localRuntimeControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final agent = state.activeProfile;
    if (agent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Trigger scroll when message list updates or streaming updates
    ref.listen<ChatMessagesState>(chatMessagesControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    ref.listen<LocalRuntimeState>(localRuntimeControllerProvider, (prev, next) {
      if (next.isGenerating) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: _buildControlDrawer(context, state),
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            ref.read(localRuntimeControllerProvider.notifier).stopGeneration();
            context.go('/agents');
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(agent.name, style: AppTypography.titleMedium),
            Text(
              agent.role,
              style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Local GGUF Model switcher
          _buildModelSwitcher(ref, state),
          IconButton(
            icon: const Icon(Icons.insights_rounded, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: 'Agent Control Center',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              primaryColor.withOpacity(0.04),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            center: const Alignment(-0.6, -0.6),
            radius: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Chat message list
            Expanded(
              child: messagesState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: messagesState.messages.length + (runtimeState.isGenerating ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messagesState.messages.length) {
                          return _buildMessageBubble(
                            sender: 'ai',
                            text: runtimeState.currentGenerationText,
                            isStreaming: true,
                          );
                        }
                        final msg = messagesState.messages[index];
                        final isUser = msg.sender.name == 'user';
                        return _buildMessageBubble(
                          sender: isUser ? 'user' : 'ai',
                          text: msg.content,
                          isStreaming: false,
                        );
                      },
                    ),
            ),

            if (state.runningToolId != null)
              _buildToolRunningIndicator(state.runningToolId!),

            // Tool execution horizontal strip
            _buildToolStrip(context, agent),

            // Input Console
            _buildInputConsole(ref, runtimeState),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSwitcher(WidgetRef ref, AgentsState state) {
    final installedState = ref.watch(installedModelsControllerProvider);
    final activeOverride = state.activeSession?.activeModelOverride;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: activeOverride,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
          items: installedState.installedModels.map((m) {
            return DropdownMenuItem<String>(
              value: m.id,
              child: Text(
                m.localName,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              ref.read(agentsControllerProvider.notifier).switchAgentModel(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String sender,
    required String text,
    bool isStreaming = false,
  }) {
    final isUser = sender == 'user';
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Detect if this message represents a tool execution
    final isToolExecution = text.startsWith('🛠️');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isToolExecution ? Colors.orange.withOpacity(0.2) : primaryColor.withOpacity(0.2),
              child: Icon(
                isToolExecution ? Icons.settings_suggest_rounded : Icons.smart_toy_rounded,
                size: 16,
                color: isToolExecution ? Colors.orange : primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GlassContainer(
              borderRadius: 16,
              blur: 5,
              color: isUser
                  ? primaryColor.withOpacity(0.15)
                  : (isToolExecution ? Colors.orange.withOpacity(0.08) : Theme.of(context).cardTheme.color!.withOpacity(0.4)),
              borderColor: isUser
                  ? primaryColor.withOpacity(0.3)
                  : (isToolExecution ? Colors.orange.withOpacity(0.3) : AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.white90,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (isStreaming) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryColor),
                    ),
                  ]
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white10,
              child: const Icon(Icons.person_rounded, size: 16, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolRunningIndicator(String toolId) {
    final tool = AgentToolService.availableTools.firstWhere((t) => t.id == toolId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Text(
            'Running local tool: ${tool.name}...',
            style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildToolStrip(BuildContext context, AgentProfile agent) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: agent.tools.map((tId) {
          final tool = AgentToolService.availableTools.firstWhere((t) => t.id == tId);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.bolt_rounded, size: 14, color: Colors.orange),
              label: Text(tool.name, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border, width: 0.5)),
              onPressed: () => _showToolFormDialog(context, tool),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputConsole(WidgetRef ref, LocalRuntimeState runtime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Ask agent or trigger local tools...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  fillColor: AppColors.surface,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (runtime.isGenerating)
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 18),
                  onPressed: () {
                    ref.read(localRuntimeControllerProvider.notifier).stopGeneration();
                  },
                ),
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  onPressed: () {
                    final text = _inputController.text.trim();
                    if (text.isEmpty) return;
                    ref.read(agentsControllerProvider.notifier).sendAgentMessage(text);
                    _inputController.clear();
                    _scrollToBottom();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlDrawer(BuildContext context, AgentsState state) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final agent = state.activeProfile!;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology_rounded, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text('Agent Configuration', style: AppTypography.titleMedium),
              ],
            ),
          ),

          // Drawer content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Persona Details
                const Text('Agent Prompt Persona', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  agent.systemPrompt,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
                const Divider(height: 32),

                // Memory Facts Database
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Long-term Memory Facts', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: _showAddMemoryDialog,
                      child: Text('+ Add Fact', style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.activeMemory.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Memory is empty. Add facts to customize responses.', style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
                    ),
                  )
                else
                  ...state.activeMemory.map((mem) => _buildMemoryTile(mem)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTile(AgentMemory mem) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mem.key,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  mem.value,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
            onPressed: () => ref.read(agentsControllerProvider.notifier).deleteMemoryFact(mem.id),
          ),
        ],
      ),
    );
  }

  void _showToolFormDialog(BuildContext context, AgentTool tool) {
    final Map<String, TextEditingController> controllers = {
      for (var param in tool.parameters) param: TextEditingController()
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(tool.name, style: AppTypography.titleMedium),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tool.description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 16),
              ...tool.parameters.map((param) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: controllers[param],
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: param[0].toUpperCase() + param.substring(1),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              for (var c in controllers.values) {
                c.dispose();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final inputs = {
                for (var entry in controllers.entries) entry.key: entry.value.text.trim()
              };
              for (var c in controllers.values) {
                c.dispose();
              }
              Navigator.of(context).pop();
              
              // Trigger tool execution in framework controller
              ref.read(agentsControllerProvider.notifier).executeAgentTool(
                    tool.id,
                    inputs,
                    'Manual trigger of tool: ${tool.name}',
                  );
            },
            child: const Text('Run Tool', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showAddMemoryDialog() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Add Memory Fact', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Facts added here are injected into the agent\'s prompt context, giving it long-term memory.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(labelText: 'Fact Type (e.g. Favorite Language)', border: OutlineInputBorder()),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'Fact Details (e.g. Dart/Flutter)', border: OutlineInputBorder()),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              keyController.dispose();
              valueController.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final keyText = keyController.text.trim();
              final valText = valueController.text.trim();
              keyController.dispose();
              valueController.dispose();
              Navigator.of(context).pop();
              if (keyText.isNotEmpty && valText.isNotEmpty) {
                ref.read(agentsControllerProvider.notifier).addMemoryFact(keyText, valText);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
