class DownloadProgress {
  final String taskId;
  final int downloadedBytes;
  final int totalBytes;
  final double speedMbPerSecond;
  final int etaSeconds; // -1 if unknown

  const DownloadProgress({
    required this.taskId,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speedMbPerSecond,
    required this.etaSeconds,
  });

  double get percentage {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes) * 100.0;
  }

  String get speedString => '${speedMbPerSecond.toStringAsFixed(1)} MB/s';

  String get etaString {
    if (etaSeconds < 0) return 'Calculating...';
    if (etaSeconds < 60) return '$etaSeconds sec remaining';
    final minutes = etaSeconds ~/ 60;
    final seconds = etaSeconds % 60;
    return '$minutes m $seconds s remaining';
  }

  String get sizeFractionString {
    final downloaded = (downloadedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
    final total = (totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
    return '$downloaded GB / $total GB';
  }
}
