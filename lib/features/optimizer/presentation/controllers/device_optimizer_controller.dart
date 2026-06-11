import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/optimizer/domain/entities/device_info.dart';
import 'package:localmind_ai/features/optimizer/data/services/device_optimizer_service.dart';
import 'package:localmind_ai/features/model_marketplace/domain/entities/marketplace_model.dart';
import 'package:localmind_ai/features/model_marketplace/presentation/controllers/marketplace_notifier.dart';

class DeviceOptimizerState {
  final DeviceInfo deviceInfo;
  final String recommendedQuantization;
  final int recommendedContextSize;
  final double safeMemoryAllocationGb;
  final List<MarketplaceModel> recommendedModels;
  final bool isScanning;
  final double scanProgress;
  final String? error;

  const DeviceOptimizerState({
    required this.deviceInfo,
    this.recommendedQuantization = 'Q4_K_M',
    this.recommendedContextSize = 2048,
    this.safeMemoryAllocationGb = 4.8,
    this.recommendedModels = const [],
    this.isScanning = false,
    this.scanProgress = 0.0,
    this.error,
  });

  DeviceOptimizerState copyWith({
    DeviceInfo? deviceInfo,
    String? recommendedQuantization,
    int? recommendedContextSize,
    double? safeMemoryAllocationGb,
    List<MarketplaceModel>? recommendedModels,
    bool? isScanning,
    double? scanProgress,
    String? error,
    bool clearError = false,
  }) {
    return DeviceOptimizerState(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      recommendedQuantization: recommendedQuantization ?? this.recommendedQuantization,
      recommendedContextSize: recommendedContextSize ?? this.recommendedContextSize,
      safeMemoryAllocationGb: safeMemoryAllocationGb ?? this.safeMemoryAllocationGb,
      recommendedModels: recommendedModels ?? this.recommendedModels,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DeviceOptimizerController extends StateNotifier<DeviceOptimizerState> {
  final DeviceOptimizerService _service = DeviceOptimizerService();
  final Ref _ref;

  DeviceOptimizerController(this._ref) : super(DeviceOptimizerState(deviceInfo: DeviceInfo.unknown())) {
    scanDevice(silent: true);
  }

  Future<void> scanDevice({bool silent = false}) async {
    if (state.isScanning) return;

    if (silent) {
      final info = await _service.getDeviceDiagnostics();
      final quant = _service.getRecommendedQuantization(info.totalRamGb);
      final ctx = _service.getRecommendedContextSize(info.totalRamGb);
      final safeMem = _service.getSafeMemoryAllocationGb(info.totalRamGb);
      final recommended = _filterModels(info.totalRamGb, safeMem);
      
      state = state.copyWith(
        deviceInfo: info,
        recommendedQuantization: quant,
        recommendedContextSize: ctx,
        safeMemoryAllocationGb: safeMem,
        recommendedModels: recommended,
        isScanning: false,
        scanProgress: 1.0,
      );
      return;
    }

    state = state.copyWith(
      isScanning: true,
      scanProgress: 0.0,
      clearError: true,
    );

    int ticks = 0;
    const maxTicks = 10;
    
    Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      ticks++;
      final currentProgress = ticks / maxTicks;
      state = state.copyWith(scanProgress: currentProgress);

      if (ticks >= maxTicks) {
        timer.cancel();
        try {
          final info = await _service.getDeviceDiagnostics();
          final quant = _service.getRecommendedQuantization(info.totalRamGb);
          final ctx = _service.getRecommendedContextSize(info.totalRamGb);
          final safeMem = _service.getSafeMemoryAllocationGb(info.totalRamGb);
          final recommended = _filterModels(info.totalRamGb, safeMem);

          state = state.copyWith(
            deviceInfo: info,
            recommendedQuantization: quant,
            recommendedContextSize: ctx,
            safeMemoryAllocationGb: safeMem,
            recommendedModels: recommended,
            isScanning: false,
            scanProgress: 1.0,
          );
        } catch (e) {
          state = state.copyWith(
            isScanning: false,
            error: 'Failed to scan hardware diagnostics: $e',
          );
        }
      }
    });
  }

  bool isModelSafe(String ramRequirement) {
    final digits = RegExp(r'\d+').firstMatch(ramRequirement);
    if (digits != null) {
      final reqRam = double.parse(digits.group(0)!);
      return reqRam <= state.safeMemoryAllocationGb;
    }
    return true; // default safe if we fail to parse
  }

  List<MarketplaceModel> _filterModels(double totalRam, double safeMemLimit) {
    final marketplaceState = _ref.read(marketplaceNotifierProvider);
    final allModels = marketplaceState.models;

    return allModels.where((m) {
      final digits = RegExp(r'\d+').firstMatch(m.ramRequirement);
      if (digits != null) {
        final reqRam = double.parse(digits.group(0)!);
        // We recommend it if it fits strictly inside our safe memory allocation limit
        return reqRam <= safeMemLimit;
      }
      return true;
    }).toList();
  }
}

final deviceOptimizerControllerProvider = StateNotifierProvider<DeviceOptimizerController, DeviceOptimizerState>((ref) {
  return DeviceOptimizerController(ref);
});
