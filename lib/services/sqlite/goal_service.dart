import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/goal_model.dart';
import '../../models/transaction_model.dart';
import 'db_helper.dart';

class GoalService {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal();

  final StreamController<List<GoalModel>> _goalController =
      StreamController<List<GoalModel>>.broadcast();

  // ---------------- All Goals Stream ----------------
  Stream<List<GoalModel>> getGoalStream() {
    _loadGoals();
    return _goalController.stream;
  }

  Future<void> _loadGoals() async {
    final goals = await getGoals().first;
    _goalController.add(goals);
  }

  // ---------------- CRUD ----------------
  Stream<List<GoalModel>> getGoals() async* {
    final db = await DBHelper.database;

    await for (final _ in Stream.periodic(const Duration(milliseconds: 500))) {
      final result = await db.query('goals', orderBy: 'id DESC');
      yield result.map((e) => GoalModel.fromMap(e)).toList();
    }
  }

  Future<GoalModel?> getGoalById(int id) async {
    final db = await DBHelper.database;
    final maps = await db.query(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return GoalModel.fromMap(maps.first);
    return null;
  }

  Future<int> createGoal(GoalModel goal) async {
    final db = await DBHelper.database;
    final id = await db.insert(
      'goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _loadGoals();
    return id;
  }

  Future<bool> updateGoal(int id, Map<String, dynamic> data) async {
    final db = await DBHelper.database;
    final count = await db.update(
      'goals',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadGoals();
    return count > 0;
  }

  Future<bool> deleteGoal(int id) async {
    final db = await DBHelper.database;
    final count = await db.delete('goals', where: 'id = ?', whereArgs: [id]);
    await _loadGoals();
    return count > 0;
  }

  // ---------------- Goal Progress ----------------
  Future<void> addProgress(int goalId, double amount) async {
    final goal = await getGoalById(goalId);
    if (goal == null) return;

    goal.currentAmount += amount;
    if (goal.currentAmount >= goal.targetAmount) {
      goal.status = 'completed';
    }

    await updateGoal(goalId, goal.toMap());
  }

  Future<void> subtractProgress(int goalId, double amount) async {
    final goal = await getGoalById(goalId);
    if (goal == null) return;

    goal.currentAmount -= amount;
    if (goal.currentAmount < 0) goal.currentAmount = 0;

    if (goal.currentAmount < goal.targetAmount && goal.status == 'completed') {
      goal.status = 'active';
    }

    await updateGoal(goalId, goal.toMap());
  }

  // ---------------- Integration with Transaction ----------------
  Future<void> handleTransactionAdded(TransactionModel tx) async {
    if (tx.isGoalTransfer && tx.goalId != null) {
      await addProgress(tx.goalId!, tx.amount);
    }
  }

  Future<void> handleTransactionDeleted(TransactionModel tx) async {
    if (tx.isGoalTransfer && tx.goalId != null) {
      await subtractProgress(tx.goalId!, tx.amount);
    }
  }

  void dispose() {
    _goalController.close();
  }
}
