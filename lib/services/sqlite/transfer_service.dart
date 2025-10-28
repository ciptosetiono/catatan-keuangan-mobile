import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/transaction_model.dart';
import 'wallet_service.dart';
import 'goal_service.dart';
import 'db_helper.dart';

class TransferService {
  static final TransferService _instance = TransferService._internal();
  factory TransferService() => _instance;
  TransferService._internal();

  final WalletService _walletService = WalletService();
  final StreamController<List<TransactionModel>> _transferController =
      StreamController<List<TransactionModel>>.broadcast();

  // ---------------- All Transfers Stream ----------------
  Stream<List<TransactionModel>> getTransferStream() {
    _loadTransfers();
    return _transferController.stream;
  }

  Future<void> _loadTransfers() async {
    final txs = await getTransfers().first; // ambil List pertama dari stream
    _transferController.add(txs);
  }

  // ---------------- CRUD ----------------
  Stream<List<TransactionModel>> getTransfers({
    String? fromWalletId,
    String? toWalletId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async* {
    final db = await DBHelper.database;

    // Stream.periodic sebagai contoh polling sederhana tiap 500ms
    await for (final _ in Stream.periodic(const Duration(milliseconds: 500))) {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      whereClauses.add('type = ?');
      whereArgs.add('transfer');

      if (fromWalletId != null) {
        whereClauses.add('fromWalletId = ?');
        whereArgs.add(fromWalletId);
      }
      if (toWalletId != null) {
        whereClauses.add('toWalletId = ?');
        whereArgs.add(toWalletId);
      }
      if (fromDate != null) {
        whereClauses.add('date >= ?');
        whereArgs.add(fromDate.millisecondsSinceEpoch);
      }
      if (toDate != null) {
        whereClauses.add('date <= ?');
        whereArgs.add(toDate.millisecondsSinceEpoch);
      }

      final whereString =
          whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

      final result = await db.query(
        'transactions',
        where: whereString,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'date DESC',
      );

      yield result.map((e) => TransactionModel.fromMap(e)).toList();
    }
  }

  Future<TransactionModel?> getTransferById(String id) async {
    final db = await DBHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return TransactionModel.fromMap(maps.first);
    return null;
  }

  Future<TransactionModel> addTransfer(Map<String, dynamic> txData) async {
    final tx = TransactionModel.fromMap(txData);

    if (tx.fromWalletId == null || tx.toWalletId == null) {
      throw Exception('Wallet ID cannot be null');
    }
    if (tx.fromWalletId == tx.toWalletId) {
      throw Exception('From and To Wallet cannot be same');
    }

    final db = await DBHelper.database;
    await db.insert(
      'transactions',
      txData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _walletService.decreaseBalance(tx.fromWalletId!, tx.amount.toInt());
    await _walletService.increaseBalance(tx.toWalletId!, tx.amount.toInt());

    await GoalService().handleTransactionAdded(tx);

    await _loadTransfers();
    return tx;
  }

  Future<bool> updateTransfer(String id, Map<String, dynamic> newData) async {
    final db = await DBHelper.database;
    final oldTx = await getTransferById(id);

    if (oldTx == null) return false;

    // ---------------- Rollback old balances ----------------
    await _walletService.increaseBalance(
      oldTx.fromWalletId!,
      oldTx.amount.toInt(),
    );
    await _walletService.decreaseBalance(
      oldTx.toWalletId!,
      oldTx.amount.toInt(),
    );

    //Rollback old goal progress
    if (oldTx.isGoalTransfer && oldTx.goalId != null) {
      await GoalService().handleTransactionDeleted(oldTx);
    }

    await db.update('transactions', newData, where: 'id = ?', whereArgs: [id]);

    final newDate =
        newData['date'] is String
            ? DateTime.tryParse(newData['date']) ?? oldTx.date
            : newData['date'] ?? oldTx.date;

    final newTx = oldTx.copyWith(
      amount: (newData['amount'] ?? oldTx.amount).toDouble(),
      type: newData['type'] ?? oldTx.type,
      walletId: newData['walletId'] ?? oldTx.walletId,
      categoryId: newData['categoryId'] ?? oldTx.categoryId,
      date: newDate,
      title: newData['title'] ?? oldTx.title,
      fromWalletId: newData['fromWalletId'] ?? oldTx.fromWalletId,
      toWalletId: newData['toWalletId'] ?? oldTx.toWalletId,
    );

    // ---------------- Apply new balances ----------------
    await _walletService.decreaseBalance(
      newTx.fromWalletId!,
      newTx.amount.toInt(),
    );
    await _walletService.increaseBalance(
      newTx.toWalletId!,
      newTx.amount.toInt(),
    );

    // ---------------- Apply new goal progress ----------------
    if (newTx.isGoalTransfer && newTx.goalId != null) {
      await GoalService().handleTransactionAdded(newTx);
    }

    await _loadTransfers();
    return true;
  }

  Future<bool> deleteTransfer(String id) async {
    final db = await DBHelper.database;

    // Ambil transfer dulu berdasarkan id
    final tx = await getTransferById(id);
    if (tx == null) return false; // jika tidak ditemukan

    // Hapus dari database
    final count = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count > 0) {
      // rollback saldo wallet
      await _walletService.increaseBalance(tx.fromWalletId!, tx.amount.toInt());
      await _walletService.decreaseBalance(tx.toWalletId!, tx.amount.toInt());
      await GoalService().handleTransactionDeleted(tx);
      await _loadTransfers();
      return true;
    }

    return false;
  }

  // ---------------- Wallet-specific Stream ----------------
  Stream<List<TransactionModel>> getTransfersByWallet(String walletId) {
    // pastikan controller ada data
    _loadTransfers();
    return _transferController.stream.map(
      (list) =>
          list
              .where(
                (tx) =>
                    tx.fromWalletId == walletId || tx.toWalletId == walletId,
              )
              .toList(),
    );
  }

  void dispose() {
    _transferController.close();
  }
}
