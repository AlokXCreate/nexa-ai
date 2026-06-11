abstract class ModelUpdateRepository {
  Future<void> saveBackupVersion(String modelId, String version);
  Future<String?> getBackupVersion(String modelId);
  Future<void> removeBackupVersion(String modelId);
  Future<Map<String, String>> getAllBackupVersions();
  Future<void> saveLastCheckTime(DateTime time);
  Future<DateTime?> getLastCheckTime();
}
