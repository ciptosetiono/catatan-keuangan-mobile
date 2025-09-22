// ignore_for_file: empty_catches

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryService {
  final CollectionReference categoriesRef = FirebaseFirestore.instance
      .collection('categories');

  // Cache lokal
  final List<Category> _localCache = [];

  // ======================= Stream / Get Categories =======================
  Stream<List<Category>> getCategoryStream({
    String? query,
    String? type,
  }) async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    Query<Category> baseQuery = categoriesRef
        .where('userId', isEqualTo: uid)
        .withConverter<Category>(
          fromFirestore: (snap, _) => Category.fromMap(snap.id, snap.data()!),
          toFirestore: (cat, _) => cat.toMap(),
        );

    if (type != null && type.isNotEmpty && type != 'all') {
      baseQuery = baseQuery.where('type', isEqualTo: type);
    }

    baseQuery = baseQuery.orderBy('name');

    await for (var snapshot in baseQuery.snapshots(
      includeMetadataChanges: true,
    )) {
      // Update local cache dengan hasil snapshot
      _localCache
        ..clear()
        ..addAll(snapshot.docs.map((doc) => doc.data()));

      // Apply client-side filter untuk search
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        final filtered =
            _localCache
                .where((cat) => cat.name.toLowerCase().contains(q))
                .toList();
        yield filtered;
      } else {
        yield _localCache;
      }
    }
  }

  // ======================= Get Category By ID =======================
  Future<Category?> getCategoryById(String id) async {
    // Check cache first
    try {
      final cached = _localCache.firstWhere(
        (c) => c.id == id,
        // ignore: cast_from_null_always_fails
        orElse: () => null as Category,
      );
      // ignore: unnecessary_null_comparison
      if (cached != null) {
        return cached;
      }

      // Fetch from Firestore if not in cache
      final doc = await categoriesRef.doc(id).get();
      if (doc.exists && doc.data() != null) {
        final cat = Category.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
        _localCache.add(cat);
        return cat;
      }
    } catch (_) {}
    return null;
  }

  // ======================= Add / Update / Delete =======================
  Future<Category?> addCategory(Category category) async {
    try {
      final docRef = categoriesRef.doc();
      final newCategory = category.copyWith(id: docRef.id);
      _localCache.add(newCategory);
      await docRef.set(newCategory.toMap());
      return newCategory;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      final index = _localCache.indexWhere((c) => c.id == category.id);
      if (index != -1) _localCache[index] = category;

      await categoriesRef.doc(category.id).update(category.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      _localCache.removeWhere((c) => c.id == id);
      await categoriesRef.doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ======================= Offline Search =======================
  List<Category> searchLocal({String? query, String? type}) {
    return _localCache.where((cat) {
      if (type != null &&
          type.isNotEmpty &&
          type != 'all' &&
          cat.type != type) {
        return false;
      }
      if (query != null &&
          query.trim().isNotEmpty &&
          !cat.name.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }
}
