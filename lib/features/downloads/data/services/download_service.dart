import 'dart:async';
import 'dart:math';
import 'package:localmind_ai/features/downloads/domain/entities/download_progress.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';

class DownloadService {
  final _progressController = StreamController<DownloadProgress>.broadcast();
  final Map<String, Timer?> _activeTimers = {};
  final Map<String, int> _lastLoadedBytes = {};
  final Map<String, List<int>> _speedHistory = {}; // 3-second moving window

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  void startDownload(DownloadTaskModel task, Function(DownloadTaskModel) onUpdate) {
    if (_activeTimers.containsKey(task.id)) return;

    _lastLoadedBytes[task.id] = task.downloadedBytes;
    _speedHistory[task.id] = [];

    final timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final lastBytes = _lastLoadedBytes[task.id] ?? 0;
      
      // Speed fluctuations: 5MB to 15MB per tick (10MB/s to 30MB/s)
      final newChunk = (5 * 1024 * 1024) + Random().nextInt(10 * 1024 * 1024);
      final currentBytes = min(lastBytes + newChunk, task.totalBytes);
      _lastLoadedBytes[task.id] = currentBytes;

      final history = _speedHistory[task.id] ?? [];
      history.add(newChunk);
      if (history.length > 6) history.removeAt(0); // 3-second window

      final totalWindowBytes = history.fold<int>(0, (sum, val) => sum + val);
      final speedSeconds = totalWindowBytes / (history.length * 0.5); // total window size in seconds
      final speedMb = speedSeconds / (1024 * 1024);

      final remainingBytes = task.totalBytes - currentBytes;
      final eta = speedSeconds > 0 ? (remainingBytes / speedSeconds).ceil() : -1;

      _progressController.add(
        DownloadProgress(
          taskId: task.id,
          downloadedBytes: currentBytes,
          totalBytes: task.totalBytes,
          speedMbPerSecond: speedMb,
          etaSeconds: eta,
        ),
      );

      if (currentBytes >= task.totalBytes) {
        timer.cancel();
        _activeTimers.remove(task.id);
        onUpdate(task.copyWith(status: DownloadStatus.completed, downloadedBytes: task.totalBytes));
      } else {
        onUpdate(task.copyWith(status: DownloadStatus.downloading, downloadedBytes: currentBytes));
      }
    });

    _activeTimers[task.id] = timer;
  }

  void pauseDownload(String taskId) {
    _activeTimers[taskId]?.cancel();
    _activeTimers.remove(taskId);
  }

  void cancelDownload(String taskId) {
    _activeTimers[taskId]?.cancel();
    _activeTimers.remove(taskId);
    _lastLoadedBytes.remove(taskId);
    _speedHistory.remove(taskId);
  }
}
