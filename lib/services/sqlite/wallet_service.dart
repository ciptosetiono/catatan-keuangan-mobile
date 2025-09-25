import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:money_note/models/wallet_model.dart';
import 'db_helper.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  // StreamController untuk realtime update
  final StreamController<List<Wallet>> _walletController =
      StreamController<List<Wallet>>.broadcast();

  // ======================= Stream =======================

  Stream<List<Wallet>> getWalletStream({String? userId}) {
    _loadWallets(userId: userId); // load pertama kali
    return _walletController.stream;
  }

  Future<void> _loadWallets({String? userId}) async {
    final wallets = await getWallets(userId: userId);
    _walletController.add(wallets);
  }

  // ======================= CRUD =======================

  Future<List<Wallet>> getWallets({String? userId}) async {
    final db = await DBHelper.database;
    final maps = await db.query(
      'wallets',
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'name ASC',
    );
    return maps.map((e) {
      final id = e['id'].toString(); // ambil id
      return Wallet.fromMap(id, e);
    }).toList();
  }

  Future<Wallet?> getWalletById(String id) async {
    final db = await DBHelper.database;
    final maps = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final id = maps.first['id'].toString(); // ambil id
      return Wallet.fromMap(id, maps.first);
    }
    return null;
  }

  Future<Wallet?> addWallet(Wallet wallet) async {
    final db = await DBHelper.database;
    await db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _loadWallets(userId: wallet.userId);
    return wallet;
  }

  Future<bool> updateWallet(Wallet wallet) async {
    final db = await DBHelper.database;
    final count = await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
    if (count > 0) {
      await _loadWallets(userId: wallet.userId);
    }
    return count > 0;
  }

  Future<bool> deleteWallet(String id, {String? userId}) async {
    final db = await DBHelper.database;
    final count = await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
    if (count > 0) {
      await _loadWallets(userId: userId);
    }
    return count > 0;
  }

  // ======================= Balance =======================

  Future<void> increaseBalance(
    String walletId,
    int amount, {
    String? userId,
  }) async {
    final db = await DBHelper.database;
    await db.rawUpdate(
      '''
      UPDATE wallets 
      SET currentBalance = currentBalance + ? 
      WHERE id = ?
    ''',
      [amount, walletId],
    );
    await _loadWallets(userId: userId);
  }

  Future<void> decreaseBalance(
    String walletId,
    int amount, {
    String? userId,
  }) async {
    await increaseBalance(walletId, -amount, userId: userId);
  }

  Future<int> getTotalBalance({String? userId}) async {
    final db = await DBHelper.database;
    final result = await db.rawQuery(
      userId != null
          ? 'SELECT SUM(currentBalance) as total FROM wallets WHERE userId = ?'
          : 'SELECT SUM(currentBalance) as total FROM wallets',
      userId != null ? [userId] : [],
    );
    return result.first['total'] as int? ?? 0;
  }

  // ======================= Dispose =======================

  void dispose() {
    _walletController.close();
  }
}
