import 'package:localmind_ai/features/developer/domain/entities/analytics_report.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsReport> generateReport();
  Future<String> getWeeklyReportText(AnalyticsReport report);
  Future<String> getMonthlyReportText(AnalyticsReport report);
}
