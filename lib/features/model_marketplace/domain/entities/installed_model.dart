class InstalledModel {
  final String id;
  final String localName;
  final String developer;
  final String version;
  final String sizeString;
  final double sizeInGb;
  final String ramRequirement;
  final String filePath;
  final DateTime lastUsed;

  const InstalledModel({
    required this.id,
    required this.localName,
    required this.developer,
    required this.version,
    required this.sizeString,
    required this.sizeInGb,
    required this.ramRequirement,
    required this.filePath,
    required this.lastUsed,
  });

  InstalledModel copyWith({
    String? localName,
    DateTime? lastUsed,
  }) {
    return InstalledModel(
      id: id,
      localName: localName ?? this.localName,
      developer: developer,
      version: version,
      sizeString: sizeString,
      sizeInGb: sizeInGb,
      ramRequirement: ramRequirement,
      filePath: filePath,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localName': localName,
      'developer': developer,
      'version': version,
      'sizeString': sizeString,
      'sizeInGb': sizeInGb,
      'ramRequirement': ramRequirement,
      'filePath': filePath,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory InstalledModel.fromMap(Map<dynamic, dynamic> map) {
    return InstalledModel(
      id: map['id'] as String,
      localName: map['localName'] as String,
      developer: map['developer'] as String,
      version: map['version'] as String,
      sizeString: map['sizeString'] as String,
      sizeInGb: map['sizeInGb'] as double,
      ramRequirement: map['ramRequirement'] as String,
      filePath: map['filePath'] as String,
      lastUsed: DateTime.parse(map['lastUsed'] as String),
    );
  }
}
