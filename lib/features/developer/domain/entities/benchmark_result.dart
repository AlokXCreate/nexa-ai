class BenchmarkResult {
  final double singleThreadSpeed; // tokens/sec
  final double multiThreadSpeed; // tokens/sec
  final double memoryBandwidth; // GB/s
  final double ramPeakMb;
  final int overallScore;
  final String grade; // e.g. 'S (Elite)', 'A (Optimal)', 'B (Standard)'
  final DateTime completedAt;

  const BenchmarkResult({
    required this.singleThreadSpeed,
    required this.multiThreadSpeed,
    required this.memoryBandwidth,
    required this.ramPeakMb,
    required this.overallScore,
    required this.grade,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'singleThreadSpeed': singleThreadSpeed,
      'multiThreadSpeed': multiThreadSpeed,
      'memoryBandwidth': memoryBandwidth,
      'ramPeakMb': ramPeakMb,
      'overallScore': overallScore,
      'grade': grade,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory BenchmarkResult.fromMap(Map<dynamic, dynamic> map) {
    return BenchmarkResult(
      singleThreadSpeed: (map['singleThreadSpeed'] as num).toDouble(),
      multiThreadSpeed: (map['multiThreadSpeed'] as num).toDouble(),
      memoryBandwidth: (map['memoryBandwidth'] as num).toDouble(),
      ramPeakMb: (map['ramPeakMb'] as num).toDouble(),
      overallScore: map['overallScore'] as int,
      grade: map['grade'] as String,
      completedAt: DateTime.parse(map['completedAt'] as String),
    );
  }
}
