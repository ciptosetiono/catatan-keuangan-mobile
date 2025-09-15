// lib/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import 'wallet_service.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference transactionsRef = FirebaseFirestore.instance
      .collection('transactions');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final WalletService _walletService = WalletService();

  // Cache lokal
  List<TransactionModel> _localCache = [];

  Query<Map<String, dynamic>> _buildQuery({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? title,
    String? walletId,
    String? categoryId,
    String orderByField = 'date',
    bool descending = true,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', whereIn: ['income', 'expense']);

    // Date filters
    if (fromDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
      );
    }
    if (toDate != null) {
      query = query.where('date', isLessThan: Timestamp.fromDate(toDate));
    }

    // Filters
    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type as Object);
    }
    if (walletId != null && walletId.isNotEmpty) {
      query = query.where('walletId', isEqualTo: walletId as Object);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId as Object);
    }
    if (title != null && title.isNotEmpty) {
      query = query.where('title', isEqualTo: title as Object);
    }

    return query.orderBy(orderByField, descending: descending);
  }

  // ======================= Stream / Get Transactions =======================
  Stream<List<TransactionModel>> getTransactionsStream({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? title,
    String? walletId,
    String? categoryId,
  }) async* {
    final query = _buildQuery(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      title: title,
      walletId: walletId,
      categoryId: categoryId,
    );
    // Listen to snapshots
    await for (var snap in query.snapshots(includeMetadataChanges: true)) {
      _localCache =
          snap.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
      yield _localCache; // use yield, not return
    }
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
  }) async {
    // Build base query with filters
    var query = _buildQuery(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      title: title,
      walletId: walletId,
      categoryId: categoryId,
    );

    // Apply pagination if needed
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    // Limit the number of documents
    query = query.limit(limit);

    // Execute query
    final snapshot = await query.get();

    // Update local cache, avoid duplicates
    final fetched =
        snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();

    for (var tx in fetched) {
      if (!_localCache.any((e) => e.id == tx.id)) {
        _localCache.add(tx);
      }
    }

    return snapshot;
  }

  Future<Map<String, num>> getSummary({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
  }) async {
    // Build query
    final query = _buildQuery(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      title: title,
      walletId: walletId,
      categoryId: categoryId,
    );

    try {
      // Fetch from Firestore
      final snapshot = await query.get();

      // Update local cache
      final fetched =
          snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();

      for (var tx in fetched) {
        if (!_localCache.any((e) => e.id == tx.id)) {
          _localCache.add(tx);
        }
      }

      // Calculate summary
      num income = 0;
      num expense = 0;

      for (var trx in fetched) {
        if (trx.type == 'income') {
          income += trx.amount;
        } else if (trx.type == 'expense') {
          expense += trx.amount;
        }
      }

      return {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    } catch (_) {
      // Offline mode: use local cache
      final filtered = _localCache.where((trx) {
        if (type != null && trx.type != type) return false;
        if (walletId != null && trx.walletId != walletId) return false;
        if (categoryId != null && trx.categoryId != categoryId) return false;
        if (title != null && trx.title != title) return false;
        if (fromDate != null && trx.date.isBefore(fromDate)) return false;
        if (toDate != null && trx.date.isAfter(toDate)) return false;
        return true;
      });

      num income = 0;
      num expense = 0;

      for (var trx in filtered) {
        if (trx.type == 'income') {
          income += trx.amount;
        } else if (trx.type == 'expense') {
          expense += trx.amount;
        }
      }

      return {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    }
  }

  // ======================= Add / Update / Delete =======================

  Future<void> addTransaction(Map<String, dynamic> newTransaction) async {
    if (userId == null) return;

    final txMap = Map<String, dynamic>.from(newTransaction);
    txMap['userId'] = userId;

    // 🔥 Generate Firestore doc ref first
    final docRef = transactionsRef.doc();
    final tx = TransactionModel.fromMap(txMap).copyWith(id: docRef.id);

    // Add to local cache immediately
    _localCache.add(tx);

    // Update wallet balance locally
    final wallet = await _walletService.getWalletById(tx.walletId!);
    final newBalance =
        tx.type == 'income'
            ? wallet.currentBalance + tx.amount
            : wallet.currentBalance - tx.amount;
    await _walletService.updateWallet(
      wallet.copyWith(currentBalance: newBalance.toDouble()),
    );

    try {
      await docRef.set(tx.toMap());
      debugPrint("✅ Transaction added with ID: ${tx.id}");
    } catch (e) {
      debugPrint("⚠️ Failed to add transaction to Firestore: $e");
    }
  }

  Future<void> updateTransaction(
    String id,
    Map<String, dynamic> newData,
  ) async {
    debugPrint("🔥 Transaction update requested for $id: $newData");

    final index = _localCache.indexWhere((tx) => tx.id == id);

    if (index == -1) {
      debugPrint("⚠️ Transaction not in cache, updating Firestore directly...");
      try {
        await transactionsRef.doc(id).update(newData);
        debugPrint("✅ Transaction $id updated on Firestore (cache skipped)");
      } catch (e) {
        debugPrint("❌ Failed to update Firestore transaction $id: $e");
      }
      return;
    }

    // --- Cache hit: update both cache + Firestore ---
    final oldTx = _localCache[index];
    final updatedTx = oldTx.copyWith(
      amount: (newData['amount'] ?? oldTx.amount).toDouble(),
      type: newData['type'] ?? oldTx.type,
      walletId: newData['walletId'] ?? oldTx.walletId,
      categoryId: newData['categoryId'] ?? oldTx.categoryId,
      title: newData['title'] ?? oldTx.title,
      date: newData['date'] ?? oldTx.date,
    );

    _localCache[index] = updatedTx;

    // --- Wallet balance updates ---
    final oldWallet = await _walletService.getWalletById(oldTx.walletId!);
    final rollback = oldTx.type == 'income' ? -oldTx.amount : oldTx.amount;
    final apply =
        updatedTx.type == 'income' ? updatedTx.amount : -updatedTx.amount;

    if (oldTx.walletId != updatedTx.walletId) {
      await _walletService.updateWallet(
        oldWallet.copyWith(currentBalance: oldWallet.currentBalance + rollback),
      );
      final newWallet = await _walletService.getWalletById(updatedTx.walletId!);
      await _walletService.updateWallet(
        newWallet.copyWith(currentBalance: newWallet.currentBalance + apply),
      );
    } else {
      await _walletService.updateWallet(
        oldWallet.copyWith(
          currentBalance: oldWallet.currentBalance + rollback + apply,
        ),
      );
    }

    // --- Firestore update ---
    try {
      await transactionsRef.doc(id).update(updatedTx.toMap());
      debugPrint("✅ Transaction $id updated on Firestore and cache");
    } catch (e) {
      debugPrint("❌ Failed to update transaction $id on Firestore: $e");
    }
  }

  Future<void> deleteTransaction(String id) async {
    final index = _localCache.indexWhere((tx) => tx.id == id);

    if (index == -1) {
      debugPrint(
        "⚠️ Transaction $id not found in cache, deleting from Firestore directly...",
      );
      try {
        await transactionsRef.doc(id).delete();
        debugPrint("✅ Transaction $id deleted from Firestore (cache skipped)");
      } catch (e) {
        debugPrint("❌ Failed to delete transaction $id from Firestore: $e");
      }
      return;
    }

    // --- Cache hit: remove from cache and adjust wallet ---
    final tx = _localCache.removeAt(index);

    final wallet = await _walletService.getWalletById(tx.walletId!);
    final adjust = tx.type == 'income' ? -tx.amount : tx.amount;
    await _walletService.updateWallet(
      wallet.copyWith(currentBalance: wallet.currentBalance + adjust),
    );

    try {
      await transactionsRef.doc(id).delete();
      debugPrint("✅ Transaction $id deleted from Firestore and cache");
    } catch (e) {
      debugPrint("❌ Failed to delete transaction $id on Firestore: $e");
    }
  }

  Future<TransactionModel> getTransactionById(String id) async {
    // Search manually
    for (var tx in _localCache) {
      if (tx.id == id) return tx;
    }

    // Fetch from Firestore
    final doc = await transactionsRef.doc(id).get();
    if (doc.exists) {
      final fetchedTx = TransactionModel.fromFirestore(doc);
      _localCache.add(fetchedTx);
      return fetchedTx;
    }

    throw Exception('Transaction not found');
  }

  // ======================= Aggregation Examples =======================

  /// Total pengeluaran dalam satu bulan
  Future<double> getTotalSpentByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final query = _buildQuery(fromDate: from, toDate: to, type: 'expense');

    final snapshot = await query.get();
    final total = snapshot.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc['amount'] as num).toDouble(),
    );

    return total;
  }

  /// Total pemasukan dalam satu bulan
  Future<double> getTotalIncomeByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final query = _buildQuery(fromDate: from, toDate: to, type: 'income');

    final snapshot = await query.get();
    final total = snapshot.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc['amount'] as num).toDouble(),
    );

    return total;
  }

  /// Total pengeluaran per kategori dalam satu bulan
  Future<Map<String, double>> getTotalSpentByCategories({
    required List<String> categoryIds,
    required DateTime month,
  }) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    Map<String, double> totals = {};

    for (var categoryId in categoryIds) {
      final query = _buildQuery(
        fromDate: from,
        toDate: to,
        type: 'expense',
        categoryId: categoryId,
      );

      final snapshot = await query.get();
      final total = snapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['amount'] as num).toDouble(),
      );

      totals[categoryId] = total;
    }

    return totals;
  }

  /// Stream transaksi berdasarkan wallet
  Stream<List<TransactionModel>> getTransactionsByWallet(String walletId) {
    final query = _buildQuery(walletId: walletId); // ambil semua tipe transaksi

    return query.snapshots().map((snap) {
      _localCache =
          snap.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
      return _localCache;
    });
  }

  /// Stream transaksi transfer berdasarkan wallet dan tanggal
  Stream<List<TransactionModel>> getTransfers({
    String? fromWalletId,
    String? toWalletId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'transfer');

    if (fromWalletId != null && fromWalletId.isNotEmpty) {
      query = query.where('fromWalletId', isEqualTo: fromWalletId);
    }
    if (toWalletId != null && toWalletId.isNotEmpty) {
      query = query.where('toWalletId', isEqualTo: toWalletId);
    }
    if (fromDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
      );
    }
    if (toDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(toDate),
      );
    }

    return query.orderBy('date', descending: true).snapshots().map((snap) {
      _localCache =
          snap.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
      return _localCache;
    });
  }
}
