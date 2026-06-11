import 'package:localmind_ai/features/settings/domain/entities/backup_metadata.dart';

abstract class BackupRepository {
  Future<void> saveBackupMetadata(BackupMetadata metadata);
  Future<void> deleteBackupMetadata(String id);
  Future<List<BackupMetadata>> getBackupMetadataList();
  
  Future<void> saveAutoBackupSchedule(String schedule); // 'none', 'daily', 'weekly'
  Future<String> getAutoBackupSchedule();
  
  Future<void> saveConflictResolutionStrategy(String strategy); // 'overwrite', 'merge_newer', 'merge_keep_both'
  Future<String> getConflictResolutionStrategy();
  
  Future<void> saveLastAutoBackupTime(DateTime time);
  Future<DateTime?> getLastAutoBackupTime();
}
