import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Register user
  Future<void> register(String username, String password) async {
    final db = await DBHelper.database;
    await db.insert('users', {
      'username': username,
      'password': password,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Login user
  Future<bool> login(String username, String password) async {
    final db = await DBHelper.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty;
  }

  // Optional: get all users (for debug)
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await DBHelper.database;
    return db.query('users');
  }
}
