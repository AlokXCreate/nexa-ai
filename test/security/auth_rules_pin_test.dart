import 'package:flutter_test/flutter_test.dart';

class PinSecurityManager {
  static const String correctPinHash = '81dc9bdb52d04dc20036dbd8313ed055'; // MD5 for '1234'
  int _failedAttempts = 0;
  bool _isLockedOut = false;

  bool verifyPin(String pin) {
    if (_isLockedOut) return false;
    
    // Hash simulation
    final hash = _hashPin(pin);
    if (hash == correctPinHash) {
      _failedAttempts = 0;
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _isLockedOut = true;
      }
      return false;
    }
  }

  String _hashPin(String pin) {
    // Basic hash stub representing MD5 '1234'
    if (pin == '1234') return '81dc9bdb52d04dc20036dbd8313ed055';
    return 'invalid_hash';
  }

  bool get isLockedOut => _isLockedOut;
  int get failedAttempts => _failedAttempts;
}

void main() {
  group('PIN Gating & Security Authentication Lock Tests', () {
    late PinSecurityManager manager;

    setUp(() {
      manager = PinSecurityManager();
    });

    test('Access is granted for correct PIN', () {
      final success = manager.verifyPin('1234');
      expect(success, isTrue);
      expect(manager.isLockedOut, isFalse);
    });

    test('Access is denied for incorrect PIN', () {
      final success = manager.verifyPin('9999');
      expect(success, isFalse);
      expect(manager.failedAttempts, equals(1));
    });

    test('User is locked out after 5 consecutive failed attempts', () {
      // 5 failed verification attempts
      for (int i = 0; i < 5; i++) {
        expect(manager.verifyPin('9999'), isFalse);
      }

      expect(manager.isLockedOut, isTrue);
      
      // Even correct PIN fails once locked out
      expect(manager.verifyPin('1234'), isFalse);
    });
  });
}
