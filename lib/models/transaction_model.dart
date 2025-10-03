class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type; // 'income' ,  'expense' or 'transfer'
  final DateTime date;
  final String? walletId; //for type "income or expense"
  final String? walletName;
  final String? fromWalletId; //for type "transfer"
  final String? toWalletId; //for type "transfer"
  final String? categoryId;
  final String? categoryName;
  String? shoppingPlanItemId;
  final String? userId;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.walletId,
    this.walletName,
    this.fromWalletId,
    this.toWalletId,
    this.categoryId,
    this.categoryName,
    this.shoppingPlanItemId,
    this.userId,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data) {
    DateTime parsedDate;

    final rawDate = data['date'];
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now(); // fallback
    }

    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return TransactionModel(
      id:
          data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      userId: data['userId']?.toString() ?? '',
      walletId: data['walletId']?.toString() ?? '',
      walletName: data['walletName']?.toString() ?? '',
      amount: parseAmount(data['amount']),
      type: data['type']?.toString() ?? '',
      categoryId: data['categoryId']?.toString() ?? '',
      categoryName: data['categoryName']?.toString() ?? '',
      shoppingPlanItemId: data['shoppingPlanItemId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      date: parsedDate,
      fromWalletId: data['fromWalletId']?.toString() ?? '',
      toWalletId: data['toWalletId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'walletId': walletId,
      if (walletName != null) 'walletName': walletName,
      if (userId != null) 'userId': userId,
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      if (shoppingPlanItemId != null) 'shoppingPlanItemId': shoppingPlanItemId,
      if (fromWalletId != null) 'fromWalletId': fromWalletId,
      if (toWalletId != null) 'toWalletId': toWalletId,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    DateTime? date,
    String? walletId,
    String? walletName,
    String? categoryId,
    String? categoryName,
    String? shoppingPlanItemId,
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
      walletName: walletName ?? this.walletName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      shoppingPlanItemId: shoppingPlanItemId ?? shoppingPlanItemId,
      userId: userId ?? this.userId,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
    );
  }
}
