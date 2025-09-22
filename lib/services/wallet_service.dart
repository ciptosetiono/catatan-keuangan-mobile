import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _walletsRef => _db.collection('wallets');

  WalletService() {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Stream wallet list (offline-first)
  Stream<List<Wallet>> getWalletStream() {
    if (userId == null) return const Stream.empty();

    return _walletsRef
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Wallet.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  /// Get wallet by ID (offline-first)
  Future<Wallet?> getWalletById(String id) async {
    final doc = await _walletsRef.doc(id).get(GetOptions(source: Source.cache));
    if (doc.exists) {
      return Wallet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }

    // fallback: server if not in cache
    final serverDoc = await _walletsRef
        .doc(id)
        .get(GetOptions(source: Source.server));
    if (serverDoc.exists) {
      return Wallet.fromMap(
        serverDoc.id,
        serverDoc.data() as Map<String, dynamic>,
      );
    }

    return null;
  }

  /// Add wallet (offline-ready)
  Future<void> addWallet(Wallet wallet) async {
    final docRef = _walletsRef.doc();
    await docRef.set(wallet.copyWith(id: docRef.id).toMap());
  }

  /// Update wallet (offline-ready)
  Future<void> updateWallet(Wallet wallet) async {
    await _walletsRef.doc(wallet.id).update(wallet.toMap());
  }

  void updateWalletBatch(WriteBatch batch, Wallet wallet) {
    final docRef = _walletsRef.doc(wallet.id);
    batch.update(docRef, wallet.toMap());
  }

  /// Delete wallet (offline-ready)
  Future<void> deleteWallet(String walletId) async {
    await _walletsRef.doc(walletId).delete();
  }

  /// Increase balance (offline-ready)
  Future<void> increaseBalance(String walletId, int amount) async {
    await _walletsRef.doc(walletId).update({
      'currentBalance': FieldValue.increment(amount),
    });
  }

  /// Decrease balance (offline-ready)
  Future<void> decreaseBalance(String walletId, int amount) async {
    await increaseBalance(walletId, -amount);
  }

  /// Get total balance (offline-first)
  Future<int> getTotalBalance() async {
    try {
      final snapshot = await _walletsRef
          .where('userId', isEqualTo: userId)
          .get(GetOptions(source: Source.cache));
      final wallets =
          snapshot.docs
              .map(
                (doc) =>
                    Wallet.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList();
      // ignore: avoid_types_as_parameter_names
      return wallets.fold<int>(0, (sum, w) => sum + w.currentBalance.toInt());
    } catch (_) {
      // If offline and cache unavailable
      return 0;
    }
  }
}
