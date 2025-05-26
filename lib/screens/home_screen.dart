import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      'title': 'Thông báo: Seminar AI ngày 30/05',
      'date': '28/05/2025',
    },
    {
      'title': 'Thông báo: Cuộc thi Sáng tạo KHKT',
      'date': '20/05/2025',
    },
  ];

  final List<Map<String, String>> featuredActivities = [
    {
      'name': 'Seminar AI & Machine Learning',
      'date': '30/05/2025',
      'location': 'Phòng 101 - Nhà A',
    },
    {
      'name': 'Cuộc thi Sáng tạo Khoa học',
      'date': '15/06/2025',
      'location': 'Hội trường B',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông báo mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...notifications.map((noti) => Card(
            child: ListTile(
              leading: Icon(Icons.notification_important, color: Colors.red),
              title: Text(noti['title']!),
              subtitle: Text('Ngày: ${noti['date']}'),
            ),
          )).toList(),
          SizedBox(height: 24),
          Text('Hoạt động nổi bật', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...featuredActivities.map((act) => Card(
            child: ListTile(
              leading: Icon(Icons.event, color: Colors.blue),
              title: Text(act['name']!),
              subtitle: Text('${act['date']} - ${act['location']}'),
            ),
          )).toList(),
        ],
      ),
    );
  }
}
