import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/models/notification_model.dart';

class ActivitiesDetailPage extends StatefulWidget {
  final String docId;

  const ActivitiesDetailPage({super.key, required this.docId});

  @override
  State<ActivitiesDetailPage> createState() => _ActivitiesDetailPageState();
}

class _ActivitiesDetailPageState extends State<ActivitiesDetailPage> {
  NotificationModel? notification;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('activities')
            .doc(widget.docId)
            .get();

    if (doc.exists) {
      setState(() {
        notification = NotificationModel.fromDocument(doc);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || notification == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết thông báo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final formattedCreatedAt = DateFormat(
      'dd/MM/yyyy',
    ).format(notification!.createdAt);
    final formattedStartTime = DateFormat(
      'dd/MM/yyyy – HH:mm',
    ).format(notification!.startTime);
    final formattedDeadline = DateFormat(
      'dd/MM/yyyy – HH:mm',
    ).format(notification!.registrationDeadline);
    final int currentRegistrations = notification!.guests.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết thông báo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification!.images.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    notification!.images[0],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                notification!.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _infoIcon(Icons.calendar_today, 'Tạo: $formattedCreatedAt'),
                  _infoIcon(Icons.access_time, 'Bắt đầu: $formattedStartTime'),
                  _infoIcon(Icons.timer_off, 'Hạn đăng ký: $formattedDeadline'),
                  _infoIcon(
                    Icons.location_on,
                    'Địa điểm: ${notification!.diadiem}',
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                notification!.content.isNotEmpty
                    ? notification!.content
                    : 'Không có nội dung',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _iconText(
                    Icons.star,
                    'CTXH: ${notification!.diemCTXH}',
                    Colors.orange,
                  ),
                  const SizedBox(width: 24),
                  _iconText(
                    Icons.verified_user,
                    'Rèn luyện: ${notification!.diemrl}',
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _iconText(
                    Icons.people,
                    'Đã đăng ký: $currentRegistrations/${notification!.maxParticipants}',
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    notification!.maxParticipants > 0
                        ? currentRegistrations / notification!.maxParticipants
                        : 0,
                backgroundColor: Colors.grey[300],
                color: Colors.green,
                minHeight: 8,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _infoIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}
