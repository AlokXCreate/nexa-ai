class SecurityConfig {
  final bool isBiometricEnabled;
  final bool isPinEnabled;
  final String pinCodeObfuscated;
  final bool isIncognitoActive;
  final List<String> privateSessionIds;

  const SecurityConfig({
    required this.isBiometricEnabled,
    required this.isPinEnabled,
    required this.pinCodeObfuscated,
    required this.isIncognitoActive,
    required this.privateSessionIds,
  });

  factory SecurityConfig.defaultConfig() {
    return const SecurityConfig(
      isBiometricEnabled: false,
      isPinEnabled: false,
      pinCodeObfuscated: '',
      isIncognitoActive: false,
      privateSessionIds: [],
    );
  }

  SecurityConfig copyWith({
    bool? isBiometricEnabled,
    bool? isPinEnabled,
    String? pinCodeObfuscated,
    bool? isIncognitoActive,
    List<String>? privateSessionIds,
  }) {
    return SecurityConfig(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      pinCodeObfuscated: pinCodeObfuscated ?? this.pinCodeObfuscated,
      isIncognitoActive: isIncognitoActive ?? this.isIncognitoActive,
      privateSessionIds: privateSessionIds ?? this.privateSessionIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isBiometricEnabled': isBiometricEnabled,
      'isPinEnabled': isPinEnabled,
      'pinCodeObfuscated': pinCodeObfuscated,
      'isIncognitoActive': isIncognitoActive,
      'privateSessionIds': privateSessionIds,
    };
  }

  factory SecurityConfig.fromMap(Map<dynamic, dynamic> map) {
    return SecurityConfig(
      isBiometricEnabled: map['isBiometricEnabled'] as bool? ?? false,
      isPinEnabled: map['isPinEnabled'] as bool? ?? false,
      pinCodeObfuscated: map['pinCodeObfuscated'] as String? ?? '',
      isIncognitoActive: map['isIncognitoActive'] as bool? ?? false,
      privateSessionIds: (map['privateSessionIds'] as List?)?.map((e) => e as String).toList() ?? const [],
    );
  }
}
