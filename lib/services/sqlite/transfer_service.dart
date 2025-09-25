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

  // ================= Stream =================
  Stream<List<TransactionModel>> getTransferStream({String? userId}) {
    _loadTransfers(userId: userId);
    return _transferController.stream;
  }

  Future<void> _loadTransfers({String? userId}) async {
    final txs = await getTransfers(userId: userId);
    _transferController.add(txs);
  }

  // ================= CRUD =================
  Future<List<TransactionModel>> getTransfers({String? userId}) async {
    final db = await DBHelper.database;
    final maps = await db.query(
      'transfers',
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'date DESC',
    );
    return maps.map((e) => TransactionModel.fromMap(e)).toList();
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
      throw Exception('Wallet ID can not be null');
    }
    if (tx.fromWalletId == tx.toWalletId) {
      throw Exception('From Wallet and To Wallet can not be same');
    }

    final db = await DBHelper.database;
    await db.insert(
      'transfers',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // update wallets
    await _walletService.decreaseBalance(tx.fromWalletId!, tx.amount.toInt());
    await _walletService.increaseBalance(tx.toWalletId!, tx.amount.toInt());

    await _loadTransfers(userId: tx.userId);
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

    // rollback old wallet balances
    await _walletService.increaseBalance(
      oldTx.fromWalletId!,
      oldTx.amount.toInt(),
    );
    await _walletService.decreaseBalance(
      oldTx.toWalletId!,
      oldTx.amount.toInt(),
    );

    // apply new wallet balances
    await _walletService.decreaseBalance(
      newTx.fromWalletId!,
      newTx.amount.toInt(),
    );
    await _walletService.increaseBalance(
      newTx.toWalletId!,
      newTx.amount.toInt(),
    );

    await _loadTransfers(userId: newTx.userId);
    return true;
  }

  Future<bool> deleteTransfer(TransactionModel tx) async {
    final db = await DBHelper.database;
    final count = await db.delete(
      'transfers',
      where: 'id = ?',
      whereArgs: [tx.id],
    );
    if (count > 0) {
      // revert wallet balances
      await _walletService.increaseBalance(tx.fromWalletId!, tx.amount.toInt());
      await _walletService.decreaseBalance(tx.toWalletId!, tx.amount.toInt());

      await _loadTransfers(userId: tx.userId);
      return true;
    }
    return false;
  }

  // ================= Dispose =================
  void dispose() {
    _transferController.close();
  }
}
