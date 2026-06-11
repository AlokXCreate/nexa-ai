class DeviceInfo {
  final double totalRamGb;
  final double freeRamGb;
  final double totalStorageGb;
  final double freeStorageGb;
  final String cpuName;
  final int cpuCores;
  final String gpuName;
  final String androidVersion;
  final int batteryLevel;
  final bool isBatteryCharging;
  final double estimatedTps;

  const DeviceInfo({
    required this.totalRamGb,
    required this.freeRamGb,
    required this.totalStorageGb,
    required this.freeStorageGb,
    required this.cpuName,
    required this.cpuCores,
    required this.gpuName,
    required this.androidVersion,
    required this.batteryLevel,
    required this.isBatteryCharging,
    required this.estimatedTps,
  });

  factory DeviceInfo.unknown() {
    return const DeviceInfo(
      totalRamGb: 0.0,
      freeRamGb: 0.0,
      totalStorageGb: 0.0,
      freeStorageGb: 0.0,
      cpuName: 'Unknown',
      cpuCores: 1,
      gpuName: 'Unknown',
      androidVersion: 'Unknown',
      batteryLevel: 100,
      isBatteryCharging: false,
      estimatedTps: 0.0,
    );
  }

  DeviceInfo copyWith({
    double? totalRamGb,
    double? freeRamGb,
    double? totalStorageGb,
    double? freeStorageGb,
    String? cpuName,
    int? cpuCores,
    String? gpuName,
    String? androidVersion,
    int? batteryLevel,
    bool? isBatteryCharging,
    double? estimatedTps,
  }) {
    return DeviceInfo(
      totalRamGb: totalRamGb ?? this.totalRamGb,
      freeRamGb: freeRamGb ?? this.freeRamGb,
      totalStorageGb: totalStorageGb ?? this.totalStorageGb,
      freeStorageGb: freeStorageGb ?? this.freeStorageGb,
      cpuName: cpuName ?? this.cpuName,
      cpuCores: cpuCores ?? this.cpuCores,
      gpuName: gpuName ?? this.gpuName,
      androidVersion: androidVersion ?? this.androidVersion,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isBatteryCharging: isBatteryCharging ?? this.isBatteryCharging,
      estimatedTps: estimatedTps ?? this.estimatedTps,
    );
  }
}
