import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/model_update_info.dart';
import 'package:localmind_ai/features/model_marketplace/domain/repositories/model_update_repository.dart';
import 'package:localmind_ai/features/model_marketplace/data/repositories/model_update_repository_impl.dart';
import 'package:localmind_ai/features/model_marketplace/data/services/model_update_service.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/downloads/presentation/controllers/downloads_controller.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/marketplace_notifier.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/installed_model.dart';

class ModelUpdateState {
  final Map<String, ModelUpdateInfo> availableUpdates;
  final Map<String, String> backupVersions; 
  final bool isChecking;
  final bool isUpdating;
  final String? activeUpdateModelId;
  final String? error;
  final DateTime? lastCheckTime;
  final String? notificationMessage; 

  const ModelUpdateState({
    this.availableUpdates = const {},
    this.backupVersions = const {},
    this.isChecking = false,
    this.isUpdating = false,
    this.activeUpdateModelId,
    this.error,
    this.lastCheckTime,
    this.notificationMessage,
  });

  ModelUpdateState copyWith({
    Map<String, ModelUpdateInfo>? availableUpdates,
    Map<String, String>? backupVersions,
    bool? isChecking,
    bool? isUpdating,
    String? activeUpdateModelId,
    String? error,
    DateTime? lastCheckTime,
    String? notificationMessage,
    bool clearError = false,
    bool clearNotification = false,
  }) {
    return ModelUpdateState(
      availableUpdates: availableUpdates ?? this.availableUpdates,
      backupVersions: backupVersions ?? this.backupVersions,
      isChecking: isChecking ?? this.isChecking,
      isUpdating: isUpdating ?? this.isUpdating,
      activeUpdateModelId: activeUpdateModelId ?? this.activeUpdateModelId,
      error: clearError ? null : (error ?? this.error),
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      notificationMessage: clearNotification ? null : (notificationMessage ?? this.notificationMessage),
    );
  }
}

class ModelUpdateController extends StateNotifier<ModelUpdateState> {
  final ModelUpdateRepository _repository;
  final ModelUpdateService _service = ModelUpdateService();
  final Ref _ref;

  ModelUpdateController(this._repository, this._ref) : super(const ModelUpdateState()) {
    _init();
  }

  void _init() async {
    final checkTime = await _repository.getLastCheckTime();
    final backups = await _repository.getAllBackupVersions();
    
    state = state.copyWith(
      lastCheckTime: checkTime,
      backupVersions: backups,
    );

    // Initial check after dependencies are ready
    Future.delayed(const Duration(seconds: 1), () {
      checkForUpdates(silent: true);
    });

    // Background update checker: check for updates periodically every 4 hours
    Timer.periodic(const Duration(hours: 4), (timer) {
      checkForUpdates(silent: true);
    });
  }

  void handleDownloadUpdate(DownloadsState downloads) {
    final activeId = state.activeUpdateModelId;
    if (activeId == null) return;

    final taskIndex = downloads.queue.indexWhere((t) => t.id == activeId);
    if (taskIndex == -1) return;

    final task = downloads.queue[taskIndex];
    if (task.status == DownloadStatus.completed) {
      _finalizeUpdate(activeId);
    } else if (task.status == DownloadStatus.failed) {
      state = state.copyWith(
        isUpdating: false,
        activeUpdateModelId: null,
        error: 'Update download failed: ${task.errorMessage ?? "Unknown error"}',
      );
    }
  }

  Future<void> checkForUpdates({bool silent = false}) async {
    if (state.isChecking) return;
    state = state.copyWith(isChecking: true, clearError: true);

    try {
      final installedState = _ref.read(installedModelsControllerProvider);
      final catalogState = _ref.read(marketplaceNotifierProvider);
      
      final installed = installedState.installedModels;
      final catalog = catalogState.models;

      final double freeStorage = installedState.storageMetrics?.freeSpaceGb ?? 180.0;
      const double deviceRam = 8.0; 

      final updates = _service.checkForUpdates(
        installed: installed,
        catalog: catalog,
        deviceRamGb: deviceRam,
        freeStorageGb: freeStorage,
      );

      final Map<String, ModelUpdateInfo> updatesMap = {};
      for (final up in updates) {
        updatesMap[up.modelId] = up;
      }

      final checkTime = DateTime.now();
      await _repository.saveLastCheckTime(checkTime);

      state = state.copyWith(
        availableUpdates: updatesMap,
        lastCheckTime: checkTime,
        isChecking: false,
        notificationMessage: (!silent && updates.isNotEmpty)
            ? 'New updates found for ${updates.length} model(s)!'
            : null,
      );
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: 'Failed to check for updates: $e',
      );
    }
  }

  Future<void> installUpdate(String modelId, {bool useDelta = true}) async {
    final updateInfo = state.availableUpdates[modelId];
    if (updateInfo == null) return;

    if (!updateInfo.isCompatible) {
      state = state.copyWith(error: 'Model update is incompatible with device memory limits.');
      return;
    }

    if (!updateInfo.hasStorageSpace) {
      state = state.copyWith(error: 'Insufficient storage space to download model update.');
      return;
    }

    state = state.copyWith(isUpdating: true, activeUpdateModelId: modelId, clearError: true);

    try {
      final installedState = _ref.read(installedModelsControllerProvider);
      final installedIndex = installedState.installedModels.indexWhere((m) => m.id == modelId);
      if (installedIndex == -1) {
        state = state.copyWith(isUpdating: false, activeUpdateModelId: null, error: 'Model is not currently installed.');
        return;
      }

      final installedModel = installedState.installedModels[installedIndex];

      // 1. Rename existing model file to create a backup
      await _service.backupModelFile(installedModel.filePath);
      await _repository.saveBackupVersion(modelId, installedModel.version);

      final updatedBackups = await _repository.getAllBackupVersions();
      state = state.copyWith(backupVersions: updatedBackups);

      // 2. Fetch catalog details for download
      final catalogState = _ref.read(marketplaceNotifierProvider);
      final catMatch = catalogState.models.firstWhere((m) => m.id == modelId);

      // Calculate download sizes: delta updates download 25% of total
      final totalSizeGb = _parseSizeToGb(catMatch.downloadSize);
      final targetSizeGb = (useDelta && updateInfo.isDeltaAvailable) ? (totalSizeGb * 0.25) : totalSizeGb;
      final totalBytes = (targetSizeGb * 1024 * 1024 * 1024).toInt();

      // 3. Trigger Download
      await _ref.read(downloadsControllerProvider.notifier).startNewDownload(
        modelId: modelId,
        modelName: catMatch.name,
        url: catMatch.downloadUrl,
        totalBytes: totalBytes,
        priority: 10, // high priority for updates
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        activeUpdateModelId: null,
        error: 'Failed to initiate update download: $e',
      );
    }
  }

  Future<void> _finalizeUpdate(String modelId) async {
    try {
      final catalogState = _ref.read(marketplaceNotifierProvider);
      final catMatch = catalogState.models.firstWhere((m) => m.id == modelId);

      final updatedInstalled = InstalledModel(
        id: modelId,
        localName: catMatch.name,
        developer: catMatch.developer,
        version: catMatch.version,
        sizeString: catMatch.downloadSize,
        sizeInGb: _parseSizeToGb(catMatch.downloadSize),
        ramRequirement: catMatch.ramRequirement,
        filePath: '/localmind/models/$modelId.gguf',
        lastUsed: DateTime.now(),
      );

      // Save updated model record in repo
      await _ref.read(installedModelsRepositoryProvider).saveModel(updatedInstalled);
      
      // Refresh list
      await _ref.read(installedModelsControllerProvider.notifier).fetchInstalledModels();

      final updatedUpdates = Map<String, ModelUpdateInfo>.from(state.availableUpdates)..remove(modelId);

      state = state.copyWith(
        availableUpdates: updatedUpdates,
        isUpdating: false,
        activeUpdateModelId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        activeUpdateModelId: null,
        error: 'Failed to finalize updated model installation: $e',
      );
    }
  }

  Future<void> rollback(String modelId) async {
    final backupVer = state.backupVersions[modelId];
    if (backupVer == null) return;

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final installedState = _ref.read(installedModelsControllerProvider);
      final installedMatch = installedState.installedModels.firstWhere((m) => m.id == modelId);

      // 1. Physically rename backup .bak back to .gguf
      await _service.rollbackModelFile(installedMatch.filePath);

      // 2. Restore DB details
      final revertedModel = InstalledModel(
        id: modelId,
        localName: installedMatch.localName,
        developer: installedMatch.developer,
        version: backupVer,
        sizeString: installedMatch.sizeString,
        sizeInGb: installedMatch.sizeInGb,
        ramRequirement: installedMatch.ramRequirement,
        filePath: installedMatch.filePath,
        lastUsed: DateTime.now(),
      );

      await _ref.read(installedModelsRepositoryProvider).saveModel(revertedModel);
      await _repository.removeBackupVersion(modelId);

      final updatedBackups = await _repository.getAllBackupVersions();
      await _ref.read(installedModelsControllerProvider.notifier).fetchInstalledModels();

      state = state.copyWith(
        backupVersions: updatedBackups,
        isUpdating: false,
      );

      // Trigger recalculate check
      checkForUpdates(silent: true);
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to perform model rollback: $e',
      );
    }
  }

  Future<void> discardBackup(String modelId) async {
    try {
      final installedState = _ref.read(installedModelsControllerProvider);
      final installedMatch = installedState.installedModels.firstWhere((m) => m.id == modelId);

      await _service.discardBackupFile(installedMatch.filePath);
      await _repository.removeBackupVersion(modelId);

      final updatedBackups = await _repository.getAllBackupVersions();
      state = state.copyWith(backupVersions: updatedBackups);
    } catch (e) {
      state = state.copyWith(error: 'Failed to discard backup: $e');
    }
  }

  void clearNotification() {
    state = state.copyWith(clearNotification: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  double _parseSizeToGb(String val) {
    final clean = val.replaceAll(RegExp(r'[^\d.]'), '');
    final num = double.tryParse(clean) ?? 0.0;
    if (val.toUpperCase().contains('MB')) {
      return num / 1024.0;
    }
    return num;
  }
}

final modelUpdateRepositoryProvider = Provider<ModelUpdateRepository>((ref) {
  return ModelUpdateRepositoryImpl();
});

final modelUpdateControllerProvider =
    StateNotifierProvider<ModelUpdateController, ModelUpdateState>((ref) {
  final repo = ref.watch(modelUpdateRepositoryProvider);
  final controller = ModelUpdateController(repo, ref);

  ref.listen<DownloadsState>(downloadsControllerProvider, (prev, next) {
    controller.handleDownloadUpdate(next);
  });

  return controller;
});
