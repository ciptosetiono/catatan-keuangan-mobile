// lib/services/planner_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlannerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  /// Tambahkan planner baru ke Firestore
  Future<void> addPlanner({
    required String title,
    required double amount,
    required DateTime targetDate,
    String? note,
    String category = 'Lainnya',
  }) async {
    if (userId == null) return;
    await _db.collection('planners').add({
      'userId': userId,
      'title': title,
      'amount': amount,
      'targetDate': Timestamp.fromDate(targetDate),
      'note': note ?? '',
      'category': category,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ambil semua planner milik user, terurut berdasarkan targetDate
  Stream<QuerySnapshot<Map<String, dynamic>>> getPlanners() {
    return _db
        .collection('planners')
        .where('userId', isEqualTo: userId)
        .orderBy('targetDate')
        .snapshots();
  }

  /// Toggle status selesai/belum pada planner tertentu
  Future<void> togglePlannerStatus(String id, bool isDone) async {
    await _db.collection('planners').doc(id).update({'isDone': isDone});
  }

  /// Hapus planner berdasarkan document ID
  Future<void> deletePlanner(String id) async {
    await _db.collection('planners').doc(id).delete();
  }
}
