import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/core/database/sync_operation.dart';

class FirestoreSyncService {
  static const String queueBoxName = 'firebaseSyncQueue';
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Timer? _syncTimer;
  bool _isSyncing = false;

  FirestoreSyncService(this._firestore, this._auth) {
    _startPeriodicSync();
    _auth.authStateChanges().listen((user) {
      if (user != null && !user.isAnonymous) {
        triggerSync();
      }
    });
  }

  Future<Box> _getQueueBox() async {
    if (!Hive.isBoxOpen(queueBoxName)) {
      return await Hive.openBox(queueBoxName);
    }
    return Hive.box(queueBoxName);
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      triggerSync();
    });
  }

  void dispose() {
    _syncTimer?.cancel();
  }

  /// Add operation to local sync queue.
  Future<void> queueOperation({
    required String collectionName,
    required String documentId,
    required SyncActionType actionType,
    Map<String, dynamic>? data,
  }) async {
    final operation = SyncOperation(
      collectionName: collectionName,
      documentId: documentId,
      actionType: actionType,
      data: data,
      timestamp: DateTime.now(),
    );

    final box = await _getQueueBox();
    await box.add(operation.toMap());

    // Try to trigger sync immediately
    triggerSync();
  }

  /// Triggers flush of the sync queue to Firestore if connected and authenticated.
  Future<void> triggerSync() async {
    if (_isSyncing) return;
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    final online = await _isOnline();
    if (!online) return;

    _isSyncing = true;
    try {
      final box = await _getQueueBox();
      if (box.isEmpty) {
        _isSyncing = false;
        return;
      }

      final keys = List.from(box.keys);
      for (final key in keys) {
        final map = box.get(key);
        if (map == null) continue;

        final op = SyncOperation.fromMap(map as Map);
        final success = await _processSyncOperation(user.uid, op);
        if (success) {
          await box.delete(key);
        } else {
          // If we fail a sync item, stop and retry later
          break;
        }
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _isOnline() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _processSyncOperation(String userId, SyncOperation op) async {
    try {
      final docRef = _getDocRef(userId, op.collectionName, op.documentId);

      if (op.actionType == SyncActionType.delete) {
        await docRef.delete();
        return true;
      }

      // SyncActionType.save (LWW logic)
      final data = Map<String, dynamic>.from(op.data ?? {});
      data['syncedAt'] = FieldValue.serverTimestamp();

      // Get timestamp field from local data (could be updatedAt, lastActiveTime, or createdAt)
      final localTimestampStr = data['updatedAt'] ?? data['lastActiveTime'] ?? data['createdAt'] ?? op.timestamp.toIso8601String();
      final localTime = DateTime.tryParse(localTimestampStr) ?? op.timestamp;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final remoteData = snapshot.data();
          if (remoteData != null) {
            final remoteTimestampStr = remoteData['updatedAt'] ?? remoteData['lastActiveTime'] ?? remoteData['createdAt'];
            if (remoteTimestampStr != null) {
              final remoteTime = DateTime.tryParse(remoteTimestampStr as String) ?? DateTime.fromMillisecondsSinceEpoch(0);
              if (remoteTime.isAfter(localTime)) {
                // Remote is newer, do not overwrite (LWW)
                return;
              }
            }
          }
        }
        transaction.set(docRef, data, SetOptions(merge: true));
      });

      return true;
    } catch (e) {
      debugPrint('Error syncing operation: $e');
      return false;
    }
  }

  DocumentReference _getDocRef(String userId, String collection, String docId) {
    return _firestore.collection('users/$userId/$collection').doc(docId);
  }
}

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService(FirebaseFirestore.instance, FirebaseAuth.instance);
});
