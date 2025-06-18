class Wallet {
  final String id;
  final String name;
  final String userId;

  Wallet({required this.id, required this.name, required this.userId});

  factory Wallet.fromMap(String id, Map<String, dynamic> map) {
    return Wallet(id: id, name: map['name'] ?? '', userId: map['userId'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'userId': userId};
  }
}
