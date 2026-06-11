import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/repositories/marketplace_repository.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/installed_models_controller.dart';
import 'package:localmind_ai/features/downloads/presentation/controllers/downloads_controller.dart';
import 'package:localmind_ai/features/downloads/domain/entities/download_task_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/installed_model.dart';

class ModelDetailsState {
  final MarketplaceModel? model;
  final bool isFavorite;
  final bool isInstalled;
  final bool isDownloading;
  final double downloadProgress;
  final String downloadSpeed;
  final String downloadEta;
  final String? error;

  const ModelDetailsState({
    this.model,
    this.isFavorite = false,
    this.isInstalled = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.downloadSpeed = '0.0 MB/s',
    this.downloadEta = '',
    this.error,
  });

  ModelDetailsState copyWith({
    MarketplaceModel? model,
    bool? isFavorite,
    bool? isInstalled,
    bool? isDownloading,
    double? downloadProgress,
    String? downloadSpeed,
    String? downloadEta,
    String? error,
    bool clearError = false,
  }) {
    return ModelDetailsState(
      model: model ?? this.model,
      isFavorite: isFavorite ?? this.isFavorite,
      isInstalled: isInstalled ?? this.isInstalled,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      downloadEta: downloadEta ?? this.downloadEta,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ModelDetailsController extends StateNotifier<ModelDetailsState> {
  final MarketplaceRepository _repository;
  final Ref _ref;
  final String _modelId;
  static const String settingsBoxName = 'settingsBox';

  ModelDetailsController(this._repository, this._ref, this._modelId)
      : super(const ModelDetailsState()) {
    _init();
  }

  void _init() async {
    final model = await _repository.getModelById(_modelId);
    if (model == null) {
      state = state.copyWith(error: 'Model not found in catalog.');
      return;
    }

    final settingsBox = Hive.isBoxOpen(settingsBoxName)
        ? Hive.box(settingsBoxName)
        : await Hive.openBox(settingsBoxName);
    final favorites = settingsBox.get('favorites', defaultValue: <dynamic>[]) as List;
    final isFavorite = favorites.contains(_modelId);

    // Initial check of downloads and installed states
    final downloadsState = _ref.read(downloadsControllerProvider);
    final installedState = _ref.read(installedModelsControllerProvider);

    final isInstalled = installedState.installedModels.any((m) => m.id == _modelId);
    
    final progress = downloadsState.progressMap[_modelId];
    final queueTaskIndex = downloadsState.queue.indexWhere((t) => t.id == _modelId);
    final queueTask = queueTaskIndex != -1 ? downloadsState.queue[queueTaskIndex] : null;
    final isDownloading = progress != null && queueTask?.status == DownloadStatus.downloading;

    state = ModelDetailsState(
      model: model,
      isFavorite: isFavorite,
      isInstalled: isInstalled,
      isDownloading: isDownloading,
      downloadProgress: progress != null ? progress.downloadedBytes / progress.totalBytes : 0.0,
      downloadSpeed: progress != null ? '${progress.speedMbPerSecond.toStringAsFixed(1)} MB/s' : '0.0 MB/s',
      downloadEta: progress != null ? _formatEta(progress.etaSeconds) : '',
    );
  }

  void updateDownloadProgress(DownloadsState next) {
    if (state.model == null) return;
    final progress = next.progressMap[_modelId];
    final queueTaskIndex = next.queue.indexWhere((t) => t.id == _modelId);
    final queueTask = queueTaskIndex != -1 ? next.queue[queueTaskIndex] : null;
    
    final isDownloading = progress != null && queueTask?.status == DownloadStatus.downloading;
    
    state = state.copyWith(
      isDownloading: isDownloading,
      downloadProgress: progress != null ? progress.downloadedBytes / progress.totalBytes : 0.0,
      downloadSpeed: progress != null ? '${progress.speedMbPerSecond.toStringAsFixed(1)} MB/s' : '0.0 MB/s',
      downloadEta: progress != null ? _formatEta(progress.etaSeconds) : '',
      isInstalled: queueTask?.status == DownloadStatus.completed ? true : state.isInstalled,
    );
  }

  void updateInstalledState(InstalledModelsState next) {
    final isInstalled = next.installedModels.any((m) => m.id == _modelId);
    state = state.copyWith(isInstalled: isInstalled);
  }

  String _formatEta(int seconds) {
    if (seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  // Favorite Toggling
  Future<void> toggleFavorite() async {
    if (state.model == null) return;
    final settingsBox = Hive.isBoxOpen(settingsBoxName)
        ? Hive.box(settingsBoxName)
        : await Hive.openBox(settingsBoxName);
    
    final favorites = List<String>.from(
      settingsBox.get('favorites', defaultValue: <dynamic>[]) as List
    );

    final updatedFavs = [...favorites];
    bool nextFav = false;

    if (updatedFavs.contains(_modelId)) {
      updatedFavs.remove(_modelId);
      nextFav = false;
    } else {
      updatedFavs.add(_modelId);
      nextFav = true;
    }

    await settingsBox.put('favorites', updatedFavs);
    state = state.copyWith(isFavorite: nextFav);
  }

  // Action dispatches
  void startDownload() {
    final model = state.model;
    if (model == null) return;

    final bytes = _parseSizeToBytes(model.downloadSize);

    _ref.read(downloadsControllerProvider.notifier).startNewDownload(
      modelId: model.id,
      modelName: model.name,
      url: model.downloadUrl,
      totalBytes: bytes,
    );
  }

  void pauseDownload() {
    _ref.read(downloadsControllerProvider.notifier).pauseDownload(_modelId);
  }

  void resumeDownload() {
    _ref.read(downloadsControllerProvider.notifier).resumeDownload(_modelId);
  }

  void cancelDownload() {
    _ref.read(downloadsControllerProvider.notifier).cancelDownload(_modelId);
  }

  void deleteModel() {
    _ref.read(installedModelsControllerProvider.notifier).deleteModel(_modelId);
  }

  void runModel() {
    _ref.read(installedModelsControllerProvider.notifier).runModel(_modelId);
  }

  Future<void> checkForUpdates() async {
    // Check version difference and reinstall if there is a mismatch
    final installedState = _ref.read(installedModelsControllerProvider);
    final installedIndex = installedState.installedModels.indexWhere((m) => m.id == _modelId);
    if (installedIndex == -1 || state.model == null) return;

    final installedModel = installedState.installedModels[installedIndex];
    if (installedModel.version != state.model!.version) {
      // Version mismatch, delete old and redownload
      await _ref.read(installedModelsControllerProvider.notifier).deleteModel(_modelId);
      startDownload();
    }
  }

  int _parseSizeToBytes(String val) {
    final clean = val.replaceAll(RegExp(r'[^\d.]'), '');
    final num = double.tryParse(clean) ?? 0.0;
    if (val.toUpperCase().contains('GB')) {
      return (num * 1024 * 1024 * 1024).toInt();
    }
    if (val.toUpperCase().contains('MB')) {
      return (num * 1024 * 1024).toInt();
    }
    return (num * 1024 * 1024 * 1024).toInt(); // default fallback to GB
  }
}

final modelDetailsControllerProvider =
    StateNotifierProvider.family<ModelDetailsController, ModelDetailsState, String>((ref, modelId) {
  final repo = ref.watch(marketplaceRepositoryProvider);
  final controller = ModelDetailsController(repo, ref, modelId);

  ref.listen<DownloadsState>(downloadsControllerProvider, (prev, next) {
    controller.updateDownloadProgress(next);
  });
  ref.listen<InstalledModelsState>(installedModelsControllerProvider, (prev, next) {
    controller.updateInstalledState(next);
  });

  return controller;
});
