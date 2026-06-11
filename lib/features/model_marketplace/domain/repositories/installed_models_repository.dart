import 'package:localmind_ai/features/model_marketplace/domain/entities/installed_model.dart';

abstract class InstalledModelsRepository {
  Future<void> saveModel(InstalledModel model);
  Future<void> deleteModel(String modelId);
  Future<List<InstalledModel>> getInstalledModels();
}
