import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:money_note/models/wallet_model.dart';
import 'db_helper.dart';

class WalletService {
  // Singleton
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  // StreamController untuk realtime updates
  final StreamController<List<Wallet>> _walletsController =
      StreamController<List<Wallet>>.broadcast();

  final Map<String, StreamController<Wallet?>> _walletByIdControllers = {};

  // Cache in-memory
  final Map<String, Wallet> _walletCache = {};

  // ================= Stream =================

  Stream<List<Wallet>> getWalletStream() {
    // load from DB awalnya
    _refreshWalletsFromDB();
    return _walletsController.stream;
  }

  Stream<Wallet?> getWalletStreamById(String id) {
    if (!_walletByIdControllers.containsKey(id)) {
      _walletByIdControllers[id] = StreamController<Wallet?>.broadcast();
    }

    // kirim data dari cache dulu jika ada
    if (_walletCache.containsKey(id)) {
      _walletByIdControllers[id]!.add(_walletCache[id]);
    }

    _refreshWalletByIdFromDB(id);
    return _walletByIdControllers[id]!.stream;
  }

  // ================= Private Helpers =================

  Future<void> _refreshWalletsFromDB() async {
    final wallets = await getWallets();
    _walletsController.add(wallets);
  }

  Future<void> _refreshWalletByIdFromDB(String id) async {
    final wallet = await getWalletById(id); // method sudah ada
    if (_walletByIdControllers.containsKey(id)) {
      _walletByIdControllers[id]!.add(wallet);
    }
  }

  // ================= CRUD =================

  Future<List<Wallet>> getWallets() async {
    final db = await DBHelper.database;
    final maps = await db.query('wallets', orderBy: 'name ASC');

    final wallets =
        maps.map((e) {
          final id = e['id'].toString();
          return Wallet.fromMap(id, e);
        }).toList();

    // update cache
    _walletCache.clear();
    for (var w in wallets) {
      _walletCache[w.id] = w;
    }

    return wallets;
  }

  Future<Wallet?> getWalletById(String id) async {
    // cek cache dulu
    if (_walletCache.containsKey(id)) return _walletCache[id];

    final db = await DBHelper.database;
    final maps = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final wallet = Wallet.fromMap(maps.first['id'].toString(), maps.first);
      _walletCache[id] = wallet;
      return wallet;
    }
    return null;
  }

  Future<Wallet?> addWallet(Wallet wallet) async {
    final db = await DBHelper.database;

    // insert dan ambil ID auto-generate
    final id = await db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final newWallet = wallet.copyWith(id: id.toString());

    _walletCache[newWallet.id] = newWallet;

    _notifyWalletsUpdate();
    _notifyWalletById(newWallet.id, newWallet);

    return newWallet;
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
      _walletCache[wallet.id] = wallet;
      _notifyWalletsUpdate();
      _notifyWalletById(wallet.id, wallet);
      return true;
    }
    return false;
  }

  Future<bool> deleteWallet(String id) async {
    final db = await DBHelper.database;
    final count = await db.delete('wallets', where: 'id = ?', whereArgs: [id]);

    if (count > 0) {
      _walletCache.remove(id);
      _notifyWalletsUpdate();
      _notifyWalletById(id, null);
      return true;
    }
    return false;
  }

  // ================= Balance =================

  Future<void> increaseBalance(String walletId, int amount) async {
    final db = await DBHelper.database;
    await db.rawUpdate(
      'UPDATE wallets SET currentBalance = currentBalance + ? WHERE id = ?',
      [amount, walletId],
    );

    // update cache dan stream
    final wallet = await getWalletById(walletId);
    if (wallet != null) {
      _walletCache[walletId] = wallet;
      _notifyWalletsUpdate();
      _notifyWalletById(walletId, wallet);
    }
  }

  Future<void> decreaseBalance(String walletId, int amount) async {
    await increaseBalance(walletId, -amount);
  }

  Future<int> getTotalBalance() async {
    final db = await DBHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(currentBalance) as total FROM wallets',
    );

    final total = result.first['total'];
    return total is int ? total : int.parse(total?.toString() ?? '0');
  }

  // ================= Notify Helpers =================

  void _notifyWalletsUpdate() {
    _walletsController.add(
      _walletCache.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  void _notifyWalletById(String id, Wallet? wallet) {
    if (_walletByIdControllers.containsKey(id)) {
      _walletByIdControllers[id]!.add(wallet);
    }
  }

  // ================= Dispose =================

  void dispose() {
    _walletsController.close();
    for (var c in _walletByIdControllers.values) {
      c.close();
    }
  }
}
