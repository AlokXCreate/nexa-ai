import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localmind_ai/features/community/domain/entities/community_model.dart';
import 'package:localmind_ai/features/community/domain/entities/model_review.dart';
import 'package:localmind_ai/features/community/domain/entities/model_collection.dart';
import 'package:localmind_ai/features/community/domain/entities/developer_profile.dart';
import 'package:localmind_ai/features/community/domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String modelsCacheBox = 'communityModelsCache';
  static const String collectionsCacheBox = 'communityCollectionsCache';
  static const String developersCacheBox = 'communityDevelopersCache';
  static const String bookmarksCacheBox = 'communityBookmarksCache';

  Future<Box> _getBox(String name) async {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox(name);
    }
    return Hive.box(name);
  }

  bool get _isAuthed => _auth.currentUser != null;

  @override
  Future<List<CommunityModel>> getModels({String? category, String? query}) async {
    final box = await _getBox(modelsCacheBox);

    if (_isAuthed) {
      try {
        Query q = _firestore.collection('community_models');
        if (category != null && category != 'All') {
          q = q.where('category', isEqualTo: category);
        }
        final snap = await q.get().timeout(const Duration(seconds: 4));
        final models = snap.docs.map((d) => CommunityModel.fromMap(d.data() as Map)).toList();

        // Update local cache
        await box.clear();
        for (final m in models) {
          await box.put(m.id, m.toMap());
        }
      } catch (_) {
        // Offline - fall through to cache
      }
    }

    // Read cache
    var cached = box.values.map((m) => CommunityModel.fromMap(m as Map)).toList();
    if (category != null && category != 'All') {
      cached = cached.where((m) => m.category == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      cached = cached.where((m) => 
        m.name.toLowerCase().contains(q) || 
        m.developerName.toLowerCase().contains(q) ||
        m.description.toLowerCase().contains(q)
      ).toList();
    }
    return cached;
  }

  @override
  Future<List<CommunityModel>> getTrendingModels() async {
    final list = await getModels();
    list.sort((a, b) => b.downloadsCount.compareTo(a.downloadsCount));
    return list.take(5).toList();
  }

  @override
  Future<List<CommunityModel>> getTopDownloadedModels() async {
    final list = await getModels();
    list.sort((a, b) => b.downloadsCount.compareTo(a.downloadsCount));
    return list;
  }

  @override
  Future<List<CommunityModel>> getEditorChoiceModels() async {
    final list = await getModels();
    return list.where((m) => m.isEditorChoice).toList();
  }

  @override
  Future<List<CommunityModel>> getRecentlyAddedModels() async {
    final list = await getModels();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<CommunityModel?> getModelById(String id) async {
    final box = await _getBox(modelsCacheBox);
    if (_isAuthed) {
      try {
        final doc = await _firestore.collection('community_models').doc(id).get();
        if (doc.exists && doc.data() != null) {
          final model = CommunityModel.fromMap(doc.data()!);
          await box.put(model.id, model.toMap());
          return model;
        }
      } catch (_) {}
    }
    final cachedData = box.get(id);
    return cachedData != null ? CommunityModel.fromMap(cachedData as Map) : null;
  }

  @override
  Future<void> uploadModel(CommunityModel model) async {
    final box = await _getBox(modelsCacheBox);
    await box.put(model.id, model.toMap());

    if (_isAuthed) {
      await _firestore.collection('community_models').doc(model.id).set(model.toMap());
      
      // Update developer profile model count
      try {
        final devDoc = _firestore.collection('developers').doc(model.developerId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(devDoc);
          if (snapshot.exists) {
            final data = snapshot.data() ?? {};
            final count = (data['modelsCount'] as int? ?? 0) + 1;
            transaction.update(devDoc, {'modelsCount': count});
          }
        });
      } catch (_) {}
    }
  }

  @override
  Future<void> bookmarkModel(String userId, String modelId) async {
    final box = await _getBox(bookmarksCacheBox);
    final list = (box.get(userId) as List?)?.cast<String>() ?? [];
    if (!list.contains(modelId)) {
      list.add(modelId);
      await box.put(userId, list);
    }

    if (_isAuthed) {
      await _firestore.collection('users').doc(userId).collection('bookmarks').doc(modelId).set({
        'bookmarkedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> unbookmarkModel(String userId, String modelId) async {
    final box = await _getBox(bookmarksCacheBox);
    final list = (box.get(userId) as List?)?.cast<String>() ?? [];
    if (list.contains(modelId)) {
      list.remove(modelId);
      await box.put(userId, list);
    }

    if (_isAuthed) {
      await _firestore.collection('users').doc(userId).collection('bookmarks').doc(modelId).delete();
    }
  }

  @override
  Future<List<String>> getBookmarkedModelIds(String userId) async {
    final box = await _getBox(bookmarksCacheBox);
    if (_isAuthed) {
      try {
        final snap = await _firestore.collection('users').doc(userId).collection('bookmarks').get();
        final ids = snap.docs.map((d) => d.id).toList();
        await box.put(userId, ids);
        return ids;
      } catch (_) {}
    }
    return (box.get(userId) as List?)?.cast<String>() ?? [];
  }

  @override
  Future<void> saveReview(ModelReview review) async {
    if (_isAuthed) {
      final docRef = _firestore.collection('community_models').doc(review.modelId).collection('reviews').doc(review.id);
      await docRef.set(review.toMap());

      // Re-calculate average model rating
      try {
        final reviewsSnap = await _firestore.collection('community_models').doc(review.modelId).collection('reviews').get();
        if (reviewsSnap.docs.isNotEmpty) {
          double totalRating = 0.0;
          for (final doc in reviewsSnap.docs) {
            totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 5.0;
          }
          final newAvg = totalRating / reviewsSnap.docs.length;
          await _firestore.collection('community_models').doc(review.modelId).update({
            'rating': newAvg,
            'reviewsCount': reviewsSnap.docs.length,
          });
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> likeReview(String modelId, String reviewId, String userId) async {
    if (_isAuthed) {
      final docRef = _firestore.collection('community_models').doc(modelId).collection('reviews').doc(reviewId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
          final likedList = (data['likedUsers'] as List?)?.cast<String>() ?? [];
          if (!likedList.contains(userId)) {
            likedList.add(userId);
            transaction.update(docRef, {
              'likedUsers': likedList,
              'likesCount': likedList.length,
            });
          }
        }
      });
    }
  }

  @override
  Future<List<ModelReview>> getReviewsForModel(String modelId) async {
    if (_isAuthed) {
      try {
        final snap = await _firestore.collection('community_models').doc(modelId).collection('reviews').orderBy('createdAt', descending: true).get();
        return snap.docs.map((d) => ModelReview.fromMap(d.data() as Map)).toList();
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<void> saveCollection(ModelCollection collection) async {
    final box = await _getBox(collectionsCacheBox);
    await box.put(collection.id, collection.toMap());

    if (_isAuthed) {
      await _firestore.collection('community_collections').doc(collection.id).set(collection.toMap());
    }
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    final box = await _getBox(collectionsCacheBox);
    await box.delete(collectionId);

    if (_isAuthed) {
      await _firestore.collection('community_collections').doc(collectionId).delete();
    }
  }

  @override
  Future<List<ModelCollection>> getCollections({bool publicOnly = true}) async {
    final box = await _getBox(collectionsCacheBox);

    if (_isAuthed) {
      try {
        Query q = _firestore.collection('community_collections');
        if (publicOnly) {
          q = q.where('isPublic', isEqualTo: true);
        }
        final snap = await q.get().timeout(const Duration(seconds: 4));
        final collections = snap.docs.map((d) => ModelCollection.fromMap(d.data() as Map)).toList();

        await box.clear();
        for (final c in collections) {
          await box.put(c.id, c.toMap());
        }
      } catch (_) {}
    }

    var cached = box.values.map((c) => ModelCollection.fromMap(c as Map)).toList();
    if (publicOnly) {
      cached = cached.where((c) => c.isPublic).toList();
    }
    return cached;
  }

  @override
  Future<ModelCollection?> getCollectionById(String collectionId) async {
    final box = await _getBox(collectionsCacheBox);
    if (_isAuthed) {
      try {
        final doc = await _firestore.collection('community_collections').doc(collectionId).get();
        if (doc.exists && doc.data() != null) {
          final col = ModelCollection.fromMap(doc.data()!);
          await box.put(col.id, col.toMap());
          return col;
        }
      } catch (_) {}
    }
    final cachedData = box.get(collectionId);
    return cachedData != null ? ModelCollection.fromMap(cachedData as Map) : null;
  }

  @override
  Future<void> followDeveloper(String developerId, String userId) async {
    final box = await _getBox(developersCacheBox);
    if (_isAuthed) {
      final devDoc = _firestore.collection('developers').doc(developerId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(devDoc);
        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
          final followers = (data['followers'] as List?)?.cast<String>() ?? [];
          if (!followers.contains(userId)) {
            followers.add(userId);
            transaction.update(devDoc, {
              'followers': followers,
              'followersCount': followers.length,
            });
            
            // Cache update
            final dev = DeveloperProfile.fromMap(data).copyWith(
              followers: followers,
              followersCount: followers.length,
            );
            await box.put(developerId, dev.toMap());
          }
        }
      });
    }
  }

  @override
  Future<void> unfollowDeveloper(String developerId, String userId) async {
    final box = await _getBox(developersCacheBox);
    if (_isAuthed) {
      final devDoc = _firestore.collection('developers').doc(developerId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(devDoc);
        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
          final followers = (data['followers'] as List?)?.cast<String>() ?? [];
          if (followers.contains(userId)) {
            followers.remove(userId);
            transaction.update(devDoc, {
              'followers': followers,
              'followersCount': followers.length,
            });
            
            // Cache update
            final dev = DeveloperProfile.fromMap(data).copyWith(
              followers: followers,
              followersCount: followers.length,
            );
            await box.put(developerId, dev.toMap());
          }
        }
      });
    }
  }

  @override
  Future<List<DeveloperProfile>> getDevelopers() async {
    final box = await _getBox(developersCacheBox);

    if (_isAuthed) {
      try {
        final snap = await _firestore.collection('developers').get();
        final list = snap.docs.map((d) => DeveloperProfile.fromMap(d.data() as Map)).toList();
        
        await box.clear();
        for (final d in list) {
          await box.put(d.id, d.toMap());
        }
      } catch (_) {}
    }

    // Load defaults if completely empty
    if (box.isEmpty) {
      final seedDevs = [
        DeveloperProfile(
          id: 'meta_ai',
          name: 'Meta AI',
          bio: 'Open-sourcing Llama models to push AI innovation forward.',
          avatarUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=120&auto=format&fit=crop',
          modelsCount: 4,
          followersCount: 1200,
          createdAt: DateTime.now(),
        ),
        DeveloperProfile(
          id: 'deepseek',
          name: 'DeepSeek',
          bio: 'High-performance open-weight LLMs from Beijing.',
          avatarUrl: 'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?w=120&auto=format&fit=crop',
          modelsCount: 2,
          followersCount: 890,
          createdAt: DateTime.now(),
        ),
      ];
      for (final d in seedDevs) {
        await box.put(d.id, d.toMap());
      }
    }

    return box.values.map((d) => DeveloperProfile.fromMap(d as Map)).toList();
  }

  @override
  Future<DeveloperProfile?> getDeveloperById(String id) async {
    final box = await _getBox(developersCacheBox);
    if (_isAuthed) {
      try {
        final doc = await _firestore.collection('developers').doc(id).get();
        if (doc.exists && doc.data() != null) {
          final dev = DeveloperProfile.fromMap(doc.data()!);
          await box.put(dev.id, dev.toMap());
          return dev;
        }
      } catch (_) {}
    }
    final cached = box.get(id);
    return cached != null ? DeveloperProfile.fromMap(cached as Map) : null;
  }
}
