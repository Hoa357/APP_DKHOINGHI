import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ungdungflutter/models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<NotificationModel>> getTodayRegisteredActivities(
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
          final data = doc.data();
          final registered = List<String>.from(data['registeredUserIds'] ?? []);
          return registered.contains(userId);
        })
        .map((doc) => NotificationModel.fromDocument(doc))
        .toList();
  }

  Future<List<NotificationModel>> getAllTodayActivities() async {
    try {
      DateTime now = DateTime.now();
      // Đặt giờ, phút, giây, mili giây, micro giây về 0 để lấy đầu ngày
      DateTime startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
        0,
        0,
        0,
        0,
        0,
      );
      // Đặt giờ, phút, giây, mili giây, micro giây về giá trị cuối cùng để lấy cuối ngày
      DateTime endOfDay = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
        999,
      );

      Timestamp startOfDayTimestamp = Timestamp.fromDate(startOfDay);
      Timestamp endOfDayTimestamp = Timestamp.fromDate(endOfDay);

      QuerySnapshot snapshot =
          await _db
              .collection('activities')
              .orderBy('startTime') // Đặt orderBy TRƯỚC where
              .where('startTime', isGreaterThanOrEqualTo: startOfDayTimestamp)
              .where('startTime', isLessThanOrEqualTo: endOfDayTimestamp)
              .get();


      List<NotificationModel> activities = [];
      if (snapshot.docs.isNotEmpty) {
        activities =
            snapshot.docs
                .map((doc) => NotificationModel.fromDocument(doc))
                .toList();
      }
      return activities;
    } catch (e) {
      print("=============================================================Error getting all today's activities: $e");

      return [];
    }
  }
}
