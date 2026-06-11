class AnalyticsReport {
  final String mostUsedModelId;
  final String mostUsedModelName;
  final double averageResponseTimeMs;
  final double averageInferenceSpeed;
  final int totalDownloads;
  final String favoriteCategory;
  final double totalStorageUsedGb;
  final int totalConversations;
  final int totalMessages;
  final double averagePromptLengthWords;
  final Map<String, int> modelUsageCounts;
  final String weeklyReportSummary;
  final String monthlyReportSummary;

  const AnalyticsReport({
    required this.mostUsedModelId,
    required this.mostUsedModelName,
    required this.averageResponseTimeMs,
    required this.averageInferenceSpeed,
    required this.totalDownloads,
    required this.favoriteCategory,
    required this.totalStorageUsedGb,
    required this.totalConversations,
    required this.totalMessages,
    required this.averagePromptLengthWords,
    required this.modelUsageCounts,
    required this.weeklyReportSummary,
    required this.monthlyReportSummary,
  });

  factory AnalyticsReport.empty() {
    return const AnalyticsReport(
      mostUsedModelId: 'N/A',
      mostUsedModelName: 'None',
      averageResponseTimeMs: 0.0,
      averageInferenceSpeed: 0.0,
      totalDownloads: 0,
      favoriteCategory: 'None',
      totalStorageUsedGb: 0.0,
      totalConversations: 0,
      totalMessages: 0,
      averagePromptLengthWords: 0.0,
      modelUsageCounts: {},
      weeklyReportSummary: 'No telemetry snapshot recorded for this week.',
      monthlyReportSummary: 'No telemetry snapshot recorded for this month.',
    );
  }
}
