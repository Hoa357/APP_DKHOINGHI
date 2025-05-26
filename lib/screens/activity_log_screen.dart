import 'package:flutter/material.dart';

class ActivityLogScreen extends StatelessWidget {
  final List<Map<String, String>> registeredActivities = [
    {
      'name': 'Seminar AI & Machine Learning',
      'status': 'Đã tham gia',
      'date': '30/05/2025',
    },
    {
      'name': 'Cuộc thi Sáng tạo Khoa học',
      'status': 'Chờ duyệt đề tài',
      'date': '15/06/2025',
    },
    {
      'name': 'Hoạt động đoàn tháng 5',
      'status': 'Vắng mặt',
      'date': '20/05/2025',
    },
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case 'Đã tham gia':
        return Colors.green;
      case 'Chờ duyệt đề tài':
        return Colors.orange;
      case 'Vắng mặt':
        return Colors.red;
      case 'Chờ tham dự':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: registeredActivities.length,
      itemBuilder: (context, index) {
        final activity = registeredActivities[index];
        return Card(
          child: ListTile(
            leading: Icon(Icons.event_note),
            title: Text(activity['name']!),
            subtitle: Text('Ngày: ${activity['date']}'),
            trailing: Text(
              activity['status']!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: getStatusColor(activity['status']!),
              ),
            ),
          ),
        );
      },
    );
  }
}
