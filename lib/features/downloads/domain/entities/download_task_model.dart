enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadTaskModel {
  final String id;
  final String modelName;
  final String url;
  final String savePath;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final int priority; // higher numbers = higher priority
  final String? errorMessage;
  final String? checksum;

  const DownloadTaskModel({
    required this.id,
    required this.modelName,
    required this.url,
    required this.savePath,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.status,
    this.priority = 0,
    this.errorMessage,
    this.checksum,
  });

  DownloadTaskModel copyWith({
    String? id,
    String? modelName,
    String? url,
    String? savePath,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    int? priority,
    String? errorMessage,
    String? checksum,
  }) {
    return DownloadTaskModel(
      id: id ?? this.id,
      modelName: modelName ?? this.modelName,
      url: url ?? this.url,
      savePath: savePath ?? this.savePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      errorMessage: errorMessage ?? this.errorMessage,
      checksum: checksum ?? this.checksum,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modelName': modelName,
      'url': url,
      'savePath': savePath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.index,
      'priority': priority,
      'errorMessage': errorMessage,
      'checksum': checksum,
    };
  }

  factory DownloadTaskModel.fromMap(Map<dynamic, dynamic> map) {
    return DownloadTaskModel(
      id: map['id'] as String,
      modelName: map['modelName'] as String,
      url: map['url'] as String,
      savePath: map['savePath'] as String,
      totalBytes: map['totalBytes'] as int,
      downloadedBytes: map['downloadedBytes'] as int,
      status: DownloadStatus.values[map['status'] as int],
      priority: map['priority'] as int,
      errorMessage: map['errorMessage'] as String?,
      checksum: map['checksum'] as String?,
    );
  }
}
