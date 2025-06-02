// lib/models/activity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String title;
  final String location;
  final Timestamp startTime;
  final String activityType;

  ActivityModel({
    required this.id,
    required this.title,
    required this.location,
    required this.startTime,
    required this.activityType,
  });

  factory ActivityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data()!;
    return ActivityModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Chưa có tiêu đề',
      location: data['location'] as String? ?? 'Chưa có địa điểm',
      startTime: data['startTime'] as Timestamp? ?? Timestamp.now(),
      activityType: data['activityType'] as String? ?? 'Không xác định',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'location': location,
      'startTime': startTime,
      'activityType': activityType,
    };
  }
}
