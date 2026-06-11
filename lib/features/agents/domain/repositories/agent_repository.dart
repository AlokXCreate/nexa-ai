import 'package:localmind_ai/features/agents/domain/entities/agent_profile.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_memory.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_session.dart';

abstract class AgentRepository {
  // Profiles
  Future<void> saveProfile(AgentProfile profile);
  Future<void> deleteProfile(String profileId);
  Future<List<AgentProfile>> getProfiles();
  Future<AgentProfile?> getProfileById(String profileId);

  // Memory Facts
  Future<void> saveMemory(AgentMemory memory);
  Future<void> deleteMemory(String memoryId);
  Future<List<AgentMemory>> getMemoryForAgent(String agentId);

  // Sessions
  Future<void> saveAgentSession(AgentSession session);
  Future<void> deleteAgentSession(String sessionId);
  Future<List<AgentSession>> getAgentSessions();
  Future<AgentSession?> getAgentSessionByChatId(String chatId);
}
