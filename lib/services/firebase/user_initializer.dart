import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initializeUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  final userId = user?.uid;

  if (userId == null) return;

  final walletRef = FirebaseFirestore.instance
      .collection('wallets')
      .where('userId', isEqualTo: userId);

  final walletSnapshot = await walletRef.get();

  if (walletSnapshot.docs.isEmpty) {
    // 🪙 Tambahkan wallet default
    await FirebaseFirestore.instance.collection('wallets').add({
      'name': 'Bank',
      'startBalance': 0,
      'currentBalance': 0,
      'userId': userId,
      'createdAt': DateTime.now(),
    });

    await FirebaseFirestore.instance.collection('wallets').add({
      'name': 'Cash',
      'startBalance': 0,
      'currentBalance': 0,
      'userId': userId,
      'createdAt': DateTime.now(),
    });

    // 📂 Tambahkan kategori default
    final defaultCategories = [
      {'name': 'Salary', 'type': 'income'},
      {'name': 'Bonus', 'type': 'income'},
      {'name': 'Food', 'type': 'expense'},
      {'name': 'Transportation', 'type': 'expense'},
      {'name': 'Education', 'type': 'expense'},
    ];

    for (var category in defaultCategories) {
      await FirebaseFirestore.instance.collection('categories').add({
        ...category,
        'userId': userId,
        'createdAt': DateTime.now(),
      });
    }
  }
}
