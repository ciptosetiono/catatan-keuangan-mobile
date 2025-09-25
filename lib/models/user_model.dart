class UserModel {
  final int? id;
  final String firebaseUid;
  final String email;
  final String name;

  UserModel({
    this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'firebaseUid': firebaseUid, 'email': email, 'name': name};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      firebaseUid: map['firebaseUid'],
      email: map['email'],
      name: map['name'],
    );
  }
}
