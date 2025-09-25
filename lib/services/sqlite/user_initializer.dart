import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> initializeUserDataOffline() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'money_note.db');

  final db = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Buat table wallets
      await db.execute('''
        CREATE TABLE wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          startBalance REAL,
          currentBalance REAL
        )
      ''');

      // Buat table categories
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          type TEXT
        )
      ''');

      // Buat table transactions
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          walletId INTEGER,
          categoryId INTEGER,
          type TEXT,
          title TEXT,
          amount REAL,
          date INTEGER
        )
      ''');
    },
  );

  // Cek apakah wallets kosong
  final walletCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM wallets'));

  if (walletCount == 0) {
    // 🪙 Tambahkan wallet default
    await db.insert('wallets', {
      'name': 'Bank',
      'startBalance': 0,
      'currentBalance': 0,
    });

    await db.insert('wallets', {
      'name': 'Cash',
      'startBalance': 0,
      'currentBalance': 0,
    });

    // 📂 Tambahkan kategori default
    final defaultCategories = [
      {'name': 'Salary', 'type': 'income'},
      {'name': 'Bonus', 'type': 'income'},
      {'name': 'Food', 'type': 'expense'},
      {'name': 'Transportation', 'type': 'expense'},
      {'name': 'Education', 'type': 'expense'},
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  await db.close();
}
