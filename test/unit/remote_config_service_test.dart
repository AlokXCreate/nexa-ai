import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:localmind_ai/core/services/remote_config_service.dart';

class MockFirebaseRemoteConfig extends Fake implements FirebaseRemoteConfig {}

void main() {
  group('RemoteConfigService Hashing & Rollout Unit Tests', () {
    late RemoteConfigService service;
    late MockFirebaseRemoteConfig mockConfig;

    setUp(() {
      mockConfig = MockFirebaseRemoteConfig();
      service = RemoteConfigService(mockConfig);
    });

    test('isFeatureActiveForUser returns false for empty userId', () {
      final isActive = service.isFeatureActiveForUser('', 'test_feature', 50);
      expect(isActive, isFalse);
    });

    test('isFeatureActiveForUser bucket assignment is deterministic', () {
      final userA = 'user_12345';
      final activeFirst = service.isFeatureActiveForUser(userA, 'chat_redesign', 40);
      final activeSecond = service.isFeatureActiveForUser(userA, 'chat_redesign', 40);
      
      expect(activeFirst, equals(activeSecond));
    });

    test('isFeatureActiveForUser handles rollout boundary correct', () {
      // For 'user_A', hash code units sum:
      // u=117, s=115, e=101, r=114, _=95, A=65. Total = 607.
      // 607 % 100 = 7.
      final userA = 'user_A';
      
      // If rollout percent is 5, bucket 7 is not active
      expect(service.isFeatureActiveForUser(userA, 'feature', 5), isFalse);
      
      // If rollout percent is 10, bucket 7 is active
      expect(service.isFeatureActiveForUser(userA, 'feature', 10), isTrue);
    });
  });
}
