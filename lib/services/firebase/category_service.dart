// ignore_for_file: empty_catches

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get categoriesRef => _db.collection('categories');

  CategoryService() {
    _db.settings = const Settings(
      persistenceEnabled: true, // Enable offline persistence
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ======================= Stream / Get Categories =======================
  Stream<List<Category>> getCategoryStream({String? query, String? type}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

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

    return baseQuery.snapshots(includeMetadataChanges: true).map((snapshot) {
      var list = snapshot.docs.map((doc) => doc.data()).toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        list = list.where((cat) => cat.name.toLowerCase().contains(q)).toList();
      }

      return list;
    });
  }

  // ======================= Get Category By ID =======================
  Future<Category?> getCategoryById(String id) async {
    try {
      // 1️⃣ Try get from cache
      final cachedDoc = await categoriesRef
          .doc(id)
          .get(const GetOptions(source: Source.cache));
      final data = cachedDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        return Category.fromMap(cachedDoc.id, data);
      }
    } catch (_) {
      // ignore errors
    }

    try {
      // 2️⃣ Fallback to server if cache not available
      final serverDoc = await categoriesRef
          .doc(id)
          .get(const GetOptions(source: Source.server));

      final data = serverDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        return Category.fromMap(serverDoc.id, data);
      }
    } catch (_) {}

    return null;
  }

  // ======================= Add / Update / Delete =======================
  Future<Category?> addCategory(Category category) async {
    try {
      final docRef = categoriesRef.doc();
      final newCategory = category.copyWith(id: docRef.id);
      await docRef.set(newCategory.toMap());
      return newCategory;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      await categoriesRef.doc(category.id).update(category.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await categoriesRef.doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ======================= Search / Filter Offline-First =======================
  Future<List<Category>> searchCategories({String? query, String? type}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    List<Category> list = [];

    // 1️⃣ Try cache first
    try {
      Query<Category> cacheQuery = categoriesRef
          .where('userId', isEqualTo: uid)
          .withConverter<Category>(
            fromFirestore: (snap, _) => Category.fromMap(snap.id, snap.data()!),
            toFirestore: (cat, _) => cat.toMap(),
          );

      if (type != null && type.isNotEmpty && type != 'all') {
        cacheQuery = cacheQuery.where('type', isEqualTo: type);
      }

      cacheQuery = cacheQuery.orderBy('name');

      final snapshot = await cacheQuery.get(
        const GetOptions(source: Source.cache),
      );
      list = snapshot.docs.map((doc) => doc.data()).toList();
    } catch (_) {}

    // 2️⃣ If empty, fallback to server
    if (list.isEmpty) {
      try {
        Query<Category> serverQuery = categoriesRef
            .where('userId', isEqualTo: uid)
            .withConverter<Category>(
              fromFirestore:
                  (snap, _) => Category.fromMap(snap.id, snap.data()!),
              toFirestore: (cat, _) => cat.toMap(),
            );

        if (type != null && type.isNotEmpty && type != 'all') {
          serverQuery = serverQuery.where('type', isEqualTo: type);
        }

        serverQuery = serverQuery.orderBy('name');

        final snapshot = await serverQuery.get(
          const GetOptions(source: Source.server),
        );
        list = snapshot.docs.map((doc) => doc.data()).toList();
      } catch (_) {}
    }

    // Apply client-side search
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((cat) => cat.name.toLowerCase().contains(q)).toList();
    }

    return list;
  }
}
