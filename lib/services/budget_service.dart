import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';

class BudgetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final CollectionReference _ref = FirebaseFirestore.instance.collection(
    'budgets',
  );

  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  BudgetService() {
    _db.settings = const Settings(
      persistenceEnabled: true, // Enable offline persistence
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ======================= Stream / Get Budgets =======================
  Stream<List<Budget>> getBudgets({DateTime? month, String? categoryId}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    Query<Budget> query = _ref
        .where('userId', isEqualTo: uid)
        .withConverter<Budget>(
          fromFirestore: (snap, _) => Budget.fromMap(snap.id, snap.data()!),
          toFirestore: (budget, _) => budget.toMap(),
        );

    if (month != null) {
      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1);
      query = query
          .where('month', isGreaterThanOrEqualTo: start)
          .where('month', isLessThan: end);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map(
      (snap) => snap.docs.map((doc) => doc.data()).toList(),
    );
  }

  // ======================= Get Budget By ID =======================
  Future<Budget?> getBudget(String id) async {
    try {
      // ✅ Firestore handle offline automatically
      final doc = await _ref
          .doc(id)
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        return Budget.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  // ======================= Add / Update / Delete =======================
  Future<Budget?> addBudget(Budget budget) async {
    try {
      final docRef = _ref.doc();
      final newBudget = budget.copyWith(id: docRef.id);
      await docRef.set(newBudget.toMap());
      return newBudget;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    try {
      await _ref.doc(budget.id).update(budget.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      await _ref.doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ======================= Duplicate Check =======================
  Future<bool> checkDuplicateBudget(String categoryId, DateTime month) async {
    if (userId == null) return false;

    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    final snapshot =
        await _ref
            .where('userId', isEqualTo: userId)
            .where('categoryId', isEqualTo: categoryId)
            .where('month', isGreaterThanOrEqualTo: start)
            .where('month', isLessThan: end)
            .get();

    return snapshot.docs.isNotEmpty;
  }
}
