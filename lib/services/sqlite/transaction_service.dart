import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/transaction_model.dart';
import 'wallet_service.dart';
import 'db_helper.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final WalletService _walletService = WalletService();

  final StreamController<List<TransactionModel>> _transactionController =
      StreamController<List<TransactionModel>>.broadcast();

  final StreamController<Map<String, double>> _summaryController =
      StreamController<Map<String, double>>.broadcast();

  // ================= Stream =================
  Stream<List<TransactionModel>> getTransactionStream({String? userId}) {
    _loadTransactions(userId: userId);
    return _transactionController.stream;
  }

  Stream<Map<String, double>> getSummary({String? userId}) {
    _calculateSummary(userId: userId);
    return _summaryController.stream;
  }

  Future<void> _loadTransactions({String? userId}) async {
    final txs = await getTransactions(userId: userId);
    _transactionController.add(txs);
    _calculateSummary(userId: userId);
  }

  Future<void> _calculateSummary({String? userId}) async {
    final db = await DBHelper.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClauses.add('userId = ?');
      whereArgs.add(userId);
    }

    final whereString =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS income,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS expense
      FROM transactions
      $whereString
    ''', whereArgs);

    final row = result.first;
    final income = (row['income'] as num?)?.toDouble() ?? 0.0;
    final expense = (row['expense'] as num?)?.toDouble() ?? 0.0;

    _summaryController.add({
      'income': income,
      'expense': expense,
      'balance': income - expense,
    });
  }

  // ================= CRUD =================
  Future<List<TransactionModel>> getTransactions({String? userId}) async {
    final db = await DBHelper.database;
    final maps = await db.query(
      'transactions',
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'date DESC',
    );
    return maps.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<TransactionModel?> getTransactionById(String id) async {
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

  Future<TransactionModel> addTransaction(TransactionModel tx) async {
    final db = await DBHelper.database;
    await db.insert(
      'transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (tx.walletId != null) {
      if (tx.type == 'income') {
        await _walletService.increaseBalance(tx.walletId!, tx.amount.toInt());
      } else {
        await _walletService.decreaseBalance(tx.walletId!, tx.amount.toInt());
      }
    }

    await _loadTransactions(userId: tx.userId);
    return tx;
  }

  Future<bool> updateTransaction(String id, TransactionModel newTx) async {
    final db = await DBHelper.database;
    final oldTx = await getTransactionById(id);
    if (oldTx == null) return false;

    await db.update(
      'transactions',
      newTx.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    // revert saldo lama
    if (oldTx.walletId != null) {
      if (oldTx.type == 'income') {
        await _walletService.decreaseBalance(
          oldTx.walletId!,
          oldTx.amount.toInt(),
        );
      } else {
        await _walletService.increaseBalance(
          oldTx.walletId!,
          oldTx.amount.toInt(),
        );
      }
    }

    // apply saldo baru
    if (newTx.walletId != null) {
      if (newTx.type == 'income') {
        await _walletService.increaseBalance(
          newTx.walletId!,
          newTx.amount.toInt(),
        );
      } else {
        await _walletService.decreaseBalance(
          newTx.walletId!,
          newTx.amount.toInt(),
        );
      }
    }

    await _loadTransactions(userId: newTx.userId);
    return true;
  }

  Future<bool> deleteTransaction(TransactionModel tx) async {
    final db = await DBHelper.database;
    final count = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [tx.id],
    );

    if (count > 0 && tx.walletId != null) {
      if (tx.type == 'income') {
        await _walletService.decreaseBalance(tx.walletId!, tx.amount.toInt());
      } else {
        await _walletService.increaseBalance(tx.walletId!, tx.amount.toInt());
      }
      await _loadTransactions(userId: tx.userId);
      return true;
    }
    return false;
  }

  // ================= Aggregation =================
  Future<double> getTotalByMonth(String type, DateTime month) async {
    final db = await DBHelper.database;
    final from = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final to = DateTime(month.year, month.month + 1, 1).millisecondsSinceEpoch;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total FROM transactions
      WHERE type = ? AND date >= ? AND date < ?
    ''',
      [type, from, to],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<Map<String, double>> getTotalByCategories(
    List<String> categoryIds,
    DateTime month,
  ) async {
    final db = await DBHelper.database;
    final from = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final to = DateTime(month.year, month.month + 1, 1).millisecondsSinceEpoch;

    final result = await db.query(
      'transactions',
      columns: ['categoryId', 'SUM(amount) as total'],
      where:
          'type = ? AND categoryId IN (${List.filled(categoryIds.length, '?').join(',')}) AND date >= ? AND date < ?',
      whereArgs: ['expense', ...categoryIds, from, to],
      groupBy: 'categoryId',
    );

    Map<String, double> totals = {};
    for (var id in categoryIds) {
      final row = result.firstWhere(
        (r) => r['categoryId'] == id,
        orElse: () => {'total': 0.0},
      );
      totals[id] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }
    return totals;
  }

  // ================= Dispose =================
  void dispose() {
    _transactionController.close();
    _summaryController.close();
  }
}
