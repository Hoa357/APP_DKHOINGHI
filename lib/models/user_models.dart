// ungdungflutter/models/user_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? mssv;
  final String? name;
  final String? email;
  final String? role;
  final String? avatarUrl;

  final String? manv;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? address;

  // final String? position; // Bạn đã bỏ trường này, nếu cần thì thêm lại

  final String? status;
  final String? faculty;
  final String? className;
  final String? educationLevel;
  final String? trainingType;
  final String? academicYear; // Đã là int?
  final String? major;
  final String? specialization;

  UserModel({
    required this.uid,
    this.mssv,
    this.name,
    this.email,
    this.role,
    this.avatarUrl,
    this.manv,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.address,
    // this.position,
    this.status,
    this.faculty,
    this.className,
    this.educationLevel,
    this.trainingType,
    this.academicYear,
    this.major,
    this.specialization,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final uid = doc.id;

    if (data == null) {
      return UserModel(uid: uid, role: 'unknown');
    }

    // Hàm helper để parse int an toàn
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return UserModel(
      uid: uid,
      mssv: data['mssv'] as String?,
      name: data['name'] as String?,
      email: data['email'] as String?,
      role: data['role'] as String? ?? 'student',
      avatarUrl:
          (data['avatarUrl'] as String?)?.isNotEmpty == true
              ? data['avatarUrl'] as String?
              : (data['avatar'] as String?)?.isNotEmpty == true
              ? data['avatar'] as String?
              : null,
      manv: data['manv'] as String?,
      dateOfBirth: (data['dob'] as Timestamp?)?.toDate(),
      gender: data['gender'] as String?,
      phone: data['phone'] as String?,
      address: data['address'] as String?,

      // position: data['position'] as String?, // Nếu bạn cần trường này
      status: data['status'] as String?,
      faculty: data['faculty'] as String?,
      className: data['className'] as String? ?? data['class'] as String?,
      educationLevel: data['educationLevel'] as String?,
      trainingType: data['trainingType'] as String?,
      // === SỬ DỤNG HÀM parseInt ĐỂ ĐẢM BẢO AN TOÀN ===
      academicYear: data['academicYear'] as String?,
      // ===============================================
      major: data['major'] as String?,
      specialization: data['specialization'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (mssv != null) 'mssv': mssv,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (manv != null) 'manv': manv,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      // if (position != null) 'position': position,
      if (status != null) 'status': status,
      if (faculty != null) 'faculty': faculty,
      // Trong toFirestore, nếu bạn muốn lưu 'className' thay vì 'class':
      if (className != null)
        'className': className, // Hoặc 'class' tùy theo bạn muốn lưu tên gì
      if (educationLevel != null) 'educationLevel': educationLevel,
      if (trainingType != null) 'trainingType': trainingType,
      if (academicYear != null)
        'academicYear': academicYear, // Firestore sẽ lưu dạng number
      if (major != null) 'major': major,
      if (specialization != null) 'specialization': specialization,
    };
  }

  String? getFormattedDateOfBirth() {
    if (dateOfBirth == null) return null;
    // Định dạng ngày thành dd/MM/yyyy
    final day = dateOfBirth!.day.toString().padLeft(2, '0');
    final month = dateOfBirth!.month.toString().padLeft(2, '0');
    final year = dateOfBirth!.year.toString();
    return "$day/$month/$year";
  }
}
