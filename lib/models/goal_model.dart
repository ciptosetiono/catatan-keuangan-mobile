class GoalModel {
  int? id;
  String name;
  double targetAmount;
  double currentAmount;
  String? startDate; // ISO string
  String? dueDate; // ISO string, optional
  int? walletId; // optional wallet linked to goal
  String status; // 'active', 'completed', 'cancelled'
  String? note;

  GoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.startDate,
    this.dueDate,
    this.walletId,
    this.status = 'active',
    this.note,
  });

  // Convert GoalModel to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate,
      'dueDate': dueDate,
      'walletId': walletId,
      'status': status,
      'note': note,
    };
  }

  // Convert Map from SQLite to GoalModel
  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'],
      name: map['name'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'] ?? 0,
      startDate: map['startDate'],
      dueDate: map['dueDate'],
      walletId: map['walletId'],
      status: map['status'] ?? 'active',
      note: map['note'],
    );
  }
}
