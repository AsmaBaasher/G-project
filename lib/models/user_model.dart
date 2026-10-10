class UserModel {

  final String name;
  final String email;
  final String phone;

  UserModel({
    required this.name,
    required this.email,
    required this.phone, required String id,
  });

  static UserModel? currentUser;
}
