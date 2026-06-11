import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_profile.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_memory.dart';
import 'package:localmind_ai/features/agents/domain/entities/agent_session.dart';
import 'package:localmind_ai/features/agents/domain/repositories/agent_repository.dart';

class AgentRepositoryImpl implements AgentRepository {
  static const String profilesBoxName = 'agentProfilesBox';
  static const String memoryBoxName = 'agentMemoryBox';
  static const String sessionsBoxName = 'agentSessionsBox';

  Future<Box> _getProfilesBox() async {
    if (!Hive.isBoxOpen(profilesBoxName)) {
      return await Hive.openBox(profilesBoxName);
    }
    return Hive.box(profilesBoxName);
  }

  Future<Box> _getMemoryBox() async {
    if (!Hive.isBoxOpen(memoryBoxName)) {
      return await Hive.openBox(memoryBoxName);
    }
    return Hive.box(memoryBoxName);
  }

  Future<Box> _getSessionsBox() async {
    if (!Hive.isBoxOpen(sessionsBoxName)) {
      return await Hive.openBox(sessionsBoxName);
    }
    return Hive.box(sessionsBoxName);
  }

  @override
  Future<void> saveProfile(AgentProfile profile) async {
    final box = await _getProfilesBox();
    await box.put(profile.id, profile.toMap());
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    final box = await _getProfilesBox();
    await box.delete(profileId);
  }

  @override
  Future<AgentProfile?> getProfileById(String profileId) async {
    final box = await _getProfilesBox();
    final data = box.get(profileId);
    if (data == null) return null;
    return AgentProfile.fromMap(data as Map);
  }

  @override
  Future<List<AgentProfile>> getProfiles() async {
    final box = await _getProfilesBox();
    if (box.isEmpty) {
      await _prepopulateBuiltInAgents(box);
    }
    return box.values.map((map) => AgentProfile.fromMap(map as Map)).toList();
  }

  @override
  Future<void> saveMemory(AgentMemory memory) async {
    final box = await _getMemoryBox();
    await box.put(memory.id, memory.toMap());
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    final box = await _getMemoryBox();
    await box.delete(memoryId);
  }

  @override
  Future<List<AgentMemory>> getMemoryForAgent(String agentId) async {
    final box = await _getMemoryBox();
    final list = box.values
        .map((map) => AgentMemory.fromMap(map as Map))
        .where((m) => m.agentId == agentId)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> saveAgentSession(AgentSession session) async {
    final box = await _getSessionsBox();
    await box.put(session.id, session.toMap());
  }

  @override
  Future<void> deleteAgentSession(String sessionId) async {
    final box = await _getSessionsBox();
    await box.delete(sessionId);
  }

  @override
  Future<List<AgentSession>> getAgentSessions() async {
    final box = await _getSessionsBox();
    return box.values.map((map) => AgentSession.fromMap(map as Map)).toList();
  }

  @override
  Future<AgentSession?> getAgentSessionByChatId(String chatId) async {
    final box = await _getSessionsBox();
    for (final map in box.values) {
      final session = AgentSession.fromMap(map as Map);
      if (session.chatSessionId == chatId) {
        return session;
      }
    }
    return null;
  }

  Future<void> _prepopulateBuiltInAgents(Box box) async {
    final defaultAgents = [
      AgentProfile(
        id: 'study_agent',
        name: 'Study Buddy',
        role: 'Academic Tutor & Flashcard Maker',
        description: 'Explains complex academic topics, formats summaries, and generates offline study plans and QA flashcards.',
        systemPrompt: 'You are Study Buddy, an offline academic tutor. Your goal is to simplify complex concepts and structure learning. Use bullet points and step-by-step guides.',
        iconName: 'school_rounded',
        tools: ['generate_flashcards', 'create_study_plan'],
        defaultModelId: 'llama_3_2_3b',
      ),
      AgentProfile(
        id: 'coding_agent',
        name: 'Cortex Developer',
        role: 'Senior Software Engineer',
        description: 'Helps write clean code, explains complex logic patterns, formats snippets, and helps debug syntax errors.',
        systemPrompt: 'You are Cortex Developer, a senior software engineer. Focus on writing clean, efficient, and well-commented code. Format code properly inside markdown blocks.',
        iconName: 'code_rounded',
        tools: ['explain_code', 'debug_helper'],
        defaultModelId: 'llama_3_2_3b',
      ),
      AgentProfile(
        id: 'research_agent',
        name: 'SciSearch',
        role: 'Empirical Scholar & RAG Assistant',
        description: 'Helps analyze document collections, structures literature summaries, and queries localized knowledge indexes.',
        systemPrompt: 'You are SciSearch, an empirical academic researcher. Focus on objective facts, citations, and analytical comparisons. Organize literature into tables.',
        iconName: 'science_rounded',
        tools: ['offline_doc_analyzer', 'source_verifier'],
        defaultModelId: 'llama_3_2_3b',
      ),
      AgentProfile(
        id: 'writing_agent',
        name: 'Scribe',
        role: 'Creative Copywriter & Editor',
        description: 'Assists with outlines, drafts articles, refines style tones, and checks grammar flow.',
        systemPrompt: 'You are Scribe, an expert copywriter and editor. Your writing should be engaging, concise, and structured. Adapt style tones (formal, casual, or concise) as requested.',
        iconName: 'edit_note_rounded',
        tools: ['style_transfer', 'outline_generator'],
        defaultModelId: 'llama_3_2_3b',
      ),
      AgentProfile(
        id: 'travel_agent',
        name: 'Globetrotter',
        role: 'Itinerary Planner & Guide',
        description: 'Generates step-by-step daily itineraries, local attraction tips, and estimated travel budgets.',
        systemPrompt: 'You are Globetrotter, an offline travel planner. Create daily itinerary maps showing times, attraction details, and approximate budgets.',
        iconName: 'map_rounded',
        tools: ['generate_itinerary', 'budget_estimator'],
        defaultModelId: 'llama_3_2_3b',
      ),
      AgentProfile(
        id: 'resume_agent',
        name: 'Career Architect',
        role: 'Professional CV Editor & Optimizer',
        description: 'Scans resume fields against job descriptions, optimizes action verbs, and verifies ATS compatibility.',
        systemPrompt: 'You are Career Architect, a professional resume optimizer. Help refine action verbs, structure achievements, and improve formatting for ATS software compatibility.',
        iconName: 'contact_page_rounded',
        tools: ['ats_compatibility_check', 'format_action_verbs'],
        defaultModelId: 'llama_3_2_3b',
      ),
      AgentProfile(
        id: 'productivity_agent',
        name: 'Focus Master',
        role: 'Time Management Coach',
        description: 'Tracks study/work tasks, prioritizes task lists using Eisenhower Matrix, and handles Pomodoro setups.',
        systemPrompt: 'You are Focus Master, a productivity coach. Help prioritize tasks, suggest timeboxing techniques, and manage Pomodoro sessions.',
        iconName: 'done_all_rounded',
        tools: ['pomodoro_timer', 'prioritize_tasks'],
        defaultModelId: 'llama_3_2_3b',
      ),
      AgentProfile(
        id: 'career_agent',
        name: 'Mentor',
        role: 'Professional Career Coach',
        description: 'Simulates mock interviews, provides skill gap analysis, and advises on career path adjustments.',
        systemPrompt: 'You are Mentor, a professional career coach. Focus on active listening, mock interview preparation, identifying skill gaps, and career mapping.',
        iconName: 'psychology_rounded',
        tools: ['interview_simulator', 'skill_gap_analysis'],
        defaultModelId: 'llama_3_2_3b',
      ),
    ];

    for (final agent in defaultAgents) {
      await box.put(agent.id, agent.toMap());
    }
  }
}
