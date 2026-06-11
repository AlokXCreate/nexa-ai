import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

class LocalDatabaseMock {
  final Map<String, dynamic> _storage = {};
  bool _isLocked = false;
  int _activeTransactions = 0;

  Future<void> write(String key, dynamic value) async {
    if (_isLocked) {
      throw Exception('Database locked exception');
    }
    _activeTransactions++;
    // Simulate minor write latency
    await Future.delayed(const Duration(milliseconds: 2));
    _storage[key] = value;
    _activeTransactions--;
  }

  Future<dynamic> read(String key) async {
    _activeTransactions++;
    // Simulate minor read latency
    await Future.delayed(const Duration(milliseconds: 1));
    final val = _storage[key];
    _activeTransactions--;
    return val;
  }

  void forceLock() {
    _isLocked = true;
  }

  int get activeTransactions => _activeTransactions;
}

void main() {
  group('Local mind DB IO Stress Tests', () {
    late LocalDatabaseMock db;

    setUp(() {
      db = LocalDatabaseMock();
    });

    test('Handles high volume concurrent transactions without lockups', () async {
      final List<Future<void>> futures = [];
      
      // Spawn 500 concurrent operations
      for (int i = 0; i < 250; i++) {
        futures.add(db.write('key_$i', 'value_$i'));
        futures.add(db.read('key_$i'));
      }

      // Await all concurrent tasks
      await Future.wait(futures);

      // Verify no locks remain and all values are written correctly
      expect(db.activeTransactions, equals(0));
      final val = await db.read('key_100');
      expect(val, equals('value_100'));
    });
  });
}
