import 'dart:async';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/sqlite/db_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'wallet_service.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final WalletService _walletService = WalletService();

  final StreamController<List<TransactionModel>> _txController =
      StreamController<List<TransactionModel>>.broadcast();

  // ================= Stream =================
  Stream<List<TransactionModel>> getTransactionsStream({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
  }) {
    _loadTransactions(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      title: title,
    );
    return _txController.stream;
  }

  Future<void> _loadTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
  }) async {
    final txs = await getTransactions(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      title: title,
    );
    _txController.add(txs);
  }

  // ================= CRUD =================
  Future<List<TransactionModel>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
    int? limit,
    int? offset,
  }) async {
    final db = await DBHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (type == null) {
      whereClauses.add('type IN (?, ?)');
      whereArgs.addAll(['income', 'expense']);
    } else {
      whereClauses.add('type = ?');
      whereArgs.add(type);
    }

    if (fromDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      whereClauses.add('date < ?');
      whereArgs.add(toDate.toIso8601String());
    }

    if (walletId != null) {
      whereClauses.add('walletId = ?');
      whereArgs.add(walletId);
    }
    if (categoryId != null) {
      whereClauses.add('categoryId = ?');
      whereArgs.add(categoryId);
    }
    if (title != null) {
      whereClauses.add('title = ?');
      whereArgs.add(title);
    }

    final maps = await db.query(
      'transactions',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<TransactionModel> addTransaction(Map<String, dynamic> txData) async {
    final db = await DBHelper.database;

    // Insert ke database
    await db.insert(
      'transactions',
      txData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Buat object TransactionModel dari map
    final tx = TransactionModel.fromMap(txData);

    // Update saldo wallet jika ada
    if (tx.walletId != null) {
      if (tx.type == 'income') {
        await _walletService.increaseBalance(tx.walletId!, tx.amount.toInt());
      } else if (tx.type == 'expense') {
        await _walletService.decreaseBalance(tx.walletId!, tx.amount.toInt());
      }
    }

    // Refresh stream / list transaksi
    _loadTransactions();

    return tx;
  }

  Future<TransactionModel?> updateTransaction(
    String id,
    Map<String, dynamic> newData,
  ) async {
    final db = await DBHelper.database;

    // Ambil transaksi lama
    final oldTxList = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (oldTxList.isEmpty) return null;

    final oldTx = TransactionModel.fromMap(oldTxList.first);

    // Rollback saldo wallet lama
    if (oldTx.walletId != null) {
      if (oldTx.type == 'income') {
        await _walletService.decreaseBalance(
          oldTx.walletId!,
          oldTx.amount.toInt(),
        );
      } else if (oldTx.type == 'expense') {
        await _walletService.increaseBalance(
          oldTx.walletId!,
          oldTx.amount.toInt(),
        );
      }
    }

    // Buat TransactionModel baru dari Map, gabungkan id & wallet lama jika perlu
    final newTx = oldTx.copyWith(
      amount: (newData['amount'] ?? oldTx.amount).toDouble(),
      type: newData['type'] ?? oldTx.type,
      walletId: newData['walletId'] ?? oldTx.walletId,
      categoryId: newData['categoryId'] ?? oldTx.categoryId,
      date: newData['date'] ?? oldTx.date,
      title: newData['title'] ?? oldTx.title,
    );

    // Update saldo wallet baru
    if (newTx.walletId != null) {
      if (newTx.type == 'income') {
        await _walletService.increaseBalance(
          newTx.walletId!,
          newTx.amount.toInt(),
        );
      } else if (newTx.type == 'expense') {
        await _walletService.decreaseBalance(
          newTx.walletId!,
          newTx.amount.toInt(),
        );
      }
    }

    // Update transaksi di database
    await db.update(
      'transactions',
      newTx.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    // Refresh stream/list
    _loadTransactions();

    return newTx;
  }

  Future<bool> deleteTransaction(TransactionModel tx) async {
    final db = await DBHelper.database;

    final count = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [tx.id],
    );
    if (count > 0) {
      if (tx.walletId != null) {
        if (tx.type == 'income') {
          await _walletService.decreaseBalance(tx.walletId!, tx.amount.toInt());
        } else if (tx.type == 'expense') {
          await _walletService.increaseBalance(tx.walletId!, tx.amount.toInt());
        }
      }
      _loadTransactions();
      return true;
    }
    return false;
  }

  // ================= Summary =================
  Future<Map<String, num>> getSummary({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
  }) async {
    final txs = await getTransactions(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      title: title,
    );

    num income = 0;
    num expense = 0;

    for (var tx in txs) {
      if (tx.type == 'income') income += tx.amount;
      if (tx.type == 'expense') expense += tx.amount;
    }

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  // ================= Total per Category =================
  Future<Map<String, double>> getTotalSpentByCategories({
    required List<String> categoryIds,
    required DateTime month,
  }) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final txs = await getTransactions(
      fromDate: from,
      toDate: to,
      type: 'expense',
    );

    Map<String, double> totals = {};

    for (var id in categoryIds) {
      totals[id] = 0;
    }

    for (var tx in txs) {
      if (tx.categoryId != null && totals.containsKey(tx.categoryId)) {
        totals[tx.categoryId!] = (totals[tx.categoryId!] ?? 0) + tx.amount;
      }
    }

    return totals;
  }

  // ================= Pagination =================
  Future<List<TransactionModel>> getTransactionsPaginated({
    required int limit,
    int offset = 0,
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
  }) async {
    return getTransactions(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      title: title,
      limit: limit,
      offset: offset,
    );
  }

  // ======================= Aggregations =======================
  Future<double> getTotalIncomeByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final db = await DBHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date < ?',
      ['income', from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalSpentByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final db = await DBHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date < ?',
      ['expense', from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  void dispose() {
    _txController.close();
  }
}
