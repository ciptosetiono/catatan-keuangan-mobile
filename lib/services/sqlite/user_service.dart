import 'dart:async';
import 'db_helper.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  Future<Map<String, dynamic>?> getFirstUser() async {
    final db = await DBHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT * FROM users ORDER BY id ASC LIMIT 1',
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null; // or {} if you prefer an empty map
    }
  }
}
