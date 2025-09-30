class ShoppingPlanItem {
  String id;
  String planId;
  String name;
  String? category;
  int quantity;
  double estimatedPrice;
  bool bought;
  int? actualQuantity;
  double? actualPrice;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  ShoppingPlanItem({
    required this.id,
    required this.planId,
    required this.name,
    this.category,
    this.quantity = 1,
    this.estimatedPrice = 0.0,
    this.bought = false,
    this.actualQuantity,
    this.actualPrice,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingPlanItem.fromMap(Map<String, dynamic> map) {
    return ShoppingPlanItem(
      id: map['id'],
      planId: map['planId'],
      name: map['name'],
      category: map['category'],
      quantity: map['quantity'] ?? 1,
      estimatedPrice: map['estimatedPrice']?.toDouble() ?? 0.0,
      bought: map['bought'] == 1,
      actualQuantity: map['actualQuantity'],
      actualPrice: map['actualPrice']?.toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'estimatedPrice': estimatedPrice,
      'bought': bought ? 1 : 0,
      'actualQquantity': actualQuantity,
      'actualPrice': actualPrice,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
