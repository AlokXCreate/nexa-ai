class RagDocument {
  final String id;
  final String name;
  final String filePath;
  final String fileType; // pdf, docx, txt, md, html
  final String? folderId;
  final int sizeBytes;
  final int chunkCount;
  final DateTime uploadedAt;
  final bool isActive;

  const RagDocument({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileType,
    this.folderId,
    required this.sizeBytes,
    required this.chunkCount,
    required this.uploadedAt,
    this.isActive = true,
  });

  RagDocument copyWith({
    String? name,
    String? folderId,
    bool? isActive,
    bool clearFolder = false,
  }) {
    return RagDocument(
      id: id,
      name: name ?? this.name,
      filePath: filePath,
      fileType: fileType,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      sizeBytes: sizeBytes,
      chunkCount: chunkCount,
      uploadedAt: uploadedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'fileType': fileType,
      'folderId': folderId,
      'sizeBytes': sizeBytes,
      'chunkCount': chunkCount,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory RagDocument.fromMap(Map<dynamic, dynamic> map) {
    return RagDocument(
      id: map['id'] as String,
      name: map['name'] as String,
      filePath: map['filePath'] as String,
      fileType: map['fileType'] as String,
      folderId: map['folderId'] as String?,
      sizeBytes: map['sizeBytes'] as int,
      chunkCount: map['chunkCount'] as int,
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
