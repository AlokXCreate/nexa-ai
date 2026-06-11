import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/services/storage_service.dart';
import 'package:localmind_ai/features/model_marketplace/data/repositories/installed_models_repository_impl.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/installed_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/repositories/installed_models_repository.dart';

class InstalledModelsState {
  final List<InstalledModel> installedModels;
  final DiskStorageMetrics? storageMetrics;
  final bool isLoading;

  const InstalledModelsState({
    this.installedModels = const [],
    this.storageMetrics,
    this.isLoading = false,
  });

  InstalledModelsState copyWith({
    List<InstalledModel>? installedModels,
    DiskStorageMetrics? storageMetrics,
    bool? isLoading,
  }) {
    return InstalledModelsState(
      installedModels: installedModels ?? this.installedModels,
      storageMetrics: storageMetrics ?? this.storageMetrics,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class InstalledModelsController extends StateNotifier<InstalledModelsState> {
  final InstalledModelsRepository _repository;
  final StorageService _storageService = StorageService();

  InstalledModelsController(this._repository) : super(const InstalledModelsState()) {
    fetchInstalledModels();
  }

  Future<void> fetchInstalledModels() async {
    state = state.copyWith(isLoading: true);
    try {
      final models = await _repository.getInstalledModels();
      final totalGb = models.fold<double>(0.0, (sum, item) => sum + item.sizeInGb);
      final metrics = await _storageService.getStorageMetrics(totalGb);
      
      state = state.copyWith(
        installedModels: models,
        storageMetrics: metrics,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> renameModel(String modelId, String newName) async {
    final index = state.installedModels.indexWhere((m) => m.id == modelId);
    if (index == -1) return;

    final updatedModel = state.installedModels[index].copyWith(localName: newName);
    await _repository.saveModel(updatedModel);
    await fetchInstalledModels();
  }

  Future<void> deleteModel(String modelId) async {
    await _repository.deleteModel(modelId);
    await fetchInstalledModels();
  }

  Future<void> runModel(String modelId) async {
    final index = state.installedModels.indexWhere((m) => m.id == modelId);
    if (index == -1) return;

    final updatedModel = state.installedModels[index].copyWith(lastUsed: DateTime.now());
    await _repository.saveModel(updatedModel);
    await fetchInstalledModels();
  }
}

final installedModelsRepositoryProvider = Provider<InstalledModelsRepository>((ref) {
  return InstalledModelsRepositoryImpl();
});

final installedModelsControllerProvider = StateNotifierProvider<InstalledModelsController, InstalledModelsState>((ref) {
  return InstalledModelsController(ref.watch(installedModelsRepositoryProvider));
});
