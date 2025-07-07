import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';

class BudgetService {
  final _ref = FirebaseFirestore.instance.collection('budgets');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> addBudget(Budget budget) async {
    await _ref.add(budget.toMap());
  }

  Future<void> updateBudget(Budget budget) async {
    await _ref.doc(budget.id).update(budget.toMap());
  }

  Future<void> deleteBudget(String id) async {
    await _ref.doc(id).delete();
  }

  Future<Budget?> getBudget(String id) async {
    final doc = await _ref.doc(id).get();
    if (doc.exists) {
      return Budget.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<List<Budget>> getBudgets({DateTime? month, String? categoryId}) {
    Query query = _ref.where('userId', isEqualTo: userId);

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

    return query
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map(
                    (doc) => Budget.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        )
        .handleError((error) {
          return <Budget>[];
        });
  }

  Future<bool> checkDuplicateBudget(String categoryId, DateTime month) async {
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
