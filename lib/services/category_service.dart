import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryService {
  final CollectionReference categoriesRef = FirebaseFirestore.instance
      .collection('categories');

  Stream<List<Category>> getCategoryStream({String? query, String? type}) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    Query<Map<String, dynamic>> baseQuery =
        categoriesRef.where('userId', isEqualTo: uid)
            as Query<Map<String, dynamic>>;

    if (type != null && type.isNotEmpty && type != 'all') {
      baseQuery = baseQuery.where('type', isEqualTo: type);
    }

    baseQuery = baseQuery.orderBy('name');

    return baseQuery.snapshots().handleError((e) {}).map((snapshot) {
      var docs = snapshot.docs;

      // Filter by name (client-side)
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        docs =
            docs.where((doc) {
              final name = (doc['name'] as String?)?.toLowerCase() ?? '';
              return name.contains(q);
            }).toList();
      }

      return docs.map((doc) {
        return Category.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<Category> getCategoryById(String id) async {
    try {
      final doc = await categoriesRef.doc(id).get();
      if (doc.exists) {
        return Category.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('Wallet not found');
      }
    } catch (error) {
      throw Exception('Error fetching wallet: $error');
    }
  }

  /// Menambahkan kategori baru
  Future<void> addCategory(Category category) async {
    try {
      await categoriesRef.add(category.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Mengupdate kategori berdasarkan ID
  Future<void> updateCategory(Category category) async {
    try {
      await categoriesRef.doc(category.id).update(category.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Menghapus kategori berdasarkan ID
  Future<void> deleteCategory(String id) async {
    try {
      await categoriesRef.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
