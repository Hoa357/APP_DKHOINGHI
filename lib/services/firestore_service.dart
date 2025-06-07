import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ungdungflutter/models/activity_model.dart'; // Đảm bảo đường dẫn đúng
import 'package:ungdungflutter/models/activity_registration_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // === QUẢN LÝ ĐĂNG KÝ HOẠT ĐỘNG (SỬ DỤNG TRANSACTION) ===

  /// Đăng ký người dùng cho một hoạt động.
  /// Kiểm tra deadline, số lượng tối đa và cập nhật currentRegistrations.
  Future<void> registerForActivity(String userId, String activityId) async {
    if (userId.isEmpty) {
      throw Exception("UserID không được rỗng khi đăng ký hoạt động.");
    }
    // 1. Kiểm tra xem người dùng đã đăng ký hoạt động này chưa TRƯỚC KHI VÀO TRANSACTION
    // Điều này giúp giảm tải cho transaction nếu người dùng đã đăng ký rồi.
    bool alreadyRegistered = await isUserRegisteredForActivity(
      userId,
      activityId,
    );
    if (alreadyRegistered) {
      throw Exception("Bạn đã đăng ký hoạt động này rồi.");
    }

    final activityRef = _db.collection('activities').doc(activityId);
    // Tạo document ID mới cho bản ghi đăng ký một cách an toàn
    final registrationRef = _db.collection('activity_registrations').doc();

    await _db.runTransaction((transaction) async {
      DocumentSnapshot activitySnapshot = await transaction.get(activityRef);
      if (!activitySnapshot.exists) {
        throw Exception("Hoạt động không tồn tại!");
      }

      Map<String, dynamic> activityData =
          activitySnapshot.data()! as Map<String, dynamic>;
      int currentRegistrations = activityData['currentRegistrations'] ?? 0;
      int maxParticipants =
          activityData['maxParticipants'] ?? 0; // Mặc định là 0 nếu không có
      Timestamp? registrationDeadline =
          activityData['registrationDeadline'] as Timestamp?;
      bool status = activityData['status'] ?? false; // Trạng thái hoạt động

      if (!status) {
        throw Exception("Hoạt động này hiện không mở để đăng ký.");
      }

      if (registrationDeadline != null &&
          registrationDeadline.toDate().isBefore(DateTime.now())) {
        throw Exception("Đã quá hạn đăng ký cho hoạt động này.");
      }

      if (maxParticipants > 0 && currentRegistrations >= maxParticipants) {
        throw Exception("Hoạt động đã đầy số lượng người tham gia.");
      }

      // Thêm bản ghi vào activity_registrations
      transaction.set(registrationRef, {
        'userId': userId,
        'activityId': activityId,
        'registerTime': Timestamp.now(),
      });

      // Cập nhật số lượng người đăng ký hiện tại trong document 'activities'
      transaction.update(activityRef, {
        'currentRegistrations': FieldValue.increment(1),
      });
    });
    print('Người dùng $userId đã đăng ký thành công hoạt động $activityId');
  }

  /// Hủy đăng ký của người dùng khỏi một hoạt động.
  /// Cập nhật currentRegistrations.
  Future<void> unregisterFromActivity(String userId, String activityId) async {
    if (userId.isEmpty) {
      throw Exception("UserID không được rỗng khi hủy đăng ký hoạt động.");
    }
    final activityRef = _db.collection('activities').doc(activityId);

    // Tìm document đăng ký cụ thể để xóa
    final registrationQuery =
        await _db
            .collection('activity_registrations')
            .where('userId', isEqualTo: userId)
            .where('activityId', isEqualTo: activityId)
            .limit(1)
            .get();

    if (registrationQuery.docs.isEmpty) {
      // Người dùng không có bản ghi đăng ký nào cho hoạt động này (có thể đã hủy trước đó)
      print(
        "Không tìm thấy bản ghi đăng ký để hủy cho user: $userId, activity: $activityId. Có thể đã hủy rồi.",
      );
      // Không nên throw Exception ở đây vì có thể người dùng nhấn hủy nhiều lần.
      // Nếu muốn báo lỗi, hãy làm ở tầng UI.
      return;
    }
    final registrationDocId = registrationQuery.docs.first.id;
    final registrationRef = _db
        .collection('activity_registrations')
        .doc(registrationDocId);

    // Kiểm tra hạn chót hủy đăng ký (logic này có thể nằm ở UI hoặc ở đây)
    // Ví dụ: Nếu muốn ngăn hủy sau deadline
    // DocumentSnapshot activityDocForDeadline = await activityRef.get();
    // if (activityDocForDeadline.exists) {
    //   Map<String, dynamic> activityData = activityDocForDeadline.data()! as Map<String, dynamic>;
    //   Timestamp? registrationDeadline = activityData['registrationDeadline'] as Timestamp?;
    //   if (registrationDeadline != null && registrationDeadline.toDate().isBefore(DateTime.now())) {
    //     throw Exception("Đã quá hạn để hủy đăng ký hoạt động này.");
    //   }
    // }

    await _db.runTransaction((transaction) async {
      DocumentSnapshot activitySnapshot = await transaction.get(activityRef);
      if (!activitySnapshot.exists) {
        // Hoạt động có thể đã bị xóa sau khi người dùng đăng ký
        // Trong trường hợp này, chỉ cần xóa bản ghi đăng ký
        print(
          "Hoạt động $activityId không tồn tại khi hủy đăng ký, chỉ xóa bản ghi đăng ký.",
        );
        transaction.delete(registrationRef);
        return; // Không cần cập nhật currentRegistrations nếu activity không tồn tại
      }

      // Xóa bản ghi đăng ký
      transaction.delete(registrationRef);

      // Cập nhật (giảm) số lượng người đăng ký hiện tại
      Map<String, dynamic> activityData =
          activitySnapshot.data()! as Map<String, dynamic>;
      int currentRegistrations = activityData['currentRegistrations'] ?? 0;
      if (currentRegistrations > 0) {
        transaction.update(activityRef, {
          'currentRegistrations': FieldValue.increment(-1),
        });
      } else {
        print(
          "Cảnh báo: currentRegistrations của hoạt động $activityId đã là 0 hoặc null khi hủy đăng ký.",
        );
      }
    });
    print(
      'Người dùng $userId đã hủy đăng ký thành công khỏi hoạt động $activityId',
    );
  }

  /// Kiểm tra xem người dùng hiện tại đã đăng ký một hoạt động cụ thể chưa.
  Future<bool> isUserRegisteredForActivity(
    String userId,
    String activityId,
  ) async {
    if (userId.isEmpty || activityId.isEmpty) return false;
    try {
      final snapshot =
          await _db
              .collection('activity_registrations') // <--- ĐIỂM QUAN TRỌNG
              .where('userId', isEqualTo: userId)
              .where('activityId', isEqualTo: activityId)
              .limit(1)
              .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Lỗi khi kiểm tra isUserRegisteredForActivity: $e");
      return false;
    }
  }
  // === LẤY THÔNG TIN HOẠT ĐỘNG ===

  /// Lấy chi tiết một hoạt động bằng ID của nó.
  /// Trả về null nếu không tìm thấy.
  Future<ActivityModel?> getActivityById(String activityId) async {
    if (activityId.isEmpty) return null;
    try {
      final doc = await _db.collection('activities').doc(activityId).get();
      if (doc.exists) {
        return ActivityModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print("Lỗi khi lấy getActivityById ($activityId): $e");
      return null;
    }
  }

  /// Lấy danh sách các hoạt động dựa trên danh sách ID.
  Future<Map<String, ActivityModel>> getActivitiesByIds(
    List<String> activityIds,
  ) async {
    if (activityIds.isEmpty) return {};
    try {
      // Firestore 'whereIn' query giới hạn 10 item mỗi lần, cần chia nhỏ nếu list quá dài
      // Tuy nhiên, với FlutterFire mới (cloud_firestore >= 3.0.0), giới hạn đã tăng lên 30.
      // Kiểm tra phiên bản của bạn.
      List<List<String>> chunks = [];
      for (var i = 0; i < activityIds.length; i += 30) {
        // Chia thành các chunk 30 ID
        chunks.add(
          activityIds.sublist(
            i,
            i + 30 > activityIds.length ? activityIds.length : i + 30,
          ),
        );
      }

      Map<String, ActivityModel> activitiesMap = {};
      for (var chunk in chunks) {
        if (chunk.isNotEmpty) {
          final snapshot =
              await _db
                  .collection('activities')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get();
          for (var doc in snapshot.docs) {
            activitiesMap[doc.id] = ActivityModel.fromDocument(doc);
          }
        }
      }
      return activitiesMap;
    } catch (e) {
      print("Lỗi khi lấy getActivitiesByIds: $e");
      return {};
    }
  }

  /// Lấy tất cả các lượt đăng ký của một người dùng.
  /// Tham số dateRange được thêm vào để tương thích với lời gọi từ UI,
  /// nhưng hàm này KHÔNG sử dụng nó để lọc query trên Firestore vì
  /// ActivityRegistrationModel không lưu trữ thời gian diễn ra hoạt động.
  /// Việc lọc theo thời gian diễn ra sẽ được thực hiện ở tầng logic cao hơn.
  Future<List<ActivityRegistrationModel>> getAllRegisteredActivities(
    String userId, {
    DateTimeRange?
    dateRange, // Tham số này hiện tại không được dùng để lọc query
  }) async {
    if (userId.isEmpty) return [];
    try {
      Query query = _db
          .collection(
            'activity_registrations',
          ) // Tên collection đăng ký của bạn
          .where('userId', isEqualTo: userId)
          .orderBy(
            'registerTime',
            descending: true,
          ); // Sắp xếp theo đăng ký mới nhất

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ActivityRegistrationModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Lỗi khi lấy getAllRegisteredActivities (userId: $userId): $e");
      return [];
    }
  }

  // Hàm getAvailableActivitiesForDate của bạn có vẻ ổn, nhưng cần kiểm tra Composite Index
  // Tôi sẽ giữ lại nó với một vài điều chỉnh nhỏ
  /// Lấy các hoạt động có sẵn cho một ngày cụ thể và còn hạn đăng ký.
  /// CẦN COMPOSITE INDEX: activities (status ASC, startTime ASC, registrationDeadline ASC/DESC)
  Future<List<ActivityModel>> getAvailableActivitiesForDate(
    DateTime selectedDate,
  ) async {
    try {
      DateTime startOfSelectedDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        0,
        0,
        0,
      );
      DateTime endOfSelectedDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
        59,
        999,
      );

      Timestamp startTimestamp = Timestamp.fromDate(startOfSelectedDay);
      Timestamp endTimestamp = Timestamp.fromDate(endOfSelectedDay);
      Timestamp nowTimestamp = Timestamp.now();

      QuerySnapshot snapshot =
          await _db
              .collection('activities')
              .where('status', isEqualTo: true) // Hoạt động phải đang active
              .where('startTime', isGreaterThanOrEqualTo: startTimestamp)
              .where(
                'startTime',
                isLessThanOrEqualTo: endTimestamp,
              ) // Bao gồm cả các hoạt động kết thúc vào cuối ngày đó
              // Chỉ lấy những hoạt động mà hạn đăng ký vẫn còn hoặc chưa qua ngày hôm nay
              // Nếu registrationDeadline là đầu ngày, isGreaterThanOrEqualTo: nowTimestamp có thể loại bỏ những HD hết hạn trong ngày
              // Để chính xác hơn, có thể cần so sánh registrationDeadline với _endOfDay(now)
              .where(
                'registrationDeadline',
                isGreaterThanOrEqualTo: nowTimestamp,
              )
              // Sắp xếp theo thời gian bắt đầu
              // `orderBy` phải khớp với trường trong `where` có điều kiện không phải equality (ở đây là startTime hoặc registrationDeadline)
              // Nếu có nhiều trường range filter, chỉ 1 trường được dùng trong orderBy.
              // Firestore tự động sắp xếp theo document ID nếu không có orderBy.
              // Nếu muốn sắp xếp theo startTime, và registrationDeadline là range filter, cần index.
              .orderBy(
                'registrationDeadline',
              ) // Sắp xếp theo hạn ĐK gần nhất trước
              .orderBy('startTime') // Rồi mới tới startTime
              .get();
      // LƯU Ý VỀ INDEX:
      // Truy vấn trên cần một composite index phức tạp.
      // Ví dụ: status ASC, registrationDeadline ASC, startTime ASC
      // Firestore sẽ báo lỗi và cung cấp link tạo index nếu cần.

      List<ActivityModel> activities =
          snapshot.docs.map((doc) => ActivityModel.fromDocument(doc)).toList();

      // Lọc client-side thêm nếu cần (ví dụ: những hoạt động đã full nhưng vẫn còn hạn ĐK)
      // activities.retainWhere((activity) => (activity.maxParticipants == 0 || activity.currentRegistrations < activity.maxParticipants));

      return activities;
    } catch (e, s) {
      print("Lỗi khi lấy getAvailableActivitiesForDate ($selectedDate): $e");
      print(s); // In stacktrace để debug index
      return [];
    }
  }

  // Hàm getAllTodayActivities
  Future<List<ActivityModel>> getAllTodayActivities() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final snapshot =
          await _db
              .collection('activities')
              .where(
                'startTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where(
                'startTime',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
              )
              .orderBy('startTime')
              .get();

      return snapshot.docs
          .map((doc) => ActivityModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Lỗi khi lấy getAllTodayActivities: $e");
      return [];
    }
  }

  // Trong FirestoreService.dart (phiên bản bạn cung cấp trước đó)
  Future<List<ActivityModel>> getTodayRegisteredActivities(
    String userId,
  ) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final snapshot =
        await _db
            .collection('activities')
            .where(
              'startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

    return snapshot.docs
        .where((doc) {
          // LỌC PHÍA CLIENT
          final data = doc.data();
          // GIẢ ĐỊNH CÓ MỘT TRƯỜNG LÀ ARRAY CHỨA ID CỦA USER ĐÃ ĐĂNG KÝ
          final registered = List<String>.from(data['registeredUserIds'] ?? []);
          return registered.contains(userId);
        })
        .map((doc) => ActivityModel.fromDocument(doc))
        .toList();
  }

  // Hàm getRegistrationsForActivity (để lấy danh sách ai đã đăng ký 1 hoạt động)
  Future<List<ActivityRegistrationModel>> getRegistrationsForActivity(
    String activityId,
  ) async {
    if (activityId.isEmpty) return [];
    try {
      final snapshot =
          await _db
              .collection('activity_registrations')
              .where('activityId', isEqualTo: activityId)
              .get();
      return snapshot.docs
          .map((doc) => ActivityRegistrationModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Lỗi khi lấy getRegistrationsForActivity ($activityId): $e");
      return [];
    }
  }

  // Giả sử bạn có hàm này để lấy chi tiết hoạt động
  Future<DocumentSnapshot> getActivityDoc(String activityId) {
    return _db.collection('activities').doc(activityId).get();
  }

  Future<int> getRegistrationCountForActivity(String activityId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('activity_registrations')
              .where('activityId', isEqualTo: activityId)
              .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Lỗi khi đếm số lượng đăng ký: $e');
      return 0;
    }
  }
}
