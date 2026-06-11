import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';
import 'package:localmind_ai/features/downloads/domain/repositories/downloads_repository.dart';

class DownloadsRepositoryImpl implements DownloadsRepository {
  static const String boxName = 'downloadsBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  @override
  Future<void> saveTask(DownloadTaskModel task) async {
    final box = await _getBox();
    await box.put(task.id, task.toMap());
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final box = await _getBox();
    await box.delete(taskId);
  }

  @override
  Future<List<DownloadTaskModel>> getAllTasks() async {
    final box = await _getBox();
    return box.values.map((map) => DownloadTaskModel.fromMap(map as Map)).toList();
  }
}
