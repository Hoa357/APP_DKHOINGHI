import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String activityType;
  final String title;
  final String content;
  final String diadiem;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime registrationDeadline;
  final int diemCTXH;
  final int diemrl;
  final List<String> images;
  final int maxParticipants;
  final List<dynamic> guests;

  ActivityModel({
    required this.id,
    required this.activityType,
    required this.title,
    required this.content,
    required this.diadiem,
    required this.createdAt,
    required this.startTime,
    required this.registrationDeadline,
    required this.diemCTXH,
    required this.diemrl,
    required this.images,
    required this.maxParticipants,
    required this.guests,
  });

  factory ActivityModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime _timestampToDateTime(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return DateTime.now();
    }

    return ActivityModel(
      id: doc.id,
      title: data['title'] ?? '',
      activityType: data['activityType'] ?? '',
      content: data['description'] ?? '',
      diadiem: data['location'] ?? '',
      createdAt: _timestampToDateTime(data['createdAt']),
      startTime: _timestampToDateTime(data['startTime']),
      registrationDeadline: _timestampToDateTime(data['registrationDeadline']),
      diemCTXH: data['socialWorkPoints'] ?? 0,
      diemrl: data['trainingPoints'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      maxParticipants: data['maxParticipants'] ?? 0,
      guests: List.from(data['guests'] ?? []),
    );
  }
}
