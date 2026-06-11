import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_profile.dart';
import 'package:localmind_ai/features/agents/presentation/controllers/agents_controller.dart';
import 'package:localmind_ai/features/agents/data/services/agent_tool_service.dart';

class AgentsDashboardScreen extends ConsumerWidget {
  const AgentsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentsControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('AI Agents Console', style: AppTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/chats'),
        ),
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
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(
                  top: kToolbarHeight + 40,
                  bottom: 60,
                  left: 16,
                  right: 16,
                ),
                children: [
                  // Header intro Card
                  _buildIntroCard(context),
                  const SizedBox(height: 24),

                  // Section Title
                  Text('Built-in Agents', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),

                  // Agents Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: state.profiles.length,
                    itemBuilder: (context, index) {
                      final agent = state.profiles[index];
                      return _buildAgentGridCard(context, ref, agent);
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'AI Agent Playground',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Interact with specialized offline agents. Each agent has its own dedicated persona system prompt, persistent context memory databases, and computational local tools to perform advanced workflows.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentGridCard(BuildContext context, WidgetRef ref, AgentProfile agent) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final icon = _getAgentIcon(agent.iconName);

    return GestureDetector(
      onTap: () async {
        await ref.read(agentsControllerProvider.notifier).startAgentSession(agent.id);
        context.push('/agent-chat/${agent.id}');
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Circle
            CircleAvatar(
              radius: 20,
              backgroundColor: primaryColor.withOpacity(0.12),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(height: 10),

            // Agent Name
            Text(
              agent.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Role Subtitle
            const SizedBox(height: 2),
            Text(
              agent.role,
              style: TextStyle(color: primaryColor.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Description
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                agent.description,
                style: const TextStyle(color: Colors.grey, fontSize: 10, height: 1.3),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Tools Badges Strip
            const SizedBox(height: 8),
            Row(
              children: agent.tools.take(2).map((tId) {
                final tool = AgentToolService.availableTools.firstWhere((t) => t.id == tId);
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(
                    tool.name.split(' ').first,
                    style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAgentIcon(String iconName) {
    switch (iconName) {
      case 'school_rounded':
        return Icons.school_rounded;
      case 'code_rounded':
        return Icons.code_rounded;
      case 'science_rounded':
        return Icons.science_rounded;
      case 'edit_note_rounded':
        return Icons.edit_note_rounded;
      case 'map_rounded':
        return Icons.map_rounded;
      case 'contact_page_rounded':
        return Icons.contact_page_rounded;
      case 'done_all_rounded':
        return Icons.done_all_rounded;
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      default:
        return Icons.smart_toy_rounded;
    }
  }
}
