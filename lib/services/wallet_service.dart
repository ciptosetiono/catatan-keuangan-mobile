import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference walletsRef = FirebaseFirestore.instance.collection(
    'wallets',
  );
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Local cache
  List<Wallet> _localCache = [];

  WalletService() {
    // Aktifkan offline persistence Firestore
    _db.settings = const Settings(persistenceEnabled: true);
  }

  /// Stream wallet list milik user (support offline)
  Stream<List<Wallet>> getWalletStream() async* {
    if (userId == null) return;

    await for (var snap in walletsRef
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots(includeMetadataChanges: true)) {
      _localCache =
          snap.docs
              .map(
                (doc) =>
                    Wallet.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList();
      yield _localCache;
    }
  }

  /// Get wallet by ID
  Future<Wallet> getWalletById(String id) async {
    // Cek cache dulu
    final cached = _localCache.firstWhere(
      (w) => w.id == id,
      orElse:
          () => Wallet(
            id: id,
            name: '',
            currentBalance: 0,
            userId: userId ?? '',
            startBalance: 0,
            createdAt: DateTime.now(),
          ),
    );
    if (cached.name.isNotEmpty) return cached;

    // Ambil dari Firestore
    final doc = await walletsRef
        .doc(id)
        .get(GetOptions(source: Source.serverAndCache));
    if (doc.exists) {
      final wallet = Wallet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      // update cache
      _localCache.removeWhere((w) => w.id == wallet.id);
      _localCache.add(wallet);
      return wallet;
    }

    throw Exception('Wallet not found');
  }

  /// Add wallet baru
  Future<void> addWallet(Wallet wallet) async {
    _localCache.add(wallet); // update cache
    try {
      final docRef = walletsRef.doc();
      await docRef.set(wallet.copyWith(id: docRef.id).toMap());
    } catch (_) {
      // Offline: cache tetap dipakai
    }
  }

  /// Update wallet existing
  Future<void> updateWallet(Wallet wallet) async {
    int index = _localCache.indexWhere((w) => w.id == wallet.id);
    if (index != -1) _localCache[index] = wallet;

    try {
      await walletsRef.doc(wallet.id).update(wallet.toMap());
    } catch (_) {
      // Offline: cache tetap dipakai
    }
  }

  /// Delete wallet
  Future<void> deleteWallet(String id) async {
    _localCache.removeWhere((w) => w.id == id);

    try {
      await walletsRef.doc(id).delete();
    } catch (_) {
      // Offline: cache tetap dipakai
    }
  }

  /// Hitung total balance dari semua wallet user
  Future<int> getTotalBalance() async {
    try {
      final snapshot = await walletsRef
          .where('userId', isEqualTo: userId)
          .get(GetOptions(source: Source.serverAndCache));
      final wallets =
          snapshot.docs
              .map(
                (doc) =>
                    Wallet.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList();
      _localCache = wallets;
      return wallets
          .fold<num>(0, (sum, w) => sum + (w.currentBalance ?? 0))
          .toInt();
    } catch (_) {
      // Offline: gunakan cache
      return _localCache.fold<int>(
        0,
        (sum, w) => sum + w.currentBalance.toInt(),
      );
    }
  }

  /// Tambah saldo ke wallet
  Future<void> increaseBalance(String walletId, int amount) async {
    int index = _localCache.indexWhere((w) => w.id == walletId);
    if (index != -1) {
      final wallet = _localCache[index];
      _localCache[index] = wallet.copyWith(
        currentBalance: wallet.currentBalance + amount.toDouble(),
      );
    }

    try {
      await walletsRef.doc(walletId).update({
        'currentBalance': FieldValue.increment(amount),
      });
    } catch (_) {
      // Offline: cache tetap dipakai
    }
  }

  /// Kurangi saldo dari wallet
  Future<void> decreaseBalance(String walletId, int amount) async {
    await increaseBalance(walletId, -amount);
  }
}
