import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:localmind_ai/features/downloads/data/repositories/downloads_repository_sync_decorator.dart';
import 'package:localmind_ai/features/downloads/data/services/download_service.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_progress.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';
import 'package:localmind_ai/features/downloads/domain/repositories/downloads_repository.dart';

class DownloadsState {
  final List<DownloadTaskModel> queue;
  final Map<String, DownloadProgress> progressMap;
  final bool isLoading;

  const DownloadsState({
    this.queue = const [],
    this.progressMap = const {},
    this.isLoading = false,
  });

  DownloadsState copyWith({
    List<DownloadTaskModel>? queue,
    Map<String, DownloadProgress>? progressMap,
    bool? isLoading,
  }) {
    return DownloadsState(
      queue: queue ?? this.queue,
      progressMap: progressMap ?? this.progressMap,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DownloadsController extends StateNotifier<DownloadsState> {
  final DownloadsRepository _repository;
  final DownloadService _service = DownloadService();

  DownloadsController(this._repository) : super(const DownloadsState()) {
    _init();
  }

  void _init() async {
    state = state.copyWith(isLoading: true);
    final tasks = await _repository.getAllTasks();
    state = state.copyWith(queue: tasks, isLoading: false);

    _service.progressStream.listen((progress) {
      final updatedMap = Map<String, DownloadProgress>.from(state.progressMap);
      updatedMap[progress.taskId] = progress;
      state = state.copyWith(progressMap: updatedMap);
    });

    for (final task in tasks) {
      if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.pending) {
        resumeDownload(task.id);
      }
    }
  }

  Future<void> startNewDownload({
    required String modelId,
    required String modelName,
    required String url,
    required int totalBytes,
    int priority = 0,
  }) async {
    final task = DownloadTaskModel(
      id: modelId,
      modelName: modelName,
      url: url,
      savePath: '/localmind/models/$modelId.gguf',
      totalBytes: totalBytes,
      downloadedBytes: 0,
      status: DownloadStatus.pending,
      priority: priority,
    );

    await _repository.saveTask(task);
    
    final updatedQueue = [...state.queue, task];
    updatedQueue.sort((a, b) => b.priority.compareTo(a.priority));
    state = state.copyWith(queue: updatedQueue);

    resumeDownload(task.id);
  }

  void pauseDownload(String taskId) async {
    _service.pauseDownload(taskId);
    _updateTaskStatus(taskId, DownloadStatus.paused);
  }

  void resumeDownload(String taskId) async {
    final index = state.queue.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = state.queue[index];
    _service.startDownload(task, (updatedTask) {
      _updateTaskInStateAndDb(updatedTask);
    });
  }

  void cancelDownload(String taskId) async {
    _service.cancelDownload(taskId);
    await _repository.deleteTask(taskId);
    
    final updatedQueue = state.queue.where((t) => t.id != taskId).toList();
    final updatedMap = Map<String, DownloadProgress>.from(state.progressMap)..remove(taskId);
    state = state.copyWith(queue: updatedQueue, progressMap: updatedMap);
  }

  void retryDownload(String taskId) async {
    final index = state.queue.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = state.queue[index].copyWith(status: DownloadStatus.pending, downloadedBytes: 0);
    await _repository.saveTask(task);
    _updateTaskInStateAndDb(task);
    resumeDownload(taskId);
  }

  void _updateTaskStatus(String taskId, DownloadStatus status) async {
    final index = state.queue.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final updatedTask = state.queue[index].copyWith(status: status);
    await _repository.saveTask(updatedTask);
    _updateTaskInStateAndDb(updatedTask);
  }

  void _updateTaskInStateAndDb(DownloadTaskModel updatedTask) async {
    await _repository.saveTask(updatedTask);
    final updatedQueue = state.queue.map((t) => t.id == updatedTask.id ? updatedTask : t).toList();
    
    updatedQueue.sort((a, b) => b.priority.compareTo(a.priority));
    state = state.copyWith(queue: updatedQueue);
  }
}

final downloadsRepositoryProvider = Provider<DownloadsRepository>((ref) {
  final impl = DownloadsRepositoryImpl();
  return DownloadsRepositorySyncDecorator(impl, ref);
});

final downloadsControllerProvider = StateNotifierProvider<DownloadsController, DownloadsState>((ref) {
  return DownloadsController(ref.watch(downloadsRepositoryProvider));
});
