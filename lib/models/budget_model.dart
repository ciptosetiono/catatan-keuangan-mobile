class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final DateTime month;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.month,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'categoryId': categoryId,
    'amount': amount,
    'month': month,
  };

  static Budget fromMap(String id, Map<String, dynamic> map) => Budget(
    id: id,
    userId: map['userId'] as String,
    categoryId: map['categoryId'] as String,
    amount: (map['amount'] as num).toDouble(),
    month: map['month'] as DateTime,
  );

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    DateTime? month,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
    );
  }
}
