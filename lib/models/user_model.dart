class UserModel {
  final int? id;
  final String firebaseUid;
  final String email;
  final String password;

  UserModel({
    this.id,
    required this.firebaseUid,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'email': email,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      firebaseUid: map['firebaseUid'],
      email: map['email'],
      password: map['password'],
    );
  }
}
