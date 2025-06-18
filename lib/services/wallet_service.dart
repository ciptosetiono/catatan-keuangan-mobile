import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';

class WalletService {
  final CollectionReference walletsRef = FirebaseFirestore.instance.collection(
    'wallets',
  );

  Stream<List<Wallet>> getWalletStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return walletsRef
        .where('userId', isEqualTo: uid)
        .orderBy('name')
        .snapshots()
        .handleError((e) {
          print('Error fetching wallets: $e');
        })
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    Wallet.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  Future<void> addWallet(Wallet wallet) async {
    print('Adding wallet: ${wallet.name}');
    await walletsRef.add(wallet.toMap());
    print('✅ Wallet ditambahkan');
  }

  Future<void> updateWallet(Wallet wallet) async {
    await walletsRef.doc(wallet.id).update(wallet.toMap());
  }

  Future<void> deleteWallet(String id) async {
    await walletsRef.doc(id).delete();
  }
}
