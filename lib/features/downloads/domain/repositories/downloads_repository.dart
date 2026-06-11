import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';

abstract class DownloadsRepository {
  Future<void> saveTask(DownloadTaskModel task);
  Future<void> deleteTask(String taskId);
  Future<List<DownloadTaskModel>> getAllTasks();
}
