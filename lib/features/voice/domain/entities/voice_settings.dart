class VoiceSettings {
  final String? voiceName;
  final double speechRate;
  final bool isHandsFree;

  VoiceSettings({
    this.voiceName,
    this.speechRate = 1.0,
    this.isHandsFree = false,
  });

  VoiceSettings copyWith({
    String? voiceName,
    double? speechRate,
    bool? isHandsFree,
    bool clearVoice = false,
  }) {
    return VoiceSettings(
      voiceName: clearVoice ? null : (voiceName ?? this.voiceName),
      speechRate: speechRate ?? this.speechRate,
      isHandsFree: isHandsFree ?? this.isHandsFree,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voiceName': voiceName,
      'speechRate': speechRate,
      'isHandsFree': isHandsFree,
    };
  }

  factory VoiceSettings.fromMap(Map<dynamic, dynamic> map) {
    return VoiceSettings(
      voiceName: map['voiceName'] as String?,
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 1.0,
      isHandsFree: map['isHandsFree'] as bool? ?? false,
    );
  }

  factory VoiceSettings.defaultSettings() {
    return VoiceSettings(
      voiceName: null,
      speechRate: 1.0,
      isHandsFree: false,
    );
  }
}
