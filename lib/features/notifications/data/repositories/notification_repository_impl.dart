import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:localmind_ai/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String boxName = 'notificationsBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  bool get _isAuthed => _auth.currentUser != null;
  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<List<AppNotification>> getNotifications() async {
    final box = await _getBox();

    if (_isAuthed) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .get()
            .timeout(const Duration(seconds: 4));
        
        final list = snap.docs.map((d) => AppNotification.fromMap(d.data() as Map)).toList();
        
        // Cache locally
        await box.clear();
        for (final n in list) {
          await box.put(n.id, n.toMap());
        }
      } catch (_) {
        // Offline - fallback silently to cached files
      }
    }

    final cached = box.values.map((map) => AppNotification.fromMap(map as Map)).toList();
    cached.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return cached;
  }

  @override
  Future<void> saveNotification(AppNotification notification) async {
    final box = await _getBox();
    await box.put(notification.id, notification.toMap());

    if (_isAuthed) {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    final box = await _getBox();
    final data = box.get(id);
    if (data != null) {
      final updated = AppNotification.fromMap(data as Map).copyWith(isRead: true);
      await box.put(id, updated.toMap());
    }

    if (_isAuthed) {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(id)
          .update({'isRead': true});
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final box = await _getBox();
    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final updated = AppNotification.fromMap(data as Map).copyWith(isRead: true);
        await box.put(key, updated.toMap());
      }
    }

    if (_isAuthed) {
      final snap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    final box = await _getBox();
    await box.delete(id);

    if (_isAuthed) {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(id)
          .delete();
    }
  }

  @override
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();

    if (_isAuthed) {
      final snap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
