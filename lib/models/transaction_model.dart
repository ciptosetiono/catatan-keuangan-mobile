import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String? walletId;
  final String? categoryId;
  final String userId;

  final String? fromWalletId;
  final String? toWalletId;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.userId,
    required this.walletId,
    this.categoryId,
    this.fromWalletId,
    this.toWalletId,
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
      fromWalletId: data['fromWalletId'],
      toWalletId: data['toWalletId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    DateTime? date,
    String? walletId,
    String? categoryId,
    String? userId,
    String? fromWalletId,
    String? toWalletId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
    );
  }
}
