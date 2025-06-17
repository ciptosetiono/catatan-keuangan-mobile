import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  /// Save a document to a collection with auto ID
  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    if (userId == null) return;
    await _db.collection(collection).add({
      ...data,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get documents from a collection by current user
  Stream<QuerySnapshot<Map<String, dynamic>>> getDocuments(String collection) {
    return _db
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Update a document
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  /// Delete a document
  Future<void> deleteDocument(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }

  Future<List<String>> getCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
  }

  Future<void> addCategory(String name) async {
    await FirebaseFirestore.instance.collection('categories').add({
      'name': name,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String docId) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(docId)
        .delete();
  }
}
