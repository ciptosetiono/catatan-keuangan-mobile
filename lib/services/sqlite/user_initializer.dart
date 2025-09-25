import 'package:sqflite/sqflite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'db_helper.dart';

Future<void> initializeUserData() async {
  final db = await DBHelper.database;

  await initializeUsers(db);
  await initializeWallets(db);
  await initializeCategories(db);
}

/// ---------------- Users ----------------
Future<void> initializeUsers(Database db) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final userId = firebaseUser?.uid ?? generateRandomUserId(8);

  final userCount =
      (Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ??
          0);

  if (userCount == 0) {
    await db.insert('users', {
      'id': userId,
      'firebaseUid': firebaseUser?.uid,
      'email': firebaseUser?.email,
      'name': firebaseUser?.displayName,
    });
  }
}

/// ---------------- Wallets ----------------
Future<void> initializeWallets(Database db) async {
  final walletCount =
      (Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM wallets'),
          ) ??
          0);

  if (walletCount == 0) {
    final defaultWallets = [
      {'name': 'Bank', 'startBalance': 0, 'currentBalance': 0},
      {'name': 'Cash', 'startBalance': 0, 'currentBalance': 0},
    ];

    for (var wallet in defaultWallets) {
      await db.insert('wallets', wallet);
    }
  }
}

/// ---------------- Categories ----------------
Future<void> initializeCategories(Database db) async {
  final categoryCount =
      (Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM categories'),
          ) ??
          0);

  if (categoryCount == 0) {
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
}

/// ---------------- Helper ----------------
String generateRandomUserId(int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random();
  return List.generate(
    length,
    (index) => chars[rand.nextInt(chars.length)],
  ).join();
}
