class ModelUpdateInfo {
  final String modelId;
  final String modelName;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadSize;
  final String? deltaSize;
  final bool isDeltaAvailable;
  final String ramRequirement;
  final String installedSize;
  final bool isCompatible;
  final bool hasStorageSpace;

  const ModelUpdateInfo({
    required this.modelId,
    required this.modelName,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadSize,
    this.deltaSize,
    required this.isDeltaAvailable,
    required this.ramRequirement,
    required this.installedSize,
    required this.isCompatible,
    required this.hasStorageSpace,
  });

  ModelUpdateInfo copyWith({
    bool? isCompatible,
    bool? hasStorageSpace,
  }) {
    return ModelUpdateInfo(
      modelId: modelId,
      modelName: modelName,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      releaseNotes: releaseNotes,
      downloadSize: downloadSize,
      deltaSize: deltaSize,
      isDeltaAvailable: isDeltaAvailable,
      ramRequirement: ramRequirement,
      installedSize: installedSize,
      isCompatible: isCompatible ?? this.isCompatible,
      hasStorageSpace: hasStorageSpace ?? this.hasStorageSpace,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modelId': modelId,
      'modelName': modelName,
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'releaseNotes': releaseNotes,
      'downloadSize': downloadSize,
      'deltaSize': deltaSize,
      'isDeltaAvailable': isDeltaAvailable,
      'ramRequirement': ramRequirement,
      'installedSize': installedSize,
      'isCompatible': isCompatible,
      'hasStorageSpace': hasStorageSpace,
    };
  }

  factory ModelUpdateInfo.fromMap(Map<dynamic, dynamic> map) {
    return ModelUpdateInfo(
      modelId: map['modelId'] as String,
      modelName: map['modelName'] as String,
      currentVersion: map['currentVersion'] as String,
      latestVersion: map['latestVersion'] as String,
      releaseNotes: map['releaseNotes'] as String,
      downloadSize: map['downloadSize'] as String,
      deltaSize: map['deltaSize'] as String?,
      isDeltaAvailable: map['isDeltaAvailable'] as bool,
      ramRequirement: map['ramRequirement'] as String,
      installedSize: map['installedSize'] as String,
      isCompatible: map['isCompatible'] as bool,
      hasStorageSpace: map['hasStorageSpace'] as bool,
    );
  }
}
