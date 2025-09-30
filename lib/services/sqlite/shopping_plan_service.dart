import 'db_helper.dart';
import '../../models/shopping_plan_model.dart';

class ShoppingPlanService {
  // --- Create ---
  Future<void> insertPlan(ShoppingPlan plan) async {
    final db = await DBHelper.database;
    await db.insert('shopping_plans', plan.toMap());
  }

  // --- Read ---
  Future<List<ShoppingPlan>> getPlans(String userId) async {
    final db = await DBHelper.database;
    final maps = await db.query(
      'shopping_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ShoppingPlan.fromMap(map)).toList();
  }

  // --- Stream ---
  Stream<List<ShoppingPlan>> getPlansStream(String userId) async* {
    while (true) {
      final plans = await getPlans(userId);
      yield plans;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // --- Update ---
  Future<void> updatePlan(ShoppingPlan plan) async {
    final db = await DBHelper.database;
    await db.update(
      'shopping_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  // --- Delete ---
  Future<void> deletePlan(String id) async {
    final db = await DBHelper.database;
    await db.delete('shopping_plans', where: 'id = ?', whereArgs: [id]);
  }
}
