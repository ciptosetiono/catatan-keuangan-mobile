import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getTransactions({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot =
        await _db
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .where('date', isGreaterThanOrEqualTo: from)
            .where('date', isLessThanOrEqualTo: to)
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
