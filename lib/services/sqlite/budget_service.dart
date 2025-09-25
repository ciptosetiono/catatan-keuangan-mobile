import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:money_note/models/budget_model.dart';
import 'db_helper.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final StreamController<List<Budget>> _budgetController =
      StreamController<List<Budget>>.broadcast();

  // ================= Stream =================
  Stream<List<Budget>> getBudgetStream({DateTime? month, String? categoryId}) {
    _loadBudgets(month: month, categoryId: categoryId);
    return _budgetController.stream;
  }

  Future<void> _loadBudgets({DateTime? month, String? categoryId}) async {
    final budgets = await getBudgets(month: month, categoryId: categoryId);
    _budgetController.add(budgets);
  }

  // ================= CRUD =================
  Future<List<Budget>> getBudgets({DateTime? month, String? categoryId}) async {
    final db = await DBHelper.database;

    String? where;
    List<Object?>? whereArgs = [];

    if (month != null) {
      final start = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
      final end =
          DateTime(month.year, month.month + 1, 1).millisecondsSinceEpoch;
      where = 'month >= ? AND month < ?';
      whereArgs.addAll([start, end]);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      if (where != null) {
        where += ' AND categoryId = ?';
      } else {
        where = 'categoryId = ?';
      }
      whereArgs.add(categoryId);
    }

    final maps = await db.query(
      'budgets',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'month ASC',
    );

    return maps.map((e) {
      final id = e['id'].toString();
      return Budget.fromMap(id, e);
    }).toList();
  }

  Future<Budget?> getBudget(String id) async {
    final db = await DBHelper.database;
    final maps = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first['id'].toString(), maps.first);
    }
    return null;
  }

  Future<Budget?> addBudget(Budget budget) async {
    final db = await DBHelper.database;
    final docId =
        budget.id.isNotEmpty
            ? budget.id
            : DateTime.now().millisecondsSinceEpoch.toString();
    final newBudget = budget.copyWith(id: docId);

    await db.insert(
      'budgets',
      newBudget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _loadBudgets();
    return newBudget;
  }

  Future<bool> updateBudget(Budget budget) async {
    final db = await DBHelper.database;
    final count = await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
    if (count > 0) await _loadBudgets();
    return count > 0;
  }

  Future<bool> deleteBudget(String id, {String? userId}) async {
    final db = await DBHelper.database;
    final count = await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
    if (count > 0) await _loadBudgets();
    return count > 0;
  }

  // ================= Duplicate Check =================
  Future<bool> checkDuplicateBudget(
    String categoryId,
    DateTime month, {
    String? userId,
  }) async {
    final db = await DBHelper.database;
    final start = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final end = DateTime(month.year, month.month + 1, 1).millisecondsSinceEpoch;

    final result = await db.query(
      'budgets',
      where:
          'categoryId = ? AND month >= ? AND month < ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs:
          userId != null
              ? [categoryId, start, end, userId]
              : [categoryId, start, end],
    );

    return result.isNotEmpty;
  }

  void dispose() {
    _budgetController.close();
  }
}
