import 'package:sqflite/sqflite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'db_helper.dart';
import 'wallet_service.dart';

Future<void> initializeUserData() async {
  final db = await DBHelper.database;

  final userId = await initializeUsers(db);
  await initializeWallets(db, userId);
  await initializeCategories(db, userId);
}

/// ---------------- Users ----------------
Future<String> initializeUsers(Database db) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final userId = firebaseUser?.uid ?? generateRandomUserId(8);

  final userCount =
      (Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ??
          0);

  if (userCount == 0) {
    await db.insert('users', {
      'firebaseUid': userId,
      'email': firebaseUser?.email ?? '',
      'name': firebaseUser?.displayName ?? 'User',
    });
  }

  return userId;
}

/// ---------------- Wallets ----------------
Future<void> initializeWallets(Database db, String userId) async {
  final walletCount =
      (Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM wallets'),
          ) ??
          0);

  if (walletCount == 0) {
    final defaultWallets = [
      {
        'name': 'Bank',
        'startBalance': 0,
        'currentBalance': 0,
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Cash',
        'startBalance': 0,
        'currentBalance': 0,
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];

    for (var wallet in defaultWallets) {
      await db.insert('wallets', wallet);
    }

    //ensure wallet data is write to disk
    WalletService().getWallets().then((wallets) {
      WalletService().getWalletStream(); // memaksa refresh stream
    });
  }
}

/// ---------------- Categories ----------------
Future<void> initializeCategories(Database db, String userId) async {
  final categoryCount =
      (Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM categories'),
          ) ??
          0);

  if (categoryCount == 0) {
    final defaultCategories = [
      {'name': 'Salary', 'type': 'income', 'userId': userId},
      {'name': 'Bonus', 'type': 'income', 'userId': userId},
      {'name': 'Food', 'type': 'expense', 'userId': userId},
      {'name': 'Transportation', 'type': 'expense', 'userId': userId},
      {'name': 'Education', 'type': 'expense', 'userId': userId},
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
