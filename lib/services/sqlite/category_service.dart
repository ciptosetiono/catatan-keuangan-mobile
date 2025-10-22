import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import 'package:money_note/models/category_model.dart';

class CategoryService {
  // Singleton
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  // ================= Stream =================
  final StreamController<List<Category>> _categoriesController =
      StreamController<List<Category>>.broadcast();
  final Map<String, StreamController<Category?>> _categoryByIdControllers = {};

  // Cache in-memory
  final Map<String, Category> _categoryCache = {};

  // State terakhir query untuk reload
  String? _currentType;
  String? _currentQuery;

  // ================= Getters =================
  Stream<List<Category>> get categoryStream => _categoriesController.stream;

  Stream<List<Category>> getCategoryStream({String? type, String? query}) {
    _loadCategories(type: type, query: query);
    return categoryStream;
  }

  Stream<Category?> getCategoryStreamById(String id) {
    if (!_categoryByIdControllers.containsKey(id)) {
      _categoryByIdControllers[id] = StreamController<Category?>.broadcast();
    }

    // Kirim cache dulu jika ada
    if (_categoryCache.containsKey(id)) {
      _categoryByIdControllers[id]!.add(_categoryCache[id]);
    }

    _loadCategoryById(id);
    return _categoryByIdControllers[id]!.stream;
  }

  Future<List<Category>> getCategories({String? type, String? query}) async {
    final db = await DBHelper.database;

    String where = "";
    List<dynamic> whereArgs = [];

    if (type != null && type.isNotEmpty && type != 'all') {
      where += " AND type = ?";
      whereArgs.add(type);
    }

    final maps = await db.query(
      'categories',
      where: where.isNotEmpty ? where.substring(5) : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    var list =
        maps.map((m) => Category.fromMap(m['id'].toString(), m)).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((cat) => cat.name.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  // ================= Load Categories =================
  Future<void> _loadCategories({String? type, String? query}) async {
    _currentType = type;
    _currentQuery = query;

    final db = await DBHelper.database;

    String where = "";
    List<dynamic> whereArgs = [];

    if (type != null && type.isNotEmpty && type != 'all') {
      where += " AND type = ?";
      whereArgs.add(type);
    }

    final maps = await db.query(
      'categories',
      where:
          where.isNotEmpty ? where.substring(5) : null, // remove leading " AND"
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    var list =
        maps.map((m) => Category.fromMap(m['id'].toString(), m)).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((cat) => cat.name.toLowerCase().contains(q)).toList();
    }

    // update cache
    _categoryCache.clear();
    for (var cat in list) {
      _categoryCache[cat.id] = cat;
    }

    _notifyCategoriesUpdate();
  }

  Future<void> _loadCategoryById(String id) async {
    final category = await getCategoryById(id);
    if (_categoryByIdControllers.containsKey(id)) {
      _categoryByIdControllers[id]!.add(category);
    }
  }

  // ================= CRUD =================
  Future<Category?> getCategoryById(String id) async {
    if (_categoryCache.containsKey(id)) return _categoryCache[id];

    final db = await DBHelper.database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final cat = Category.fromMap(maps.first['id'] as String, maps.first);
      _categoryCache[id] = cat;
      return cat;
    }
    return null;
  }

  Future<Category> addCategory(Category category) async {
    final db = await DBHelper.database;
    final id = await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Reload stream
    await _reloadLastQuery();

    // Kembalikan Category dengan ID baru
    return category.copyWith(id: id.toString());
  }

  Future<Category?> updateCategory(Category category) async {
    final db = await DBHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await _reloadLastQuery();

    _notifyCategoryById(category.id, category);
    // Fetch the nupdated category
    final updatedCategory = await getCategoryById(category.id);
    return updatedCategory;
  }

  Future<void> deleteCategory(String id) async {
    final db = await DBHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    _categoryCache.remove(id);
    await _reloadLastQuery();
    _notifyCategoryById(id, null);
  }

  Future<void> _reloadLastQuery() async {
    await _loadCategories(type: _currentType, query: _currentQuery);
  }

  // ================= Notify Helpers =================
  void _notifyCategoriesUpdate() {
    _categoriesController.add(
      _categoryCache.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  void _notifyCategoryById(String id, Category? category) {
    if (_categoryByIdControllers.containsKey(id)) {
      _categoryByIdControllers[id]!.add(category);
    }
  }

  // ================= Dispose =================
  void dispose() {
    _categoriesController.close();
    for (var c in _categoryByIdControllers.values) {
      c.close();
    }
  }
}
