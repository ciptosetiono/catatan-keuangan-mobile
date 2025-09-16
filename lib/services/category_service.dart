// ignore_for_file: empty_catches

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryService {
  final CollectionReference categoriesRef = FirebaseFirestore.instance
      .collection('categories');

  // Cache lokal
  List<Category> _localCache = [];

  // ======================= Stream / Get Categories =======================
  Stream<List<Category>> getCategoryStream({
    String? query,
    String? type,
  }) async* {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    Query<Map<String, dynamic>> baseQuery =
        categoriesRef.where('userId', isEqualTo: uid)
            as Query<Map<String, dynamic>>;

    if (type != null && type.isNotEmpty && type != 'all') {
      baseQuery = baseQuery.where('type', isEqualTo: type);
    }

    baseQuery = baseQuery.orderBy('name');

    await for (var snapshot in baseQuery.snapshots(
      includeMetadataChanges: true,
    )) {
      var docs = snapshot.docs;

      // Update local cache
      _localCache =
          docs.map((doc) => Category.fromMap(doc.id, doc.data())).toList();

      // Filter by name (client-side)
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
    try {
      // Cari di cache dulu
      final cached =
          _localCache.where((c) => c.id == id).isNotEmpty
              ? _localCache.firstWhere((c) => c.id == id)
              : null;
      if (cached != null) return cached;

      // Jika tidak ada, fetch dari Firestore
      final doc = await categoriesRef.doc(id).get();
      if (doc.exists) {
        final cat = Category.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
        _localCache.add(cat);
        return cat;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ======================= Add / Update / Delete =======================
  Future<void> addCategory(Category category) async {
    final docRef = categoriesRef.doc();
    final newCategory = category.copyWith(id: docRef.id);

    // Update cache lokal dulu
    _localCache.add(newCategory);

    try {
      await docRef.set(newCategory.toMap());
    } catch (e) {}
  }

  Future<void> updateCategory(Category category) async {
    // Update cache lokal
    final index = _localCache.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _localCache[index] = category;
    }

    try {
      await categoriesRef.doc(category.id).update(category.toMap());
    } catch (e) {}
  }

  Future<void> deleteCategory(String id) async {
    // Hapus dari cache lokal
    _localCache.removeWhere((c) => c.id == id);

    try {
      await categoriesRef.doc(id).delete();
    } catch (e) {}
  }

  // ======================= Search Offline =======================
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
