import 'package:localmind_ai/features/plugins/domain/entities/cloud_provider_config.dart';
import 'package:localmind_ai/features/plugins/domain/entities/cloud_usage_stats.dart';

abstract class CloudConfigRepository {
  Future<void> saveConfig(CloudProviderConfig config);
  Future<List<CloudProviderConfig>> getConfigs();
  Future<CloudProviderConfig?> getConfigById(String providerId);
  Future<void> saveUsage(CloudUsageStats usage);
  Future<List<CloudUsageStats>> getUsageHistory();
  Future<void> clearUsage();
}
