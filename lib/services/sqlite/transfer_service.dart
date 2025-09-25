import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/transaction_model.dart';
import 'wallet_service.dart';
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
        'transfers',
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
      'transfers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return TransactionModel.fromMap(maps.first);
    return null;
  }

  Future<TransactionModel> addTransfer(TransactionModel tx) async {
    if (tx.fromWalletId == null || tx.toWalletId == null) {
      throw Exception('Wallet ID cannot be null');
    }
    if (tx.fromWalletId == tx.toWalletId) {
      throw Exception('From and To Wallet cannot be same');
    }

    final db = await DBHelper.database;
    await db.insert(
      'transfers',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _walletService.decreaseBalance(tx.fromWalletId!, tx.amount.toInt());
    await _walletService.increaseBalance(tx.toWalletId!, tx.amount.toInt());

    await _loadTransfers();
    return tx;
  }

  Future<bool> updateTransfer(String id, TransactionModel newTx) async {
    final db = await DBHelper.database;
    final oldTx = await getTransferById(id);
    if (oldTx == null) return false;

    await db.update(
      'transfers',
      newTx.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await _walletService.increaseBalance(
      oldTx.fromWalletId!,
      oldTx.amount.toInt(),
    );
    await _walletService.decreaseBalance(
      oldTx.toWalletId!,
      oldTx.amount.toInt(),
    );

    await _walletService.decreaseBalance(
      newTx.fromWalletId!,
      newTx.amount.toInt(),
    );
    await _walletService.increaseBalance(
      newTx.toWalletId!,
      newTx.amount.toInt(),
    );

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
      'transfers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count > 0) {
      // rollback saldo wallet
      await _walletService.increaseBalance(tx.fromWalletId!, tx.amount.toInt());
      await _walletService.decreaseBalance(tx.toWalletId!, tx.amount.toInt());

      await _loadTransfers();
      return true;
    }

    return false;
  }

  // ---------------- Wallet-specific Stream ----------------
  Stream<List<TransactionModel>> getTransfersByWallet(String walletId) async* {
    final db = await DBHelper.database;
    final maps = await db.query(
      'transfers',
      where: 'fromWalletId = ? OR toWalletId = ?',
      whereArgs: [walletId, walletId],
      orderBy: 'date DESC',
    );
    final transfers = maps.map((e) => TransactionModel.fromMap(e)).toList();
    yield transfers;
  }

  void dispose() {
    _transferController.close();
  }
}
