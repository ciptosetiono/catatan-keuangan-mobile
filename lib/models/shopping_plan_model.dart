class ShoppingPlan {
  String id;
  String title;
  String userId;
  DateTime createdAt;
  DateTime updatedAt;

  ShoppingPlan({
    required this.id,
    required this.title,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingPlan.fromMap(Map<String, dynamic> map) {
    return ShoppingPlan(
      id: map['id'],
      title: map['title'],
      userId: map['userId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
