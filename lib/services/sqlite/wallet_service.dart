import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:money_note/models/wallet_model.dart';
import 'db_helper.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  // StreamController untuk realtime updates
  final StreamController<List<Wallet>> _walletsController =
      StreamController<List<Wallet>>.broadcast();

  final Map<String, StreamController<Wallet?>> _walletByIdControllers = {};

  // ================= Stream =================

  /// Stream semua wallet
  Stream<List<Wallet>> getWalletStream() {
    _loadWallets();
    return _walletsController.stream;
  }

  Future<void> _loadWallets() async {
    final wallets = await getWallets();
    _walletsController.add(wallets);

    // update setiap controller wallet per ID
    for (var wallet in wallets) {
      if (_walletByIdControllers.containsKey(wallet.id)) {
        _walletByIdControllers[wallet.id]!.add(wallet);
      }
    }
  }

  /// Stream wallet by ID
  Stream<Wallet?> getWalletStreamById(String id) {
    if (!_walletByIdControllers.containsKey(id)) {
      _walletByIdControllers[id] = StreamController<Wallet?>.broadcast();
    }
    _loadWalletById(id);
    return _walletByIdControllers[id]!.stream;
  }

  Future<void> _loadWalletById(String id) async {
    final wallet = await getWalletById(id);
    if (_walletByIdControllers.containsKey(id)) {
      _walletByIdControllers[id]!.add(wallet);
    }
  }

  // ================= CRUD =================

  Future<List<Wallet>> getWallets() async {
    final db = await DBHelper.database;
    final maps = await db.query('wallets', orderBy: 'name ASC');
    return maps.map((e) {
      final id = e['id'].toString();
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
      final id = maps.first['id'].toString();
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
    await _loadWallets();
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
      await _loadWallets();
    }
    return count > 0;
  }

  Future<bool> deleteWallet(String id) async {
    final db = await DBHelper.database;
    final count = await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
    if (count > 0) {
      await _loadWallets();
    }
    return count > 0;
  }

  // ================= Balance =================

  Future<void> increaseBalance(String walletId, int amount) async {
    final db = await DBHelper.database;
    await db.rawUpdate(
      'UPDATE wallets SET currentBalance = currentBalance + ? WHERE id = ?',
      [amount, walletId],
    );
    await _loadWalletById(walletId);
    await _loadWallets();
  }

  Future<void> decreaseBalance(String walletId, int amount) async {
    await increaseBalance(walletId, -amount);
  }

  Future<int> getTotalBalance() async {
    final db = await DBHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(currentBalance) as total FROM wallets',
    );
    return result.first['total'] as int? ?? 0;
  }

  // ================= Dispose =================

  void dispose() {
    _walletsController.close();
    for (var c in _walletByIdControllers.values) {
      c.close();
    }
  }
}
