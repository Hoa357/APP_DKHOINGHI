// ungdungflutter/services/user_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ungdungflutter/models/user_models.dart'; // Đảm bảo đường dẫn này đúng

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy thông tin user hiện tại
  static Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("UserService (getCurrentUser): No current user.");
        return null;
      }

      // Lấy DocumentSnapshot và đảm bảo ép kiểu đúng
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore
              .collection('students') // Hoặc 'users' tùy theo cấu trúc của bạn
              .doc(currentUser.uid)
              .get();

      if (doc.exists) {
        print(
          "UserService (getCurrentUser): Document found for UID ${currentUser.uid}.",
        );
        // === SỬA Ở ĐÂY: Truyền toàn bộ DocumentSnapshot 'doc' ===
        return UserModel.fromFirestore(doc);
        // ======================================================
      }
      print(
        "UserService (getCurrentUser): Document NOT found for UID ${currentUser.uid}.",
      );
      return null;
    } catch (e) {
      print("UserService (getCurrentUser): Error - ${e.toString()}");
      // Xem xét việc throw lỗi có ý nghĩa hơn hoặc trả về một UserModel báo lỗi
      // throw Exception('Lỗi lấy thông tin user: ${e.toString()}');
      return null; // Hoặc tạo một UserModel với trạng thái lỗi
    }
  }

  // Lấy thông tin user theo MSSV
  static Future<UserModel?> getUserByMssv(String mssv) async {
    try {
      print("UserService (getUserByMssv): Searching for MSSV: $mssv");
      final querySnapshot =
          await _firestore
              .collection('students') // Hoặc 'users' tùy theo cấu trúc của bạn
              .where('mssv', isEqualTo: mssv)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Lấy DocumentSnapshot từ QueryDocumentSnapshot và ép kiểu
        final DocumentSnapshot<Map<String, dynamic>> doc =
            querySnapshot.docs.first as DocumentSnapshot<Map<String, dynamic>>;
        print(
          "UserService (getUserByMssv): User found with MSSV $mssv, UID ${doc.id}.",
        );
        // === SỬA Ở ĐÂY: Truyền toàn bộ DocumentSnapshot 'doc' ===
        return UserModel.fromFirestore(doc);
        // ======================================================
      }
      print("UserService (getUserByMssv): No user found with MSSV $mssv.");
      return null;
    } catch (e) {
      print("UserService (getUserByMssv): Error - ${e.toString()}");
      return null;
    }
  }

  // Cập nhật thông tin user
  static Future<void> updateUser(UserModel user) async {
    try {
      print("UserService (updateUser): Updating user UID ${user.uid}.");
      await _firestore
          .collection('students') // Hoặc 'users' tùy theo cấu trúc của bạn
          .doc(user.uid)
          .update(
            user.toFirestore(),
          ); // toFirestore() trả về Map<String, dynamic>
      print(
        "UserService (updateUser): User UID ${user.uid} updated successfully.",
      );
    } catch (e) {
      print("UserService (updateUser): Error - ${e.toString()}");
      throw Exception('Lỗi cập nhật user: ${e.toString()}');
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("UserService (signOut): User signed out successfully.");
    } catch (e) {
      print("UserService (signOut): Error - ${e.toString()}");
      throw Exception('Lỗi đăng xuất: ${e.toString()}');
    }
  }

  // Stream để lắng nghe thay đổi thông tin user real-time
  static Stream<UserModel?> getCurrentUserStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("UserService (getCurrentUserStream): No current user for stream.");
      return Stream.value(null);
    }

    print(
      "UserService (getCurrentUserStream): Listening to changes for UID ${currentUser.uid}.",
    );
    return _firestore
        .collection('students') // Hoặc 'users' tùy theo cấu trúc của bạn
        .doc(currentUser.uid)
        .snapshots() // snapshots() trả về Stream<DocumentSnapshot<Map<String, dynamic>>>
        .map((docSnapshot) {
          // docSnapshot ở đây đã là DocumentSnapshot<Map<String, dynamic>>
          if (docSnapshot.exists) {
            print(
              "UserService (getCurrentUserStream): Data change received, document exists.",
            );
            // === SỬA Ở ĐÂY: Truyền toàn bộ DocumentSnapshot 'docSnapshot' ===
            return UserModel.fromFirestore(docSnapshot);
            // ============================================================
          }
          print(
            "UserService (getCurrentUserStream): Data change received, document does not exist.",
          );
          return null;
        })
        .handleError((error) {
          // Thêm xử lý lỗi cho stream
          print("UserService (getCurrentUserStream): Error in stream - $error");
          return null; // Hoặc phát ra một UserModel báo lỗi
        });
  }
}
