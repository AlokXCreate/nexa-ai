import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/database/sync_operation.dart';
import 'package:localmind_ai/core/database/firestore_sync_service.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_profile.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_memory.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_session.dart';
import 'package:localmind_ai/features/agents/domain/repositories/agent_repository.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';

class AgentRepositorySyncDecorator implements AgentRepository {
  final AgentRepository _delegate;
  final Ref _ref;

  AgentRepositorySyncDecorator(this._delegate, this._ref);

  FirestoreSyncService get _syncService => _ref.read(firestoreSyncServiceProvider);

  bool _isIncognito() {
    try {
      return _ref.read(securityControllerProvider).config.isIncognitoActive;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveProfile(AgentProfile profile) async {
    await _delegate.saveProfile(profile);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'agent_profiles',
        documentId: profile.id,
        actionType: SyncActionType.save,
        data: profile.toMap(),
      );
    }
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    await _delegate.deleteProfile(profileId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'agent_profiles',
        documentId: profileId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<AgentProfile>> getProfiles() => _delegate.getProfiles();

  @override
  Future<AgentProfile?> getProfileById(String profileId) => _delegate.getProfileById(profileId);

  @override
  Future<void> saveMemory(AgentMemory memory) async {
    await _delegate.saveMemory(memory);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'agent_memories',
        documentId: memory.id,
        actionType: SyncActionType.save,
        data: memory.toMap(),
      );
    }
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    await _delegate.deleteMemory(memoryId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'agent_memories',
        documentId: memoryId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<AgentMemory>> getMemoryForAgent(String agentId) => _delegate.getMemoryForAgent(agentId);

  @override
  Future<void> saveAgentSession(AgentSession session) async {
    await _delegate.saveAgentSession(session);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'agent_sessions',
        documentId: session.id,
        actionType: SyncActionType.save,
        data: session.toMap(),
      );
    }
  }

  @override
  Future<void> deleteAgentSession(String sessionId) async {
    await _delegate.deleteAgentSession(sessionId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'agent_sessions',
        documentId: sessionId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<AgentSession>> getAgentSessions() => _delegate.getAgentSessions();

  @override
  Future<AgentSession?> getAgentSessionByChatId(String chatId) => _delegate.getAgentSessionByChatId(chatId);
}
