import 'dart:async';
import 'package:flutter/material.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';

class PomodoroTimerWidget extends StatefulWidget {
  const PomodoroTimerWidget({super.key});

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget> {
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _secondsRemaining = 25 * 60; // Reset
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pomodoro completed! Time for a short break. ☕'),
              backgroundColor: Colors.emerald,
            ),
          );
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 25 * 60;
      _isRunning = false;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GlassContainer(
      borderRadius: 20,
      blur: 15,
      color: theme.colorScheme.surface.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Focus Timebox (Pomodoro)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isRunning ? 'FOCUS ACTIVE' : 'PAUSED',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(_secondsRemaining),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Goal: Keep offline flow going',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: _toggleTimer,
                    child: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.12)),
                    ),
                    onPressed: _resetTimer,
                    child: const Icon(Icons.replay_rounded, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1 - (_secondsRemaining / (25 * 60)),
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskMatrixWidget extends StatefulWidget {
  const TaskMatrixWidget({super.key});

  @override
  State<TaskMatrixWidget> createState() => _TaskMatrixWidgetState();
}

class _TaskMatrixWidgetState extends State<TaskMatrixWidget> {
  final Map<String, List<Map<String, dynamic>>> _quadrantTasks = {
    'Q1': [
      {'text': 'Complete local model setup', 'checked': true},
      {'text': 'Debug router configuration', 'checked': false},
    ],
    'Q2': [
      {'text': 'Update development journal', 'checked': false},
    ],
    'Q3': [
      {'text': 'Check system resource limits', 'checked': false},
    ],
    'Q4': [
      {'text': 'Clear cache directory', 'checked': false},
    ],
  };

  String _activeQuadrant = 'Q1';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GlassContainer(
      borderRadius: 20,
      blur: 15,
      color: theme.colorScheme.surface.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: theme.colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Eisenhower Task Matrix',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2x2 Grid selector
              Expanded(
                flex: 4,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildQuadrantButton('Q1', 'DO FIRST', Colors.redAccent),
                      _buildQuadrantButton('Q2', 'SCHEDULE', Colors.blueAccent),
                      _buildQuadrantButton('Q3', 'DELEGATE', Colors.orangeAccent),
                      _buildQuadrantButton('Q4', 'ELIMINATE', Colors.greenAccent),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Checklist for active quadrant
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getQuadrantHeader(_activeQuadrant),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getQuadrantColor(_activeQuadrant),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _quadrantTasks[_activeQuadrant]!.length,
                          itemBuilder: (context, index) {
                            final task = _quadrantTasks[_activeQuadrant]![index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    task['checked'] = !task['checked'];
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        task['checked']
                                            ? Icons.check_box_outlined
                                            : Icons.check_box_outline_blank_outlined,
                                        size: 18,
                                        color: task['checked'] ? primaryColor : Colors.white60,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          task['text'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            decoration: task['checked']
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: task['checked']
                                                ? Colors.white30
                                                : Colors.white80,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrantButton(String qId, String label, Color color) {
    final isActive = _activeQuadrant == qId;
    return InkWell(
      onTap: () {
        setState(() {
          _activeQuadrant = qId;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? color.withOpacity(0.25) : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: isActive ? color : Colors.white.withOpacity(0.1),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                qId,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isActive ? color : Colors.white60,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getQuadrantHeader(String qId) {
    switch (qId) {
      case 'Q1':
        return '🔥 Urgent & Important';
      case 'Q2':
        return '📅 Important, Not Urgent';
      case 'Q3':
        return '⚡ Urgent, Not Important';
      case 'Q4':
        return '🍃 Not Urgent or Important';
      default:
        return '';
    }
  }

  Color _getQuadrantColor(String qId) {
    switch (qId) {
      case 'Q1':
        return Colors.redAccent;
      case 'Q2':
        return Colors.blueAccent;
      case 'Q3':
        return Colors.orangeAccent;
      case 'Q4':
        return Colors.greenAccent;
      default:
        return Colors.white;
    }
  }
}
