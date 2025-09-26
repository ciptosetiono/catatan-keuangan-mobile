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
    if (kIsWeb) {
      // ---------- WEB ----------
      throw UnimplementedError(
        'Web version not implemented yet. Use sembast_web or indexedDB.',
      );
      // Example with sembast_web:
      // final factory = databaseFactoryWeb;
      // final db = await factory.openDatabase(fileName);
      // return db;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // ---------- DESKTOP ----------
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final dbPath = join(await _getDatabasesPath(), fileName);
      return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
    } else {
      // ---------- MOBILE (iOS/Android) ----------
      final dbPath = join(await _getDatabasesPath(), fileName);
      return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
    }
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

  static Future _onCreate(Database db, int version) async {
    // --- Users table ---
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      firebaseUid TEXT UNIQUE NOT NULL,
      email TEXT NOT NULL,
      name TEXT NOT NULL
    )
  ''');

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

    // --- Categories table ---
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      FOREIGN KEY (userId) REFERENCES users(firebaseUid)
    )
  ''');

    // --- Transactions table ---
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      walletId INTEGER NOT NULL,
      fromWalletId INTEGER,
      toWalletId INTEGER,
      categoryId INTEGER,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      date TEXT NOT NULL,
      title TEXT,
      FOREIGN KEY (walletId) REFERENCES wallets(id),
      FOREIGN KEY (fromWalletId) REFERENCES wallets(id),
      FOREIGN KEY (toWalletId) REFERENCES wallets(id),
      FOREIGN KEY (categoryId) REFERENCES categories(id)
    )
  ''');

    // --- Budgets table ---
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
