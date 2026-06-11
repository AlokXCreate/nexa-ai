import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/model_marketplace/domain/repositories/model_update_repository.dart';

class ModelUpdateRepositoryImpl implements ModelUpdateRepository {
  static const String boxName = 'modelUpdatesBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  @override
  Future<void> saveBackupVersion(String modelId, String version) async {
    final box = await _getBox();
    final backups = Map<String, String>.from(box.get('backups', defaultValue: <dynamic, dynamic>{}));
    backups[modelId] = version;
    await box.put('backups', backups);
  }

  @override
  Future<String?> getBackupVersion(String modelId) async {
    final box = await _getBox();
    final backups = box.get('backups', defaultValue: <dynamic, dynamic>{});
    return backups[modelId] as String?;
  }

  @override
  Future<void> removeBackupVersion(String modelId) async {
    final box = await _getBox();
    final backups = Map<String, String>.from(box.get('backups', defaultValue: <dynamic, dynamic>{}));
    backups.remove(modelId);
    await box.put('backups', backups);
  }

  @override
  Future<Map<String, String>> getAllBackupVersions() async {
    final box = await _getBox();
    final backups = box.get('backups', defaultValue: <dynamic, dynamic>{});
    return Map<String, String>.from(backups);
  }

  @override
  Future<void> saveLastCheckTime(DateTime time) async {
    final box = await _getBox();
    await box.put('lastCheckTime', time.toIso8601String());
  }

  @override
  Future<DateTime?> getLastCheckTime() async {
    final box = await _getBox();
    final str = box.get('lastCheckTime') as String?;
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
