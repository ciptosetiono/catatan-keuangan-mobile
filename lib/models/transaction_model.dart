import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String? walletId;
  final String? categoryId;
  final String? note;
  final String userId;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.userId,
    this.walletId,
    this.categoryId,
    this.note,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: data['type'] ?? 'expense',
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      walletId: data['walletId'], // stored as string in Firestore
      categoryId: data['categoryId'],
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,
      'note': note,
    };
  }
}
