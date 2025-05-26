import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ungdungflutter/models/user_models.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy thông tin user hiện tại
  static Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, currentUser.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin user: ${e.toString()}');
    }
  }

  // Lấy thông tin user theo MSSV
  static Future<UserModel?> getUserByMssv(String mssv) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('mssv', isEqualTo: mssv)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return UserModel.fromFirestore(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi tìm user: ${e.toString()}');
    }
  }

  // Cập nhật thông tin user
  static Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Lỗi cập nhật user: ${e.toString()}');
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Lỗi đăng xuất: ${e.toString()}');
    }
  }

  // Stream để lắng nghe thay đổi thông tin user real-time
  static Stream<UserModel?> getCurrentUserStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(null);

    return _firestore.collection('users').doc(currentUser.uid).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, currentUser.uid);
      }
      return null;
    });
  }
}
