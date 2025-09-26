class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;

  /// Stored in DB as "yyyy-MM"
  final String month;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.month,
  });

  /// Helper to create "yyyy-MM" string from DateTime
  static String formatMonth(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}";
  }

  /// Convert object to map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'amount': amount,
      'month': month,
    };
  }

  /// Convert SQLite row back to Budget object
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'].toString(),
      userId: map['userId'],
      categoryId: map['categoryId'].toString(),
      amount: (map['amount'] ?? 0).toDouble(),
      month: map['month'], // stored as "yyyy-MM"
    );
  }

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    String? month,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
    );
  }

  /// Get DateTime object back (always first day of month)
  DateTime get monthDate {
    final parts = month.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }
}
