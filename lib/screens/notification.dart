import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/models/notification_model.dart';
import 'package:ungdungflutter/screens/notification_detail_sreen.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('activities')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có thông báo nào'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final notif = NotificationModel.fromDocument(doc);
              final formattedDate = DateFormat(
                'dd/MM/yyyy',
              ).format(notif.createdAt);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => NotificationDetailPage(docId: doc.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề và địa điểm
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            Text(
                              notif.diadiem,
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Nội dung ngắn
                        Text(
                          notif.content,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 8),

                        // Thông tin điểm và ngày
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Chip(
                                  label: Text("CTXH: ${notif.diemCTXH}"),
                                  backgroundColor: Colors.blue.shade50,
                                  labelStyle: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text("RL: ${notif.diemrl}"),
                                  backgroundColor: Colors.green.shade50,
                                  labelStyle: const TextStyle(
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
