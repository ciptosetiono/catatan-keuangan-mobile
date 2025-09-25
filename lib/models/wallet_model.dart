// ignore_for_file: prefer_collection_literals

class Wallet {
  final String id;
  final String userId;
  final String name;
  final double startBalance;
  final double currentBalance;
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.startBalance,
    required this.currentBalance,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory Wallet.fromMap(String id, Map<String, dynamic> map) {
    return Wallet(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '-',
      startBalance: (map['startBalance'] ?? 0).toDouble(),
      currentBalance: (map['currentBalance'] ?? 0).toDouble(),
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'startBalance': startBalance,
      'currentBalance': currentBalance,
      'createdAt': createdAt,
    };
  }

  /// Safe parsing Timestamp from Firestore
  // ignore: unused_element
  static DateTime _parseTimestamp(dynamic value) {
    if (value is DateTime) {
      return value;
    } else {
      return DateTime.now(); // fallback
    }
  }

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    double? startBalance,
    double? currentBalance,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startBalance: startBalance ?? this.startBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Wallet(id: $id, name: $name, balance: $currentBalance, userId: $userId)';
  }
}
