// lib/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference transactionsRef = FirebaseFirestore.instance
      .collection('transactions');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  /// Tambah transaksi baru ke Firestore
  Future<void> addTransaction({
    required String walletId,
    required String title,
    required double amount,
    required String type, // 'income' atau 'expense'
    required String categoryId,
    required DateTime date,
  }) async {
    if (userId == null) return;
    await transactionsRef.add({
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ambil transaksi dengan filter tanggal optional
  Stream<List<TransactionModel>> getTransactionsStream({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? title,
    String? walletId,
    String? categoryId,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (fromDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
      );
    }

    if (toDate != null) {
      query = query.where('date', isLessThan: Timestamp.fromDate(toDate));
    }

    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }

    if (walletId != null && walletId.isNotEmpty) {
      query = query.where('walletId', isEqualTo: walletId);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (title != null && title.isNotEmpty) {
      query = query.where('title', isEqualTo: title);
    }

    return query.snapshots().map(
      (snap) =>
          snap.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList(),
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getTransactionsPaginated({
    required int limit,
    DocumentSnapshot? startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? title,
    String? walletId,
    String? categoryId,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (fromDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
      );
    }

    if (toDate != null) {
      query = query.where('date', isLessThan: Timestamp.fromDate(toDate));
    }

    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }

    if (walletId != null && walletId.isNotEmpty) {
      query = query.where('walletId', isEqualTo: walletId);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (title != null && title.isNotEmpty) {
      query = query.where('title', isEqualTo: title);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.limit(limit).get();
  }

  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final doc = await transactionsRef.doc(id).get();
      if (doc.exists) {
        return TransactionModel.fromFirestore(doc);
      } else {
        throw Exception('Transaction not found');
      }
    } catch (error) {
      throw Exception('Error fetching transaction: $error');
    }
  }

  Future<void> addTransactionFromMap(Map<String, dynamic> data) async {
    // misalnya tambahkan createdAt di sini kalau perlu
    data['createdAt'] = DateTime.now();
    await transactionsRef.add(data);
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await transactionsRef.doc(id).update(data);
  }

  /// Hapus transaksi berdasarkan document ID
  Future<void> deleteTransaction(String id) async {
    await transactionsRef.doc(id).delete();
  }

  Future<double> getTotalSpentByCategory(
    String categoryId,
    DateTime month,
  ) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final query =
        await transactionsRef
            .where('userId', isEqualTo: userId)
            .where('date', isGreaterThanOrEqualTo: from)
            .where('date', isLessThan: to)
            .where('type', isEqualTo: 'expense')
            .where('categoryId', isEqualTo: categoryId)
            .get();

    final total = query.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc['amount'] as num).toDouble(),
    );

    return total;
  }

  Future<double> getTotalSpentByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);
    print('Calculating total spent month $month');
    print('Calculating total spent from $from to $to');

    try {
      final query =
          await _db
              .collection('transactions')
              .where('userId', isEqualTo: userId)
              .where('date', isGreaterThanOrEqualTo: from)
              .where('date', isLessThan: to)
              .where('type', isEqualTo: 'expense')
              .get();

      print(
        query.docs.length > 0
            ? 'Found ${query.docs.length} transactions'
            : 'No transactions found for this month',
      );

      final total = query.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['amount'] as num).toDouble(),
      );

      return total;
    } catch (e, stack) {
      print('Error fetching transactions: $e');
      return 0.0;
    }
  }

  Future<Map<String, double>> getTotalSpentByCategories({
    required List<String> categoryIds,
    required DateTime month,
  }) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);

    // Batasi maksimal 10 kategori per batch (Firestore `whereIn` max 10 item)
    final batches = <List<String>>[];
    for (var i = 0; i < categoryIds.length; i += 10) {
      batches.add(
        categoryIds.sublist(
          i,
          (i + 10 > categoryIds.length) ? categoryIds.length : i + 10,
        ),
      );
    }

    final Map<String, double> totals = {};

    for (final batch in batches) {
      final snapshot =
          await transactionsRef
              .where('userId', isEqualTo: userId)
              .where('date', isGreaterThanOrEqualTo: from)
              .where('date', isLessThan: to)
              .where('type', isEqualTo: 'expense')
              .where('categoryId', whereIn: batch)
              .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data != null) {
          final map = data as Map<String, dynamic>;
          final categoryId = map['categoryId'];
          final amount = (map['amount'] ?? 0).toDouble();
          totals[categoryId] = (totals[categoryId] ?? 0) + amount;
        }
      }
    }

    return totals;
  }
}
