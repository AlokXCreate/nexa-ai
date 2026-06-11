import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/settings/domain/entities/backup_metadata.dart';
import 'package:localmind_ai/features/settings/domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  static const String metadataBoxName = 'backupMetadataBox';
  static const String settingsBoxName = 'settingsBox';

  Future<Box> _getMetadataBox() async {
    if (!Hive.isBoxOpen(metadataBoxName)) {
      return await Hive.openBox(metadataBoxName);
    }
    return Hive.box(metadataBoxName);
  }

  Future<Box> _getSettingsBox() async {
    if (!Hive.isBoxOpen(settingsBoxName)) {
      return await Hive.openBox(settingsBoxName);
    }
    return Hive.box(settingsBoxName);
  }

  @override
  Future<void> saveBackupMetadata(BackupMetadata metadata) async {
    final box = await _getMetadataBox();
    await box.put(metadata.id, metadata.toMap());
  }

  @override
  Future<void> deleteBackupMetadata(String id) async {
    final box = await _getMetadataBox();
    await box.delete(id);
  }

  @override
  Future<List<BackupMetadata>> getBackupMetadataList() async {
    final box = await _getMetadataBox();
    return box.values.map((map) => BackupMetadata.fromMap(map as Map)).toList();
  }

  @override
  Future<void> saveAutoBackupSchedule(String schedule) async {
    final box = await _getSettingsBox();
    await box.put('autoBackupSchedule', schedule);
  }

  @override
  Future<String> getAutoBackupSchedule() async {
    final box = await _getSettingsBox();
    return box.get('autoBackupSchedule', defaultValue: 'none') as String;
  }

  @override
  Future<void> saveConflictResolutionStrategy(String strategy) async {
    final box = await _getSettingsBox();
    await box.put('conflictResolutionStrategy', strategy);
  }

  @override
  Future<String> getConflictResolutionStrategy() async {
    final box = await _getSettingsBox();
    return box.get('conflictResolutionStrategy', defaultValue: 'merge_newer') as String;
  }

  @override
  Future<void> saveLastAutoBackupTime(DateTime time) async {
    final box = await _getSettingsBox();
    await box.put('lastAutoBackupTime', time.toIso8601String());
  }

  @override
  Future<DateTime?> getLastAutoBackupTime() async {
    final box = await _getSettingsBox();
    final str = box.get('lastAutoBackupTime') as String?;
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
