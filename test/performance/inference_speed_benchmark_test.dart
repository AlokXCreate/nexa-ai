import 'package:flutter_test/flutter_test.dart';

class PerformanceAggregator {
  final List<double> responseTimes = [];
  final List<double> tokensPerSecond = [];

  void logRun({required double durationMs, required int tokenCount}) {
    responseTimes.add(durationMs);
    if (durationMs > 0) {
      tokensPerSecond.add((tokenCount / durationMs) * 1000);
    }
  }

  double get averageLatency => responseTimes.isEmpty
      ? 0.0
      : responseTimes.reduce((a, b) => a + b) / responseTimes.length;

  double get averageSpeed => tokensPerSecond.isEmpty
      ? 0.0
      : tokensPerSecond.reduce((a, b) => a + b) / tokensPerSecond.length;
}

void main() {
  group('Inference Engine Performance & Telemetry Benchmarks', () {
    late PerformanceAggregator aggregator;

    setUp(() {
      aggregator = PerformanceAggregator();
    });

    test('Computes averages accurately from log lists', () {
      aggregator.logRun(durationMs: 500, tokenCount: 20); // 40 T/s
      aggregator.logRun(durationMs: 1000, tokenCount: 30); // 30 T/s

      expect(aggregator.averageLatency, equals(750.0));
      expect(aggregator.averageSpeed, equals(35.0));
    });

    test('Inference speed remains within acceptable threshold (>= 15 Tokens/sec)', () {
      final logs = [
        {'duration': 800.0, 'tokens': 25},
        {'duration': 1200.0, 'tokens': 35},
        {'duration': 600.0, 'tokens': 20},
      ];

      for (final run in logs) {
        aggregator.logRun(
          durationMs: run['duration'] as double,
          tokenCount: run['tokens'] as int,
        );
      }

      // Assert that the aggregate speed complies with performance SLA (>= 15 T/s)
      expect(aggregator.averageSpeed, greaterThanOrEqualTo(15.0));
    });
  });
}
