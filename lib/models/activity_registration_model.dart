import 'package:cloud_firestore/cloud_firestore.dart';

enum ParticipationStatus {
  pendingApproval,
  registered,
  checkedIn,
  absent,
  cancelled,
}

class ActivityRegistrationModel {
  final String id;
  final String userId;
  final String activityId;
  final Timestamp registerTime;
  final Timestamp? endTime; // Nullable để hỗ trợ giá trị mặc định
  final ParticipationStatus status;
  final Timestamp? checkInTime;
  final String? updatedBy;

  ActivityRegistrationModel({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.registerTime,
    this.endTime,
    required this.status,
    this.checkInTime,
    this.updatedBy,
  });

  factory ActivityRegistrationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityRegistrationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      activityId: data['activityId'] ?? '',
      registerTime: data['registerTime'] ?? Timestamp.now(),
      endTime: data['endTime'],
      status: ParticipationStatus.values.firstWhere(
        (e) => e.toString() == 'ParticipationStatus.${data['status']}',
        orElse: () => ParticipationStatus.registered,
      ),
      checkInTime: data['checkInTime'],
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'activityId': activityId,
      'registerTime': registerTime,
      'endTime': endTime,
      'status': status.toString().split('.').last,
      'checkInTime': checkInTime,
      'updatedBy': updatedBy,
    };
  }
}
