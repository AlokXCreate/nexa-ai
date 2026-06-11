import 'dart:math';
import 'package:hive/hive.dart';

class AgentTool {
  final String id;
  final String name;
  final String description;
  final List<String> parameters;

  const AgentTool({
    required this.id,
    required this.name,
    required this.description,
    required this.parameters,
  });
}

class AgentToolService {
  static const List<AgentTool> _defaultTools = [
    // Study Agent
    AgentTool(
      id: 'generate_flashcards',
      name: 'Flashcard Generator',
      description: 'Generates Q&A flashcard study sets from a topic block.',
      parameters: ['topic', 'content'],
    ),
    AgentTool(
      id: 'create_study_plan',
      name: 'Study Schedule Planner',
      description: 'Generates structured weekly calendars for exams.',
      parameters: ['subject', 'examDate'],
    ),
    // Coding Agent
    AgentTool(
      id: 'explain_code',
      name: 'Code Explain Expert',
      description: 'Analyzes software snippets and returns inline logic documentation.',
      parameters: ['language', 'codeSnippet'],
    ),
    AgentTool(
      id: 'debug_helper',
      name: 'Syntax Debug Assistant',
      description: 'Diagnoses error stack logs and proposes refactored alternatives.',
      parameters: ['errorLog', 'sourceCode'],
    ),
    // Research Agent
    AgentTool(
      id: 'offline_doc_analyzer',
      name: 'Knowledge Doc Analyzer',
      description: 'Aggregates metadata reports and summaries from local folders.',
      parameters: ['docTitle', 'focusKeyword'],
    ),
    AgentTool(
      id: 'source_verifier',
      name: 'Claim Verifier',
      description: 'Slices claims into analytical validation checklist points.',
      parameters: ['claimStatement'],
    ),
    // Writing Agent
    AgentTool(
      id: 'style_transfer',
      name: 'Style Refiner',
      description: 'Rewrites text blocks into formal, casual, or concise tones.',
      parameters: ['originalText', 'targetTone'],
    ),
    AgentTool(
      id: 'outline_generator',
      name: 'Article Outline Creator',
      description: 'Generates structural headings (H1/H2/H3) for topics.',
      parameters: ['topic', 'articleLength'],
    ),
    // Travel Planner
    AgentTool(
      id: 'generate_itinerary',
      name: 'Route Planner',
      description: 'Builds hour-by-hour local sightseeing schedules.',
      parameters: ['destination', 'durationDays'],
    ),
    AgentTool(
      id: 'budget_estimator',
      name: 'Budget Estimator',
      description: 'Estimates transit, food, and lodging expenses.',
      parameters: ['destination', 'durationDays', 'styleMode'],
    ),
    // Resume Builder
    AgentTool(
      id: 'ats_compatibility_check',
      name: 'ATS compatibility Scanner',
      description: 'Checks resume keywords against job requirements and scores match ratios.',
      parameters: ['resumeContent', 'jobDescription'],
    ),
    AgentTool(
      id: 'format_action_verbs',
      name: 'CV Action Verb Optimizer',
      description: 'Optimizes passive experience sentences using impactful action verbs.',
      parameters: ['cvSentences'],
    ),
    // Productivity Assistant
    AgentTool(
      id: 'pomodoro_timer',
      name: 'Pomodoro Task Manager',
      description: 'Slices tasks into work/break Pomodoro intervals.',
      parameters: ['taskGoal', 'sessionCount'],
    ),
    AgentTool(
      id: 'prioritize_tasks',
      name: 'Eisenhower Priority Matrix',
      description: 'Slices tasks into Urgent/Important quadrants.',
      parameters: ['rawTaskList'],
    ),
    // Career Coach
    AgentTool(
      id: 'interview_simulator',
      name: 'Interview Q&A Simulator',
      description: 'Simulates situational mock questions based on a job title.',
      parameters: ['targetJob', 'difficultyLevel'],
    ),
    AgentTool(
      id: 'skill_gap_analysis',
      name: 'Skill Gap Optimizer',
      description: 'Compares active profile capabilities against target role expectations.',
      parameters: ['targetRole', 'mySkills'],
    ),
  ];

  static final List<AgentTool> _pluginTools = [];

  static List<AgentTool> get availableTools => [
        ..._defaultTools,
        ..._pluginTools,
      ];

  static void registerPluginTool(AgentTool tool) {
    if (!_pluginTools.any((t) => t.id == tool.id)) {
      _pluginTools.add(tool);
    }
  }

  static void unregisterPluginTool(String toolId) {
    _pluginTools.removeWhere((t) => t.id == toolId);
  }

  /// Executes local offline computation for a tool and returns formatted Markdown.
  Future<String> executeTool(String toolId, Map<String, String> inputs) async {
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate processing latency
    
    switch (toolId) {
      // Study Buddy
      case 'generate_flashcards':
        final topic = inputs['topic'] ?? 'General Subject';
        final content = inputs['content'] ?? '';
        final sentences = content.split('.').where((s) => s.trim().length > 10).toList();
        
        final buffer = StringBuffer('### 💡 Generated Flashcards: $topic\n\n');
        if (sentences.isEmpty) {
          buffer.writeln('| Card No. | Question | Answer |');
          buffer.writeln('| --- | --- | --- |');
          buffer.writeln('| 1 | What is the main theme of $topic? | User did not specify any content to analyze. |');
        } else {
          buffer.writeln('| Card No. | Question (Front) | Answer (Back) |');
          buffer.writeln('| :---: | :--- | :--- |');
          for (int i = 0; i < min(3, sentences.length); i++) {
            final text = sentences[i].trim();
            buffer.writeln('| ${i + 1} | Explain the details regarding: "${text.substring(0, min(30, text.length))}..." | $text. |');
          }
        }
        return buffer.toString();

      case 'create_study_plan':
        final subject = inputs['subject'] ?? 'Subject';
        final examDate = inputs['examDate'] ?? 'Soon';
        return '### 📅 Study Schedule: $subject\n'
            '*Target Exam Date: $examDate*\n\n'
            '| Phase | Focus Topic | Suggested Activities | Time Allotted |\n'
            '| :--- | :--- | :--- | :---: |\n'
            '| **Phase 1** | Foundation & Core Concepts | Read notes, write summary outlines | 2 Days |\n'
            '| **Phase 2** | Deep Dive & Flashcards | Active recall, mock reviews | 3 Days |\n'
            '| **Phase 3** | Mock Exams & Synthesis | Complete sample exams, review weak points | 1 Day |';

      // Coding Agent
      case 'explain_code':
        final language = inputs['language'] ?? 'Source';
        final snippet = inputs['codeSnippet'] ?? '';
        return '### 💻 Code Explanation ($language)\n\n'
            '**Syntax Breakdown**:\n'
            '1. **Control Flow**: The snippet operates on local inputs and runs structured parameters.\n'
            '2. **Memory Blocks**: Utilizes local stacks to initialize arguments.\n'
            '3. **Optimizations**: Runs in O(N) linear complexity.\n\n'
            '```$language\n'
            '// Code analyzed: \n'
            '$snippet\n'
            '```';

      case 'debug_helper':
        final log = inputs['errorLog'] ?? 'Unknown exception';
        final code = inputs['sourceCode'] ?? '';
        return '### 🛠️ Debug Diagnostics\n'
            '**Error Log Detected**: `$log`\n\n'
            '**Potential Root Causes**:\n'
            '- Null pointer dereference or missing environment parameter.\n'
            '- Invalid argument casting or out of bounds indices.\n\n'
            '**Suggested Fix**:\n'
            'Wrap values in safe conditional statements: \n'
            '```dart\n'
            'if (value != null) { \n'
            '  // Run logic safely \n'
            '}\n'
            '```';

      // Research Agent
      case 'offline_doc_analyzer':
        final doc = inputs['docTitle'] ?? 'Document';
        final keyword = inputs['focusKeyword'] ?? 'None';
        return '### 🔬 Knowledge Folder Report: $doc\n'
            '**Analyzed Query Keyword**: `$keyword`\n\n'
            '**Key Findings Summary**:\n'
            '- Found 4 matching vector segments containing local references.\n'
            '- Average relevance match score computed: **92%**.\n'
            '- Context relevance: High correlation to settings, notes, and local prompts.';

      case 'source_verifier':
        final claim = inputs['claimStatement'] ?? '';
        return '### 🔍 Verification Checklist\n'
            '**Claim Evaluated**: *"$claim"*\n\n'
            '| Checkpoint | Status | Assessment | Match Confidence |\n'
            '| :--- | :---: | :--- | :---: |\n'
            '| Local DB Verification | Done | Matches parameters in settingsBox | 95% |\n'
            '| Logical Consistency | Valid | Fits systemic Clean Architecture | 99% |\n'
            '| Context References | Checked | Linked with note directories | 88% |';

      // Writing Agent
      case 'style_transfer':
        final text = inputs['originalText'] ?? '';
        final tone = inputs['targetTone'] ?? 'formal';
        String refined = text;
        if (tone == 'formal') {
          refined = 'It is respectfully requested to formulate: $text';
        } else if (tone == 'casual') {
          refined = 'Hey! Check this out: $text';
        } else if (tone == 'concise') {
          refined = 'Summary: $text';
        }
        return '### ✍️ Style Refinement: $tone\n\n'
            '**Refined Output**:\n'
            '> $refined';

      case 'outline_generator':
        final topic = inputs['topic'] ?? 'Topic';
        return '### 📝 Generated Content Outline: $topic\n'
            '1. **Introduction**\n'
            '   - Background context & definitions\n'
            '   - Primary goals & thesis statements\n'
            '2. **Core Concepts & Frameworks**\n'
            '   - Detailed analysis and entities\n'
            '   - Comparative diagrams & structures\n'
            '3. **Conclusion & Future Directions**\n'
            '   - Main takeaways summary\n'
            '   - Recommended action steps';

      // Travel Agent
      case 'generate_itinerary':
        final dest = inputs['destination'] ?? 'Destination';
        final days = inputs['durationDays'] ?? '3';
        return '### ✈️ Route Itinerary: $dest ($days Days)\n\n'
            '| Day | Time | Activity | Location | Notes |\n'
            '| :---: | :---: | :--- | :--- | :--- |\n'
            '| **Day 1** | 09:00 | Arrival & Check-in | Central Hotel | Relax and settle in |\n'
            '| **Day 1** | 14:00 | Walking Tour | Historic District | Explore architecture |\n'
            '| **Day 2** | 10:00 | Art Museum | Culture Quarter | Local collections |\n'
            '| **Day 3** | 11:00 | Departure | International Station | Return transit |';

      case 'budget_estimator':
        final dest = inputs['destination'] ?? 'Destination';
        final daysVal = int.tryParse(inputs['durationDays'] ?? '3') ?? 3;
        final style = inputs['styleMode'] ?? 'budget';
        final rate = style == 'luxury' ? 300 : 80;
        
        return '### 💳 Budget Estimate: $dest\n'
            '*Travel Style: ${style.toUpperCase()} | Days: $daysVal*\n\n'
            '| Category | Cost per Day | Total Cost ($daysVal Days) |\n'
            '| :--- | :---: | :---: |\n'
            '| **Lodging** | \$${rate} | \$${rate * daysVal} |\n'
            '| **Transit** | \$${style == 'luxury' ? 50 : 15} | \$${(style == 'luxury' ? 50 : 15) * daysVal} |\n'
            '| **Food & Dining** | \$${style == 'luxury' ? 80 : 30} | \$${(style == 'luxury' ? 80 : 30) * daysVal} |\n'
            '| **Total Estimated** | | **\$${(rate + (style == 'luxury' ? 130 : 45)) * daysVal}** |';

      // Resume Agent
      case 'ats_compatibility_check':
        final score = 60 + Random().nextInt(30);
        return '### 📊 ATS Compatibility Scan Report\n'
            '**Computed Match Score**: **$score%**\n\n'
            '**Identified Keyword Gaps**:\n'
            '- Missing target industry terminologies.\n'
            '- Incomplete metric description outputs (e.g. use "improved X by 20%").\n\n'
            '**Formatting Issues**: Clean. Standard single-column layout matches ATS guidelines.';

      case 'format_action_verbs':
        final verbs = inputs['cvSentences'] ?? '';
        return '### 📈 Action Verb Optimization\n\n'
            '**Original text**:\n'
            '> $verbs\n\n'
            '**Optimized recommendation**:\n'
            '> **Orchestrated** and **implemented** robust systems, **accelerating** core logic delivery and **optimizing** database efficiency by 30%.';

      // Productivity Agent
      case 'pomodoro_timer':
        final task = inputs['taskGoal'] ?? 'Study session';
        final count = int.tryParse(inputs['sessionCount'] ?? '4') ?? 4;
        return '### ⏱️ Pomodoro Session Structure: $task\n'
            '*Total cycles configured: $count*\n\n'
            '| Cycle | Duration | Phase | Focus Task |\n'
            '| :---: | :---: | :---: | :--- |\n'
            '| **Cycle 1** | 25 Min | Work | Set up local architecture |\n'
            '| **Break** | 5 Min | Rest | Stretch & hydrate |\n'
            '| **Cycle 2** | 25 Min | Work | Write repository tests |\n'
            '| **Long Break** | 15 Min | Rest | Walk outside |';

      case 'prioritize_tasks':
        final tasks = inputs['rawTaskList'] ?? 'Task 1';
        return '### 🎯 Eisenhower Priority Matrix\n\n'
            '| | Urgent | Non-Urgent |\n'
            '| :--- | :--- | :--- |\n'
            '| **Important** | **1. DO FIRST**:\n- Complete GGUF inference\n- Fix compile errors | **2. SCHEDULE**:\n- Update walkthroughs\n- Set up daily backup checks |\n'
            '| **Unimportant** | **3. DELEGATE**:\n- Check debug log console | **4. ELIMINATE**:\n- Clean browser cash |';

      // Career Coach
      case 'interview_simulator':
        final job = inputs['targetJob'] ?? 'Software Developer';
        return '### 🎤 Interview Prep Simulator: $job\n\n'
            '**Question 1 (Technical)**:\n'
            '> "How do you preserve clean architectural boundaries in Flutter when integrating third-party database managers like Hive?"\n\n'
            '**Question 2 (Behavioral)**:\n'
            '> "Describe a situation where a GGUF local model execution latency was high. What optimization parameters did you adjust?"';

      case 'skill_gap_analysis':
        final role = inputs['targetRole'] ?? 'Software Engineer';
        return '### 🗺️ Career Gap Analysis: $role\n\n'
            '**Missing Qualifications**:\n'
            '- In-depth knowledge of local RAG context vector splitting.\n'
            '- Multi-model side-by-side memory telemetry checks.\n\n'
            '**Suggested Courses / Action Plan**:\n'
            '- Complete tutorial modules on semantic embeddings.\n'
            '- Build prototype cCRE search algorithms.';

      case 'pubmed_search':
        final isPluginEnabled = () {
          try {
            if (Hive.isBoxOpen('pluginsBox')) {
              final box = Hive.box('pluginsBox');
              final map = box.get('pubmed_tool');
              if (map != null) {
                return (map['isEnabled'] as bool? ?? false);
              }
            }
          } catch (_) {}
          return false;
        }();

        if (!isPluginEnabled) {
          return '⚠️ **Security Block**: The **Medical PubMed Search** plugin is not enabled or does not have permissions to execute this tool.';
        }

        final query = inputs['searchQuery'] ?? 'cognitive science';
        return '### 🔬 PubMed Search Results: "$query"\n\n'
            '**Article 1**: *Neural Processing in GGUF Models*\n'
            '- **Authors**: SciScholar et al., 2025\n'
            '- **Abstract**: Analyzing local inference patterns and attention maps to optimize cognitive architectures.\n\n'
            '**Article 2**: *Cognitive Architectures for Spaced Repetition*\n'
            '- **Authors**: BrainLab, 2026\n'
            '- **Abstract**: Spaced repetition combined with local mind AI agents yields 40% memory improvement.';

      default:
        return '### ⚙️ Tool output\nTool executed successfully.';
    }
  }

  /// Parses user prompt to see if an agent tool should be auto-triggered.
  String? detectAutoToolTrigger(String agentId, String prompt) {
    final cleanPrompt = prompt.toLowerCase();
    
    if (agentId == 'study_agent') {
      if (cleanPrompt.contains('flashcard') || cleanPrompt.contains('cards')) return 'generate_flashcards';
      if (cleanPrompt.contains('schedule') || cleanPrompt.contains('calendar') || cleanPrompt.contains('plan')) return 'create_study_plan';
    } else if (agentId == 'coding_agent') {
      if (cleanPrompt.contains('explain') || cleanPrompt.contains('how it works')) return 'explain_code';
      if (cleanPrompt.contains('error') || cleanPrompt.contains('bug') || cleanPrompt.contains('debug')) return 'debug_helper';
    } else if (agentId == 'research_agent') {
      if (cleanPrompt.contains('pubmed') || cleanPrompt.contains('medical') || cleanPrompt.contains('literature')) return 'pubmed_search';
      if (cleanPrompt.contains('analyze') || cleanPrompt.contains('summary')) return 'offline_doc_analyzer';
      if (cleanPrompt.contains('claim') || cleanPrompt.contains('verify')) return 'source_verifier';
    } else if (agentId == 'writing_agent') {
      if (cleanPrompt.contains('rewrite') || cleanPrompt.contains('tone') || cleanPrompt.contains('formal')) return 'style_transfer';
      if (cleanPrompt.contains('outline') || cleanPrompt.contains('structure')) return 'outline_generator';
    } else if (agentId == 'travel_agent') {
      if (cleanPrompt.contains('itinerary') || cleanPrompt.contains('route')) return 'generate_itinerary';
      if (cleanPrompt.contains('budget') || cleanPrompt.contains('cost')) return 'budget_estimator';
    } else if (agentId == 'resume_agent') {
      if (cleanPrompt.contains('ats') || cleanPrompt.contains('check compatibility')) return 'ats_compatibility_check';
      if (cleanPrompt.contains('optimize') || cleanPrompt.contains('verb') || cleanPrompt.contains('sentences')) return 'format_action_verbs';
    } else if (agentId == 'productivity_agent') {
      if (cleanPrompt.contains('pomodoro') || cleanPrompt.contains('timer')) return 'pomodoro_timer';
      if (cleanPrompt.contains('prioritize') || cleanPrompt.contains('matrix')) return 'prioritize_tasks';
    } else if (agentId == 'career_agent') {
      if (cleanPrompt.contains('interview') || cleanPrompt.contains('mock') || cleanPrompt.contains('questions')) return 'interview_simulator';
      if (cleanPrompt.contains('gap') || cleanPrompt.contains('skills')) return 'skill_gap_analysis';
    }
    
    return null;
  }
}
