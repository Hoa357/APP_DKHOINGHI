import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<void> checkCurrentPassword(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Lỗi: không tìm thấy user đăng nhập');
    }

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException {
      throw Exception('Mật khẩu hiện tại không đúng');
    } catch (_) {
      throw Exception('Lỗi xác thực mật khẩu');
    }
  }

  static Future<void> updatePassword(String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Lỗi: Không tìm thấy user đăng nhập');
    }

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception('Lỗi: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Lỗi: ${e.toString()}');
    }
  }
}
