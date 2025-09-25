// ignore_for_file: empty_catches

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/wallet_model.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final userId = FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Wallet> get walletsRef => _db
      .collection('wallets')
      .withConverter<Wallet>(
        fromFirestore: (snap, _) => Wallet.fromFirestore(snap),
        toFirestore: (wallet, _) => wallet.toMap(),
      );

  WalletService() {
    // 🔑 On mobile, persistence is enabled by default.
    // Only needed on web, but this won't break mobile.
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ======================= Stream / Get Wallets =======================
  Stream<List<Wallet>> getWalletStream() {
    if (userId == null) return const Stream.empty();

    return walletsRef
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ======================= Get Wallet By ID =======================
  Future<Wallet?> getWalletById(String id) async {
    try {
      final cachedDoc = await walletsRef
          .doc(id)
          .get(const GetOptions(source: Source.cache));
      if (cachedDoc.data() != null) return cachedDoc.data();
    } catch (_) {}

    try {
      final serverDoc = await walletsRef
          .doc(id)
          .get(const GetOptions(source: Source.server));
      if (serverDoc.data() != null) return serverDoc.data();
    } catch (_) {}

    return null;
  }

  Stream<Wallet?> getWalletStreamById(String id) {
    return walletsRef.doc(id).snapshots().map((doc) => doc.data());
  }

  // ======================= Add / Update / Delete =======================
  Future<Wallet?> addWallet(Wallet wallet) async {
    try {
      final docRef = walletsRef.doc();
      final newWallet = wallet.copyWith(id: docRef.id);
      await docRef.set(newWallet);
      return newWallet;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateWallet(Wallet wallet) async {
    try {
      await walletsRef.doc(wallet.id).update(wallet.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateWalletBatch(WriteBatch batch, Wallet wallet) {
    final docRef = walletsRef.doc(wallet.id);
    batch.update(docRef, wallet.toMap());
  }

  Future<bool> deleteWallet(String id) async {
    try {
      await walletsRef.doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ======================= Balance =======================
  Future<void> increaseBalance(String walletId, int amount) async {
    await walletsRef.doc(walletId).update({
      'currentBalance': FieldValue.increment(amount),
    });
  }

  Future<void> decreaseBalance(String walletId, int amount) async {
    await increaseBalance(walletId, -amount);
  }

  Future<int> getTotalBalance() async {
    if (userId == null) return 0;

    List<Wallet> list = [];

    try {
      final snapshot = await walletsRef
          .where('userId', isEqualTo: userId)
          .get(const GetOptions(source: Source.cache));
      list = snapshot.docs.map((doc) => doc.data()).toList();
    } catch (_) {}

    if (list.isEmpty) {
      try {
        final snapshot = await walletsRef
            .where('userId', isEqualTo: userId)
            .get(const GetOptions(source: Source.server));
        list = snapshot.docs.map((doc) => doc.data()).toList();
      } catch (_) {}
    }

    // ignore: avoid_types_as_parameter_names
    return list.fold<int>(0, (sum, w) => sum + w.currentBalance.toInt());
  }
}
