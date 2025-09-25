import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import 'package:money_note/models/category_model.dart';

class CategoryService {
  final StreamController<List<Category>> _categoryController =
      StreamController<List<Category>>.broadcast();

  String? _currentUserId;
  String? _currentType;
  String? _currentQuery;

  // Getter stream untuk UI
  Stream<List<Category>> get categoryStream => _categoryController.stream;

  // ======================= Load Categories =======================
  Future<void> loadCategories({
    required String userId,
    String? type,
    String? query,
  }) async {
    _currentUserId = userId;
    _currentType = type;
    _currentQuery = query;

    final db = await DBHelper.database;

    String where = "userId = ?";
    List<dynamic> whereArgs = [userId];

    if (type != null && type.isNotEmpty && type != 'all') {
      where += " AND type = ?";
      whereArgs.add(type);
    }

    final maps = await db.query(
      'categories',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    var list = maps.map((m) => Category.fromMap(m['id'] as String, m)).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((cat) => cat.name.toLowerCase().contains(q)).toList();
    }

    _categoryController.add(list);
  }

  // ======================= Get By ID =======================
  Future<Category?> getCategoryById(String id) async {
    final db = await DBHelper.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first['id'] as String, maps.first);
    }
    return null;
  }

  // ======================= Add =======================
  Future<void> addCategory(Category category) async {
    final db = await DBHelper.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _reloadLastQuery();
  }

  // ======================= Update =======================
  Future<void> updateCategory(Category category) async {
    final db = await DBHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await _reloadLastQuery();
  }

  // ======================= Delete =======================
  Future<void> deleteCategory(String id) async {
    final db = await DBHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await _reloadLastQuery();
  }

  // ======================= Reload Query =======================
  Future<void> _reloadLastQuery() async {
    if (_currentUserId != null) {
      await loadCategories(
        userId: _currentUserId!,
        type: _currentType,
        query: _currentQuery,
      );
    }
  }

  void dispose() {
    _categoryController.close();
  }
}
