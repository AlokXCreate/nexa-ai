import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

class LeakTargetController {
  final StreamController<String> _streamController = StreamController<String>.broadcast();
  StreamSubscription<String>? _subscription;
  bool isDisposed = false;

  LeakTargetController() {
    _subscription = _streamController.stream.listen((event) {});
  }

  void emit(String val) {
    if (isDisposed) return;
    _streamController.add(val);
  }

  void dispose() {
    _subscription?.cancel();
    _streamController.close();
    isDisposed = true;
  }

  bool get hasActiveListeners => _streamController.hasListener;
}

void main() {
  group('Memory Leak & Resource Disposal Audit', () {
    test('Stream Controller disposes listeners and closes channel cleanly', () {
      final controller = LeakTargetController();

      // Initially must have active subscriptions
      expect(controller.hasActiveListeners, isTrue);

      // Perform updates
      controller.emit('ping');

      // Dispose controller
      controller.dispose();

      // After disposal, it should have no active listeners and be closed
      expect(controller.isDisposed, isTrue);
      expect(controller.hasActiveListeners, isFalse);
    });
  });
}
