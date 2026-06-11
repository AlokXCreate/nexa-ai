class AppSettings {
  final String themeMode; // 'system', 'light', 'dark'
  final String accentColor; // 'purple', 'cyan', 'emerald', 'amber', 'rose'
  final String fontSize; // 'small', 'medium', 'large'
  final String animationSpeed; // 'slow', 'normal', 'fast'
  final String? defaultModelId;
  final int maxContextSize;
  final String inferenceMode; // 'auto', 'cpu', 'gpu'
  final bool showPerformanceMonitor;
  final bool enableDebugLogs;
  final bool showTokenCounter;
  final String downloadLocation;
  final String languageCode; // 'en', 'hi', 'es', 'fr', 'de', 'ja', 'ko', 'zh', 'ar', 'pt'
  final bool highContrast;
  
  // Custom theme overrides from active Plugins
  final String? customPrimaryColor;
  final String? customAccentColor;
  final String? customBgColor;
  final String? customSurfaceColor;

  const AppSettings({
    required this.themeMode,
    required this.accentColor,
    required this.fontSize,
    required this.animationSpeed,
    this.defaultModelId,
    required this.maxContextSize,
    required this.inferenceMode,
    required this.showPerformanceMonitor,
    required this.enableDebugLogs,
    required this.showTokenCounter,
    required this.downloadLocation,
    required this.languageCode,
    required this.highContrast,
    this.customPrimaryColor,
    this.customAccentColor,
    this.customBgColor,
    this.customSurfaceColor,
  });

  AppSettings copyWith({
    String? themeMode,
    String? accentColor,
    String? fontSize,
    String? animationSpeed,
    String? defaultModelId,
    int? maxContextSize,
    String? inferenceMode,
    bool? showPerformanceMonitor,
    bool? enableDebugLogs,
    bool? showTokenCounter,
    String? downloadLocation,
    String? languageCode,
    bool? highContrast,
    String? customPrimaryColor,
    String? customAccentColor,
    String? customBgColor,
    String? customSurfaceColor,
    bool clearDefaultModel = false,
    bool clearCustomColors = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      fontSize: fontSize ?? this.fontSize,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      defaultModelId: clearDefaultModel ? null : (defaultModelId ?? this.defaultModelId),
      maxContextSize: maxContextSize ?? this.maxContextSize,
      inferenceMode: inferenceMode ?? this.inferenceMode,
      showPerformanceMonitor: showPerformanceMonitor ?? this.showPerformanceMonitor,
      enableDebugLogs: enableDebugLogs ?? this.enableDebugLogs,
      showTokenCounter: showTokenCounter ?? this.showTokenCounter,
      downloadLocation: downloadLocation ?? this.downloadLocation,
      languageCode: languageCode ?? this.languageCode,
      highContrast: highContrast ?? this.highContrast,
      customPrimaryColor: clearCustomColors ? null : (customPrimaryColor ?? this.customPrimaryColor),
      customAccentColor: clearCustomColors ? null : (customAccentColor ?? this.customAccentColor),
      customBgColor: clearCustomColors ? null : (customBgColor ?? this.customBgColor),
      customSurfaceColor: clearCustomColors ? null : (customSurfaceColor ?? this.customSurfaceColor),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'accentColor': accentColor,
      'fontSize': fontSize,
      'animationSpeed': animationSpeed,
      'defaultModelId': defaultModelId,
      'maxContextSize': maxContextSize,
      'inferenceMode': inferenceMode,
      'showPerformanceMonitor': showPerformanceMonitor,
      'enableDebugLogs': enableDebugLogs,
      'showTokenCounter': showTokenCounter,
      'downloadLocation': downloadLocation,
      'languageCode': languageCode,
      'highContrast': highContrast,
      'customPrimaryColor': customPrimaryColor,
      'customAccentColor': customAccentColor,
      'customBgColor': customBgColor,
      'customSurfaceColor': customSurfaceColor,
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      themeMode: map['themeMode'] as String? ?? 'system',
      accentColor: map['accentColor'] as String? ?? 'purple',
      fontSize: map['fontSize'] as String? ?? 'medium',
      animationSpeed: map['animationSpeed'] as String? ?? 'normal',
      defaultModelId: map['defaultModelId'] as String?,
      maxContextSize: map['maxContextSize'] as int? ?? 2048,
      inferenceMode: map['inferenceMode'] as String? ?? 'auto',
      showPerformanceMonitor: map['showPerformanceMonitor'] as bool? ?? false,
      enableDebugLogs: map['enableDebugLogs'] as bool? ?? false,
      showTokenCounter: map['showTokenCounter'] as bool? ?? false,
      downloadLocation: map['downloadLocation'] as String? ?? '/localmind/models',
      languageCode: map['languageCode'] as String? ?? 'en',
      highContrast: map['highContrast'] as bool? ?? false,
      customPrimaryColor: map['customPrimaryColor'] as String?,
      customAccentColor: map['customAccentColor'] as String?,
      customBgColor: map['customBgColor'] as String?,
      customSurfaceColor: map['customSurfaceColor'] as String?,
    );
  }

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      themeMode: 'system',
      accentColor: 'purple',
      fontSize: 'medium',
      animationSpeed: 'normal',
      defaultModelId: null,
      maxContextSize: 2048,
      inferenceMode: 'auto',
      showPerformanceMonitor: false,
      enableDebugLogs: false,
      showTokenCounter: false,
      downloadLocation: '/localmind/models',
      languageCode: 'en',
      highContrast: false,
    );
  }
}
