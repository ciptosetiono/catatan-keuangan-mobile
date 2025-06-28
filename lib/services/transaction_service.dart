// lib/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
    await _db.collection('transactions').add({
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
  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? title,
    String? walletId,
    String? categoryId,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('transactions')
        .where('userId', isEqualTo: userId);

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
      print('Filtering by account: $walletId');
      query = query.where('walletId', isEqualTo: walletId);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (title != null && title.isNotEmpty) {
      query = query.where('title', isEqualTo: title);
    }

    return query.orderBy('date', descending: true).snapshots();
  }

  Future<void> addTransactionFromMap(Map<String, dynamic> data) async {
    // misalnya tambahkan createdAt di sini kalau perlu
    data['createdAt'] = DateTime.now();
    await FirebaseFirestore.instance.collection('transactions').add(data);
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(id)
        .update(data);
  }

  /// Hapus transaksi berdasarkan document ID
  Future<void> deleteTransaction(String id) async {
    await _db.collection('transactions').doc(id).delete();
  }
}
