// lib/services/transaction_service.dart
// ignore_for_file: avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/transaction_model.dart';
import 'wallet_service.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference transactionsRef = FirebaseFirestore.instance
      .collection('transactions');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final WalletService _walletService = WalletService();

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
        .orderBy('date', descending: true)
        .where('type', whereIn: ['income', 'expense']);

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
        .orderBy('date', descending: true)
        .where('type', whereIn: ['income', 'expense']);
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

  Stream<List<TransactionModel>> getTransactionsByWallet(String walletId) {
    return transactionsRef
        .where('walletId', isEqualTo: walletId)
        .where('userId', isEqualTo: userId)
        .where('type', whereIn: ['income', 'expense'])
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TransactionModel.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Tambah transaksi baru ke Firestore
  Future<void> addTransaction(Map<String, dynamic> newTransaction) async {
    if (userId == null) return;
    await transactionsRef.add({...newTransaction, userId: userId});

    final wallet = await _walletService.getWalletById(
      newTransaction['walletId'],
    );
    final newBalance =
        newTransaction['type'] == 'income'
            ? wallet.currentBalance + newTransaction['amount']
            : wallet.currentBalance - newTransaction['amount'];

    await _walletService.updateWallet(
      wallet.copyWith(currentBalance: newBalance.toDouble()),
    );
  }

  Future<void> updateTransaction(
    String id,
    Map<String, dynamic> newData,
  ) async {
    final doc = await transactionsRef.doc(id).get();

    if (!doc.exists) return;
    final oldTransaction = TransactionModel.fromFirestore(doc);

    final oldWallet = await _walletService.getWalletById(
      oldTransaction.walletId!,
    );

    final oldAmount = oldTransaction.amount;
    final oldType = oldTransaction.type;
    final oldWalletId = oldTransaction.walletId;

    final newAmount = (newData['amount'] ?? oldAmount).toDouble();
    final newType = newData['type'] ?? oldType;
    final newWalletId = newData['walletId'] ?? oldWalletId;

    // 1. Kembalikan saldo dari transaksi lama
    double rollbackAmount = oldType == 'income' ? -oldAmount : oldAmount;

    // 2. Tambahkan saldo baru berdasarkan transaksi baru
    double applyAmount = newType == 'income' ? newAmount : -newAmount;

    // 3. Jika ganti wallet, update keduanya
    if (oldWalletId != newWalletId) {
      // Kembalikan saldo lama
      final oldWalletNewBalance = oldWallet.currentBalance + rollbackAmount;
      await _walletService.updateWallet(
        oldWallet.copyWith(currentBalance: oldWalletNewBalance),
      );

      // Tambahkan saldo baru ke wallet baru
      final newWallet = await _walletService.getWalletById(newWalletId);
      final newWalletNewBalance = newWallet.currentBalance + applyAmount;
      await _walletService.updateWallet(
        newWallet.copyWith(currentBalance: newWalletNewBalance),
      );
    } else {
      final updatedBalance =
          oldWallet.currentBalance + rollbackAmount + applyAmount;
      await _walletService.updateWallet(
        oldWallet.copyWith(currentBalance: updatedBalance),
      );
    }

    // 4. Update dokumen transaksi
    await transactionsRef.doc(id).update(newData);
  }

  /// Hapus transaksi berdasarkan document ID
  Future<void> deleteTransaction(String id) async {
    final doc = await transactionsRef.doc(id).get();

    if (!doc.exists) return;
    TransactionModel transaction = TransactionModel.fromFirestore(doc);

    final String walletId = transaction.walletId!;
    final amount = transaction.amount.toDouble();
    final type = transaction.type;

    // Hapus transaksi
    await transactionsRef.doc(id).delete();

    // Update saldo wallet
    final wallet = await _walletService.getWalletById(walletId);
    final updatedBalance =
        type == 'income'
            ? wallet.currentBalance - amount
            : wallet.currentBalance + amount;

    await _walletService.updateWallet(
      wallet.copyWith(currentBalance: updatedBalance),
    );
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
    try {
      final query =
          await _db
              .collection('transactions')
              .where('userId', isEqualTo: userId)
              .where('date', isGreaterThanOrEqualTo: from)
              .where('date', isLessThan: to)
              .where('type', isEqualTo: 'expense')
              .get();

      final total = query.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['amount'] as num).toDouble(),
      );

      return total;
      // ignore: unused_catch_stack
    } catch (e, stack) {
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

  Future<double> getTotalIncomeByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final snapshot =
        await transactionsRef
            .where('userId', isEqualTo: userId)
            .where('type', isEqualTo: 'income')
            .where('date', isGreaterThanOrEqualTo: from)
            .where('date', isLessThan: to)
            .get();

    final total = snapshot.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc['amount'] as num).toDouble(),
    );

    return total;
  }

  // Stream khusus untuk data transfer
  Stream<List<TransactionModel>> getTransfers({
    String? fromWalletId,
    String? toWalletId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    // Siapkan range tanggal jika ada
    final Timestamp? startTimestamp =
        fromDate != null ? Timestamp.fromDate(fromDate) : null;
    final Timestamp? endTimestamp =
        toDate != null ? Timestamp.fromDate(toDate) : null;

    // Query untuk fromWalletId
    Query fromQuery = transactionsRef
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'transfer');

    if (fromWalletId != null) {
      fromQuery = fromQuery.where('fromWalletId', isEqualTo: fromWalletId);
    }

    if (startTimestamp != null && endTimestamp != null) {
      fromQuery = fromQuery
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp);
    }

    // Query untuk toWalletId
    Query toQuery = transactionsRef
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'transfer');

    if (toWalletId != null) {
      toQuery = toQuery.where('toWalletId', isEqualTo: toWalletId);
    }

    if (startTimestamp != null && endTimestamp != null) {
      toQuery = toQuery
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp);
    }

    return Rx.combineLatest2(fromQuery.snapshots(), toQuery.snapshots(), (
      QuerySnapshot fromSnap,
      QuerySnapshot toSnap,
    ) {
      final allDocsMap = <String, DocumentSnapshot>{};

      for (final doc in fromSnap.docs) {
        allDocsMap[doc.id] = doc;
      }
      for (final doc in toSnap.docs) {
        allDocsMap[doc.id] =
            doc; // Akan overwrite duplikat dengan doc.id yang sama
      }

      final allDocs = allDocsMap.values.toList();
      allDocs.sort((a, b) {
        final dateA = (a['date'] as Timestamp).toDate();
        final dateB = (b['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA); // descending
      });
      return allDocs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    });
  }
}
