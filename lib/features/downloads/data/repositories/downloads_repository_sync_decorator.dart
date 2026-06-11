import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/database/sync_operation.dart';
import 'package:localmind_ai/core/database/firestore_sync_service.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';
import 'package:localmind_ai/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';

class DownloadsRepositorySyncDecorator implements DownloadsRepository {
  final DownloadsRepository _delegate;
  final Ref _ref;

  DownloadsRepositorySyncDecorator(this._delegate, this._ref);

  FirestoreSyncService get _syncService => _ref.read(firestoreSyncServiceProvider);

  bool _isIncognito() {
    try {
      return _ref.read(securityControllerProvider).config.isIncognitoActive;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveTask(DownloadTaskModel task) async {
    await _delegate.saveTask(task);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'downloads',
        documentId: task.id,
        actionType: SyncActionType.save,
        data: task.toMap(),
      );
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _delegate.deleteTask(taskId);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'downloads',
        documentId: taskId,
        actionType: SyncActionType.delete,
      );
    }
  }

  @override
  Future<List<DownloadTaskModel>> getAllTasks() => _delegate.getAllTasks();
}
