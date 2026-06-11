class BackupMetadata {
  final String id;
  final DateTime timestamp;
  final String fileName;
  final int fileSize;
  final String source; // 'local' | 'gdrive'
  final String filePath; // Local file path or Google Drive file ID
  final bool isEncrypted;
  final int version;

  BackupMetadata({
    required this.id,
    required this.timestamp,
    required this.fileName,
    required this.fileSize,
    required this.source,
    required this.filePath,
    required this.isEncrypted,
    this.version = 1,
  });

  BackupMetadata copyWith({
    String? id,
    DateTime? timestamp,
    String? fileName,
    int? fileSize,
    String? source,
    String? filePath,
    bool? isEncrypted,
    int? version,
  }) {
    return BackupMetadata(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      source: source ?? this.source,
      filePath: filePath ?? this.filePath,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'fileName': fileName,
      'fileSize': fileSize,
      'source': source,
      'filePath': filePath,
      'isEncrypted': isEncrypted,
      'version': version,
    };
  }

  factory BackupMetadata.fromMap(Map<dynamic, dynamic> map) {
    return BackupMetadata(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      fileName: map['fileName'] as String,
      fileSize: map['fileSize'] as int,
      source: map['source'] as String,
      filePath: map['filePath'] as String,
      isEncrypted: map['isEncrypted'] as bool? ?? false,
      version: map['version'] as int? ?? 1,
    );
  }
}
