import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
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

  NotificationModel({
     required this.id,
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

  // Thêm hàm này:
  factory NotificationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['description'] ?? '',
      diadiem: data['location'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      registrationDeadline:
          (data['registrationDeadline'] as Timestamp).toDate(),
      diemCTXH: data['socialWorkPoints'] ?? 0,
      diemrl: data['trainingPoints'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      maxParticipants: data['maxParticipants'] ?? 0,
      guests: List.from(data['guests'] ?? []),
    );
  }
}
