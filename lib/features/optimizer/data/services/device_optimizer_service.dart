import 'dart:io';
import 'dart:math';
import 'package:localmind_ai/features/optimizer/domain/entities/device_info.dart';

class DeviceOptimizerService {
  Future<DeviceInfo> getDeviceDiagnostics() async {
    // 1. Core Platform & OS Information
    final osName = Platform.operatingSystem;
    final osVersion = Platform.operatingSystemVersion;
    final cores = Platform.numberOfProcessors;

    // 2. RAM estimation based on Platform and standard heuristics
    double totalRam = 8.0;
    if (Platform.isWindows || Platform.isMacOS) {
      totalRam = 16.0; // standard laptop RAM
    } else if (Platform.isAndroid || Platform.isIOS) {
      totalRam = 8.0; // standard mobile RAM
    }
    
    // Simulate background memory load (usually 30% to 50% RAM occupied by OS)
    final double freeRam = totalRam * (0.5 + Random().nextDouble() * 0.15);

    // 3. Storage estimation
    const double totalStorage = 256.0;
    final double freeStorage = 120.0 + Random().nextInt(50); // mock free space

    // 4. CPU & GPU descriptions based on platform
    String cpuDescription = 'Octa-Core Processor';
    String gpuDescription = 'Integrated Neural Engine';
    if (Platform.isWindows) {
      cpuDescription = 'Intel Core i7 Processor';
      gpuDescription = 'NVIDIA GeForce RTX GPU';
    } else if (Platform.isMacOS) {
      cpuDescription = 'Apple M-Series Silicon';
      gpuDescription = 'Apple Neural Engine';
    } else if (Platform.isAndroid) {
      cpuDescription = 'Snapdragon Octa-Core Processor';
      gpuDescription = 'Adreno GPU';
    }

    // 5. Battery metrics
    final batteryLevel = 70 + Random().nextInt(30);
    final isCharging = Random().nextBool();

    // 6. Estimated local inference speed (TPS proxy)
    // Cores, RAM capacity and neural engines increase estimated speed
    double estSpeed = cores * 3.5;
    if (gpuDescription.toLowerCase().contains('nvidia') || gpuDescription.toLowerCase().contains('neural')) {
      estSpeed += 12.0;
    }

    return DeviceInfo(
      totalRamGb: totalRam,
      freeRamGb: freeRam,
      totalStorageGb: totalStorage,
      freeStorageGb: freeStorage,
      cpuName: cpuDescription,
      cpuCores: cores,
      gpuName: gpuDescription,
      androidVersion: '$osName ($osVersion)',
      batteryLevel: batteryLevel,
      isBatteryCharging: isCharging,
      estimatedTps: estSpeed,
    );
  }

  String getRecommendedQuantization(double totalRam) {
    if (totalRam <= 4.0) {
      return 'Q2_K';
    } else if (totalRam <= 6.0) {
      return 'Q3_K_M';
    } else if (totalRam <= 10.0) {
      return 'Q4_K_M';
    } else if (totalRam <= 16.0) {
      return 'Q5_K_M';
    } else {
      return 'Q8_0';
    }
  }

  int getRecommendedContextSize(double totalRam) {
    if (totalRam <= 4.0) {
      return 1024;
    } else if (totalRam <= 8.0) {
      return 2048;
    } else if (totalRam <= 16.0) {
      return 4096;
    } else {
      return 8192;
    }
  }

  double getSafeMemoryAllocationGb(double totalRam) {
    // Retain 40% for the system, allocate 60% safely
    return totalRam * 0.6;
  }
}
