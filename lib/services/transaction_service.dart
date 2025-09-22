import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'wallet_service.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // ignore: unused_field
  final WalletService _walletService = WalletService();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  final CollectionReference<TransactionModel> _transactionsRef =
      FirebaseFirestore.instance
          .collection('transactions')
          .withConverter<TransactionModel>(
            fromFirestore: (snap, _) => TransactionModel.fromFirestore(snap),
            toFirestore: (tx, _) => tx.toMap(),
          );

  final _walletsRef = FirebaseFirestore.instance.collection('wallets');

  TransactionService() {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ======================= Core Query Builder =======================
  Query<TransactionModel> _buildQuery({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
    String orderByField = 'date',
    bool descending = true,
  }) {
    Query<TransactionModel> query = _transactionsRef.where(
      'userId',
      isEqualTo: userId,
    );

    if (fromDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
      );
    }
    if (toDate != null) {
      query = query.where('date', isLessThan: Timestamp.fromDate(toDate));
    }
    if (type != null) query = query.where('type', isEqualTo: type);
    if (walletId != null) query = query.where('walletId', isEqualTo: walletId);
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (title != null) query = query.where('title', isEqualTo: title);

    return query.orderBy(orderByField, descending: descending);
  }

  // ======================= Streams =======================
  Stream<List<TransactionModel>> getTransactionsStream({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
  }) {
    final query = _buildQuery(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      title: title,
    );

    return query
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<QuerySnapshot<TransactionModel>> getTransactionsPaginated({
    required int limit,
    DocumentSnapshot<TransactionModel>? startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? title,
    String? walletId,
    String? categoryId,
  }) async {
    Query<TransactionModel> query = _buildQuery(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      title: title,
      walletId: walletId,
      categoryId: categoryId,
    );

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    return await query.get();
  }

  Stream<List<TransactionModel>> getTransactionsByWallet(String walletId) {
    return _buildQuery(
      walletId: walletId,
    ).snapshots().map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  // ======================= CRUD Operations =======================
  Future<TransactionModel> addTransaction(Map<String, dynamic> data) async {
    if (userId == null) throw Exception("User not logged in");

    final docRef = _transactionsRef.doc();
    late TransactionModel txModel;

    await _db.runTransaction((tx) async {
      txModel = TransactionModel.fromMap(
        data,
      ).copyWith(id: docRef.id, userId: userId!);

      debugPrint('add txmodel : $txModel');

      // 🔹 Update wallet balance pakai tx.get (bukan service di luar transaction)
      if (txModel.walletId != null) {
        final walletDoc = await tx.get(_walletsRef.doc(txModel.walletId!));
        if (walletDoc.exists) {
          final wallet = Wallet.fromMap(walletDoc.id, walletDoc.data()!);
          final newBalance =
              txModel.type == 'income'
                  ? wallet.currentBalance + txModel.amount
                  : wallet.currentBalance - txModel.amount;

          tx.update(
            walletDoc.reference,
            wallet.copyWith(currentBalance: newBalance).toMap(),
          );
        }
      }

      // 🔹 Simpan transaksi
      tx.set(docRef, txModel);
    });

    return txModel;
  }

  Future<TransactionModel> updateTransaction(
    String id,
    Map<String, dynamic> newData,
  ) async {
    late TransactionModel updatedTx;

    await _db.runTransaction((tx) async {
      final trxRef = _transactionsRef.doc(id);
      final trxSnap = await tx.get(trxRef);
      if (!trxSnap.exists) throw Exception("Transaction not found");

      final oldTx = trxSnap.data()!;
      updatedTx = oldTx.copyWith(
        amount: (newData['amount'] ?? oldTx.amount).toDouble(),
        type: newData['type'] ?? oldTx.type,
        walletId: newData['walletId'] ?? oldTx.walletId,
        categoryId: newData['categoryId'] ?? oldTx.categoryId,
        title: newData['title'] ?? oldTx.title,
        date: newData['date'] ?? oldTx.date,
      );

      // same wallet → update once
      if (oldTx.walletId == updatedTx.walletId && oldTx.walletId != null) {
        final walletRef = _walletsRef.doc(oldTx.walletId!);
        final walletSnap = await tx.get(walletRef);
        if (walletSnap.exists) {
          final wallet = Wallet.fromMap(walletSnap.id, walletSnap.data()!);
          final oldChange =
              oldTx.type == 'income' ? oldTx.amount : -oldTx.amount;
          final newChange =
              updatedTx.type == 'income' ? updatedTx.amount : -updatedTx.amount;
          final delta = newChange - oldChange;
          tx.update(walletRef, {
            'currentBalance': wallet.currentBalance + delta,
          });
        }
      } else {
        // rollback old wallet
        if (oldTx.walletId != null) {
          final oldWalletRef = _walletsRef.doc(oldTx.walletId!);
          final oldWalletSnap = await tx.get(oldWalletRef);
          if (oldWalletSnap.exists) {
            final oldWallet = Wallet.fromMap(
              oldWalletSnap.id,
              oldWalletSnap.data()!,
            );
            final rollback =
                oldTx.type == 'income' ? -oldTx.amount : oldTx.amount;
            tx.update(oldWalletRef, {
              'currentBalance': oldWallet.currentBalance + rollback,
            });
          }
        }

        // apply to new wallet
        if (updatedTx.walletId != null) {
          final newWalletRef = _walletsRef.doc(updatedTx.walletId!);
          final newWalletSnap = await tx.get(newWalletRef);
          if (newWalletSnap.exists) {
            final newWallet = Wallet.fromMap(
              newWalletSnap.id,
              newWalletSnap.data()!,
            );
            final adjust =
                updatedTx.type == 'income'
                    ? updatedTx.amount
                    : -updatedTx.amount;
            tx.update(newWalletRef, {
              'currentBalance': newWallet.currentBalance + adjust,
            });
          }
        }
      }

      tx.update(trxRef, updatedTx.toMap());
    });

    return updatedTx;
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    await _db.runTransaction((tx) async {
      final docRef = _transactionsRef.doc(transaction.id);

      if (transaction.walletId != null) {
        final walletRef = _walletsRef.doc(transaction.walletId!);
        final walletSnap = await tx.get(walletRef);
        if (walletSnap.exists) {
          final wallet = Wallet.fromMap(walletSnap.id, walletSnap.data()!);
          final adjust =
              transaction.type == 'income'
                  ? -transaction.amount
                  : transaction.amount;
          tx.update(walletRef, {
            'currentBalance': wallet.currentBalance + adjust,
          });
        }
      }

      tx.delete(docRef);
    });
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final doc = await _transactionsRef
        .doc(id)
        .get(GetOptions(source: Source.cache));
    if (doc.exists) return doc.data();
    final serverDoc = await _transactionsRef
        .doc(id)
        .get(GetOptions(source: Source.server));
    if (serverDoc.exists) return serverDoc.data();
    return null;
  }

  // ======================= Aggregations =======================
  Future<double> getTotalSpentByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final query = _buildQuery(fromDate: from, toDate: to, type: 'expense');
    final snapshot = await query.get(GetOptions(source: Source.cache));
    return snapshot.docs.fold<double>(
      0.0,
      // ignore: avoid_types_as_parameter_names
      (sum, doc) => sum + (doc['amount'] as num).toDouble(),
    );
  }

  Future<double> getTotalIncomeByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final query = _buildQuery(fromDate: from, toDate: to, type: 'income');
    final snapshot = await query.get(GetOptions(source: Source.cache));
    return snapshot.docs.fold<double>(
      0.0,
      // ignore: avoid_types_as_parameter_names
      (sum, doc) => sum + (doc['amount'] as num).toDouble(),
    );
  }

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
      final snapshot = await query.get(GetOptions(source: Source.cache));
      totals[categoryId] = snapshot.docs.fold<double>(
        0.0,
        // ignore: avoid_types_as_parameter_names
        (sum, doc) => sum + (doc['amount'] as num).toDouble(),
      );
    }
    return totals;
  }

  Stream<Map<String, num>> getSummary({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
  }) async* {
    // ambil snapshot realtime dari query Firestore
    final query = _buildQuery(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      title: title,
    );

    await for (final snapshot in query.snapshots(
      includeMetadataChanges: true,
    )) {
      num income = 0;
      num expense = 0;

      for (var doc in snapshot.docs) {
        final trx = doc.data();
        // ignore: unnecessary_null_comparison
        if (trx == null) continue;

        if (trx.type == 'income') {
          income += trx.amount;
        } else if (trx.type == 'expense') {
          expense += trx.amount;
        }
      }

      yield {'income': income, 'expense': expense, 'balance': income - expense};
    }
  }
}
