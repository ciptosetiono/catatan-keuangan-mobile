import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String userId;
  final String name;
  final num startBalance;
  final num currentBalance;
  final String icon;
  final String color;
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.startBalance,
    required this.currentBalance,
    this.icon = '',
    this.color = '',
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
      startBalance: map['startBalance'] ?? 0,
      currentBalance: map['currentBalance'] ?? 0,
      icon: map['icon'],
      color: map['color'],
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'startBalance': startBalance,
      'currentBalance': currentBalance,
      'icon': icon,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Safe parsing Timestamp from Firestore
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else {
      return DateTime.now(); // fallback
    }
  }

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    double? startBalance,
    double? currentBalance,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      startBalance: startBalance ?? this.startBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
