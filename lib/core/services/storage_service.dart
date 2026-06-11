class DiskStorageMetrics {
  final double totalSpaceGb;
  final double freeSpaceGb;
  final double usedSpaceGb;

  const DiskStorageMetrics({
    required this.totalSpaceGb,
    required this.freeSpaceGb,
    required this.usedSpaceGb,
  });

  double get usedPercentage {
    if (totalSpaceGb <= 0) return 0.0;
    return (usedSpaceGb / totalSpaceGb) * 100.0;
  }
}

class StorageService {
  Future<DiskStorageMetrics> getStorageMetrics(double installedModelsTotalSizeGb) async {
    const double totalSpace = 128.0;
    const double systemUsedSpace = 48.0; 
    
    final double modelsUsedSpace = installedModelsTotalSizeGb;
    final double totalUsed = systemUsedSpace + modelsUsedSpace;
    final double freeSpace = totalSpace - totalUsed;

    return DiskStorageMetrics(
      totalSpaceGb: totalSpace,
      freeSpaceGb: freeSpace,
      usedSpaceGb: totalUsed,
    );
  }
}
