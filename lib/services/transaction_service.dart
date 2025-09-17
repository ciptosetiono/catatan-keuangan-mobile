// lib/services/transaction_service.dart
// ignore_for_file: avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
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
  Future<TransactionModel> addTransaction(
    Map<String, dynamic> newTransaction,
  ) async {
    if (userId == null) {
      throw Exception("User not logged in");
    }

    final txMap = Map<String, dynamic>.from(newTransaction);
    txMap['userId'] = userId;

    // 🔥 Generate Firestore doc ref first
    final docRef = transactionsRef.doc();
    late TransactionModel txModel;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        // --- 1. Buat model transaksi ---
        txModel = TransactionModel.fromMap(txMap).copyWith(id: docRef.id);

        // --- 2. Update wallet saldo ---
        if (txModel.walletId != null) {
          final walletRef = _walletService.walletsRef.doc(txModel.walletId!);
          final walletSnapshot = await tx.get(walletRef);

          final walletData = walletSnapshot.data();
          if (walletData == null || walletData is! Map<String, dynamic>) {
            throw Exception("Wallet ${txModel.walletId} data invalid");
          }

          final wallet = Wallet.fromMap(walletSnapshot.id, walletData);
          final newBalance =
              txModel.type == 'income'
                  ? wallet.currentBalance + txModel.amount
                  : wallet.currentBalance - txModel.amount;

          tx.update(walletRef, {'currentBalance': newBalance.toDouble()});
          debugPrint(
            "🔥 Wallet ${wallet.id} balance adjusted by ${txModel.amount}",
          );
        }

        // --- 3. Tambah transaksi ke Firestore ---
        tx.set(docRef, txModel.toMap());
        debugPrint("✅ Transaction will be added with ID: ${txModel.id}");
      });

      // --- 4. Update cache lokal setelah transaction berhasil ---
      _localCache.add(txModel);

      return txModel;
    } catch (e, st) {
      debugPrint("❌ Failed to add transaction atomically: $e");
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<TransactionModel> updateTransaction(
    String id,
    Map<String, dynamic> newData,
  ) async {
    try {
      late TransactionModel updatedTx;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        // Ambil snapshot transaksi lama
        final docRef = transactionsRef.doc(id);
        final snapshot = await tx.get(docRef);

        if (!snapshot.exists) throw Exception("Transaction $id not found");

        // Safe cast data
        final snapshotData = snapshot.data();
        if (snapshotData == null || snapshotData is! Map<String, dynamic>) {
          throw Exception("Transaction data invalid");
        }

        final oldTx = TransactionModel.fromMap(snapshotData).copyWith(id: id);

        // Buat updated transaction
        updatedTx = oldTx.copyWith(
          amount: (newData['amount'] ?? oldTx.amount).toDouble(),
          type: newData['type'] ?? oldTx.type,
          walletId: newData['walletId'] ?? oldTx.walletId,
          categoryId: newData['categoryId'] ?? oldTx.categoryId,
          title: newData['title'] ?? oldTx.title,
          date: newData['date'] ?? oldTx.date,
        );

        // --- Update wallet(s) ---
        if (oldTx.walletId != updatedTx.walletId) {
          // Wallet berganti
          if (oldTx.walletId != null) {
            final oldWalletRef = _walletService.walletsRef.doc(oldTx.walletId!);
            final oldWalletSnapshot = await tx.get(oldWalletRef);
            final oldWalletData = oldWalletSnapshot.data();
            if (oldWalletData == null ||
                oldWalletData is! Map<String, dynamic>) {
              throw Exception("Old wallet data invalid");
            }
            final oldWallet = Wallet.fromMap(
              oldWalletSnapshot.id,
              oldWalletData,
            );
            final rollback =
                oldTx.type == 'income' ? -oldTx.amount : oldTx.amount;
            tx.update(oldWalletRef, {
              'currentBalance': oldWallet.currentBalance + rollback,
            });
          }
          if (updatedTx.walletId != null) {
            final newWalletRef = _walletService.walletsRef.doc(
              updatedTx.walletId!,
            );
            final newWalletSnapshot = await tx.get(newWalletRef);
            final newWalletData = newWalletSnapshot.data();
            if (newWalletData == null ||
                newWalletData is! Map<String, dynamic>) {
              throw Exception("New wallet data invalid");
            }
            final newWallet = Wallet.fromMap(
              newWalletSnapshot.id,
              newWalletData,
            );
            final apply =
                updatedTx.type == 'income'
                    ? updatedTx.amount
                    : -updatedTx.amount;
            tx.update(newWalletRef, {
              'currentBalance': newWallet.currentBalance + apply,
            });
          }
        } else if (updatedTx.walletId != null) {
          // Wallet sama
          final walletRef = _walletService.walletsRef.doc(updatedTx.walletId!);
          final walletSnapshot = await tx.get(walletRef);
          final walletData = walletSnapshot.data();
          if (walletData == null || walletData is! Map<String, dynamic>) {
            throw Exception("Wallet data invalid");
          }
          final wallet = Wallet.fromMap(walletSnapshot.id, walletData);
          final rollback =
              oldTx.type == 'income' ? -oldTx.amount : oldTx.amount;
          final apply =
              updatedTx.type == 'income' ? updatedTx.amount : -updatedTx.amount;
          tx.update(walletRef, {
            'currentBalance': wallet.currentBalance + rollback + apply,
          });
        }

        // --- Update transaksi ---
        tx.update(docRef, updatedTx.toMap());
      });

      // --- Update cache jika perlu ---
      final index = _localCache.indexWhere((tx) => tx.id == id);
      if (index != -1) _localCache[index] = updatedTx;

      debugPrint("✅ Transaction $id updated atomically with wallet");
      return updatedTx;
    } catch (e, st) {
      debugPrint("❌ Failed to update transaction $id atomically: $e");
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<bool> deleteTransaction(TransactionModel transaction) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final docRef = transactionsRef.doc(transaction.id);

        // --- 1. Ambil transaksi dari Firestore ---
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) {
          throw Exception(
            "Transaction ${transaction.id} not found in Firestore",
          );
        }

        // --- 2. Update wallet saldo ---
        if (transaction.walletId != null) {
          final walletRef = _walletService.walletsRef.doc(
            transaction.walletId!,
          );
          final walletSnapshot = await tx.get(walletRef);

          final walletData = walletSnapshot.data();
          if (walletData == null || walletData is! Map<String, dynamic>) {
            throw Exception("Wallet ${transaction.walletId} data invalid");
          }

          final wallet = Wallet.fromMap(walletSnapshot.id, walletData);
          final adjust =
              transaction.type == 'income'
                  ? -transaction.amount
                  : transaction.amount;

          tx.update(walletRef, {
            'currentBalance': wallet.currentBalance + adjust,
          });
          debugPrint("🔥 Wallet ${wallet.id} balance adjusted by $adjust");
        }

        // --- 3. Hapus transaksi di Firestore ---
        tx.delete(docRef);
        debugPrint("✅ Transaction ${transaction.id} deleted from Firestore");
      });

      // --- 4. Hapus dari cache lokal ---
      final index = _localCache.indexWhere((t) => t.id == transaction.id);
      if (index != -1) _localCache.removeAt(index);

      return true;
    } catch (e, st) {
      debugPrint(
        "❌ Failed to delete transaction ${transaction.id} atomically: $e",
      );
      debugPrint(st.toString());
      return false;
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
    final query = _buildQuery(walletId: walletId);

    return query.snapshots().map((snap) {
      _localCache =
          snap.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
      return _localCache;
    });
  }
}
