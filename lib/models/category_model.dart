class Category {
  final String id;
  final String name;
  final String type;
  final String? userId;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.userId,
  });

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'type': type, if (userId != null) 'userId': userId};
  }

  Category copyWith({String? id, String? name, String? type, String? userId}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }
}
