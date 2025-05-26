class UserModel {
  final String uid;
  final String mssv; // Thay đổi từ studentId thành mssv
  final String name; // Thay đổi từ fullName thành name
  final String email;
  final String role;
  final String? avatarUrl;

  UserModel({
    required this.uid,
    required this.mssv,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      mssv: data['mssv'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      avatarUrl: data['avatarUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mssv': mssv,
      'name': name,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
    };
  }
}
