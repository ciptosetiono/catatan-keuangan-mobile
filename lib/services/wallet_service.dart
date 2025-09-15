import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';

class WalletService {
  final CollectionReference walletsRef = FirebaseFirestore.instance.collection(
    'wallets',
  );

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  /// ✅ Stream wallet list milik user
  Stream<List<Wallet>> getWalletStream() {
    return walletsRef
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Wallet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  /// ✅ Get wallet by ID
  Future<Wallet> getWalletById(String id) async {
    try {
      final doc = await walletsRef.doc(id).get();
      if (doc.exists) {
        return Wallet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('Wallet not found');
      }
    } catch (error) {
      throw Exception('Error fetching wallet: $error');
    }
  }

  /// ✅ Add wallet baru
  Future<void> addWallet(Wallet wallet) async {
    await walletsRef.add(wallet.toMap());
  }

  /// ✅ Update wallet existing
  Future<void> updateWallet(Wallet wallet) async {
    await walletsRef.doc(wallet.id).update(wallet.toMap());
  }

  /// ✅ Delete wallet
  Future<void> deleteWallet(String id) async {
    await walletsRef.doc(id).delete();
  }

  /// ✅ Hitung total balance dari semua wallet user
  Future<int> getTotalBalance() async {
    final snapshot = await walletsRef.where('userId', isEqualTo: userId).get();

    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['currentBalance'] ?? 0) as int;
    }

    return total;
  }

  /// ✅ Tambah saldo ke wallet
  Future<void> increaseBalance(String walletId, int amount) async {
    final ref = walletsRef.doc(walletId);
    await ref.update({'currentBalance': FieldValue.increment(amount)});
  }

  /// ✅ Kurangi saldo dari wallet
  Future<void> decreaseBalance(String walletId, int amount) async {
    final ref = walletsRef.doc(walletId);
    await ref.update({'currentBalance': FieldValue.increment(-amount)});
  }
}
