import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import '../../config/database_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DBHelper {
  DBHelper._internal();

  static final DBHelper instance = DBHelper._internal();

  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB(dbConfig['name']!);
    return _db!;
  }

  static Future<Database> _initDB(String fileName) async {
    final dbPath = join(await _getDatabasesPath(), fileName);
    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  static Future<String> _getDatabasesPath() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } else {
      return await getDatabasesPath();
    }
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<void> reopen() async {
    await close();
    await database; // trigger open ulang
  }

  static Future _onCreate(Database db, int version) async {
    await createUsersTable(db);
    await createWalletsTable(db);
    await createCategoriesTable(db);
    await createShoppingPlansTable(db);
    await createShoppingPlanItemsTable(db);
    await createTransactionsTable(db);
    await createBudgetsTable(db);

    await db.execute('PRAGMA foreign_keys = ON;');
  }

  static Future createUsersTable(Database db) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      firebaseUid TEXT UNIQUE NOT NULL,
      email TEXT NOT NULL,
      name TEXT NOT NULL
    )
  ''');
  }

  static Future createWalletsTable(Database db) async {
    // --- Wallets table ---
    await db.execute('''
    CREATE TABLE wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      name TEXT NOT NULL,
      startBalance REAL NOT NULL,
      currentBalance REAL NOT NULL,
      createdAt TEXT NOT NULL,
      FOREIGN KEY (userId) REFERENCES users(firebaseUid)
    )
  ''');
  }

  static Future createCategoriesTable(Database db) async {
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      FOREIGN KEY (userId) REFERENCES users(firebaseUid)
    )
  ''');
  }

  // --- shopping_plans Table table --
  static Future createShoppingPlansTable(Database db) async {
    await db.execute('''
   CREATE TABLE shopping_plans (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    userId TEXT NOT NULL,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL
)
  ''');
  }

  // --- shopping_plan_items table ---
  static Future createShoppingPlanItemsTable(Database db) async {
    await db.execute('''
   CREATE TABLE shopping_plan_items (
    id TEXT PRIMARY KEY,
    planId TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT,
    quantity INTEGER DEFAULT 1,
    estimatedPrice REAL DEFAULT 0.0,
    bought INTEGER DEFAULT 0,
    actualQuantity INTEGER,
    actualPrice REAL,
    notes TEXT,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    FOREIGN KEY(planId) REFERENCES shopping_plans(id) ON DELETE CASCADE
)
  ''');
  }

  static Future createTransactionsTable(Database db) async {
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      walletId INTEGER NOT NULL,
      fromWalletId INTEGER,
      toWalletId INTEGER,
      categoryId INTEGER,
      shoppingPlanItemId TEXT, 
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      date TEXT NOT NULL,
      title TEXT,
      FOREIGN KEY (walletId) REFERENCES wallets(id) ON DELETE SET NULL,
      FOREIGN KEY (fromWalletId) REFERENCES wallets(id) ON DELETE SET NULL,
      FOREIGN KEY (toWalletId) REFERENCES wallets(id) ON DELETE SET NULL,
      FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE SET NULL,
      FOREIGN KEY(shoppingPlanItemId) REFERENCES shopping_plan_items(id) ON DELETE SET NULL
    )
  ''');
  }

  static Future createBudgetsTable(Database db) async {
    await db.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      categoryId INTEGER,
      amount REAL NOT NULL,
      month TEXT NOT NULL,
      FOREIGN KEY (userId) REFERENCES users(firebaseUid),
      FOREIGN KEY (categoryId) REFERENCES categories(id)
  )
  ''');
  }
}
