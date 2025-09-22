import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';

class BudgetService {
  final CollectionReference _ref = FirebaseFirestore.instance.collection(
    'budgets',
  );

  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Cache lokal
  final List<Budget> _localCache = [];

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
      // Check local cache first
      final cached = _localCache.firstWhere(
        (b) => b.id == id,
        // ignore: cast_from_null_always_fails
        orElse: () => null as Budget,
      );
      // ignore: unnecessary_null_comparison
      if (cached != null) return cached;

      final doc = await _ref.doc(id).get();
      if (doc.exists && doc.data() != null) {
        final budget = Budget.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
        _localCache.add(budget);
        return budget;
      }
    } catch (_) {}
    return null;
  }

  // ======================= Add / Update / Delete =======================
  Future<Budget?> addBudget(Budget budget) async {
    try {
      final docRef = _ref.doc();
      final newBudget = budget.copyWith(id: docRef.id);
      _localCache.add(newBudget);
      await docRef.set(newBudget.toMap());
      return newBudget;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    try {
      final index = _localCache.indexWhere((b) => b.id == budget.id);
      if (index != -1) _localCache[index] = budget;
      await _ref.doc(budget.id).update(budget.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      _localCache.removeWhere((b) => b.id == id);
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

  // ======================= Offline Search =======================
  List<Budget> searchLocal({String? categoryId, DateTime? month}) {
    return _localCache.where((b) {
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          b.categoryId != categoryId) {
        return false;
      }
      if (month != null) {
        final start = DateTime(month.year, month.month);
        final end = DateTime(month.year, month.month + 1);
        if (b.month.isBefore(start) || b.month.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }
}
