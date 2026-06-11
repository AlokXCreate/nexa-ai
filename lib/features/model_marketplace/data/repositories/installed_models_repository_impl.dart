import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/installed_model.dart';
import 'package:localmind_ai/features/model_marketplace/domain/repositories/installed_models_repository.dart';

class InstalledModelsRepositoryImpl implements InstalledModelsRepository {
  static const String boxName = 'installedModelsBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  @override
  Future<void> saveModel(InstalledModel model) async {
    final box = await _getBox();
    await box.put(model.id, model.toMap());
  }

  @override
  Future<void> deleteModel(String modelId) async {
    final box = await _getBox();
    await box.delete(modelId);
  }

  @override
  Future<List<InstalledModel>> getInstalledModels() async {
    final box = await _getBox();
    
    if (box.isEmpty) {
      final defaultModel = InstalledModel(
        id: 'llama_3_2_3b',
        localName: 'Llama 3.2 (3B)',
        developer: 'Meta',
        version: '1.0.0',
        sizeString: '2.0 GB',
        sizeInGb: 2.0,
        ramRequirement: '4 GB',
        filePath: '/localmind/models/llama_3_2_3b.gguf',
        lastUsed: DateTime.now().subtract(const Duration(hours: 4)),
      );
      await box.put(defaultModel.id, defaultModel.toMap());
    }

    return box.values.map((map) => InstalledModel.fromMap(map as Map)).toList();
  }
}
