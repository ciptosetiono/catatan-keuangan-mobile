import 'db_helper.dart';
import 'package:money_note/models/shopping_plan_item_model.dart';

class ShoppingPlanItemService {
  // --- Create ---
  Future<void> insertItem(ShoppingPlanItem item) async {
    final db = await DBHelper.database;
    await db.insert('shopping_plan_items', item.toMap());
  }

  // --- Read all items for a plan ---
  Future<List<ShoppingPlanItem>> getItems(String planId) async {
    final db = await DBHelper.database;
    final maps = await db.query(
      'shopping_plan_items',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => ShoppingPlanItem.fromMap(map)).toList();
  }

  // --- Stream ---
  Stream<List<ShoppingPlanItem>> getItemsStream(String planId) async* {
    while (true) {
      final items = await getItems(planId);
      yield items;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // --- Update ---
  Future<void> updateItem(ShoppingPlanItem item) async {
    final db = await DBHelper.database;
    await db.update(
      'shopping_plan_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // --- Delete ---
  Future<void> deleteItem(String id) async {
    final db = await DBHelper.database;
    await db.delete('shopping_plan_items', where: 'id = ?', whereArgs: [id]);
  }

  // --- Mark item as bought + insert transaction ---
  Future<void> markItemBoughtAndInsertTransaction(
    ShoppingPlanItem item,
    double actualPrice,
    int walletId,
  ) async {
    final db = await DBHelper.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      // Update item
      await txn.update(
        'shopping_plan_items',
        {
          'bought': 1,
          'actual_price': actualPrice,
          'actual_quantity': item.quantity,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );

      // Insert transaction
      await txn.insert('transactions', {
        'userId': item.planId, // or pass userId separately
        'walletId': walletId,
        'categoryId': null,
        'shopping_plan_item_id': item.id,
        'amount': actualPrice,
        'type': 'expense',
        'date': now.toIso8601String(),
        'title': item.name,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    });
  }
}
