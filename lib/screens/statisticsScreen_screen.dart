import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  // Dữ liệu tạm: ngày - số lượng hoạt động đã đăng ký
  Map<String, int> getMockStatistics() {
    return {'2025-06-01': 2, '2025-06-02': 1, '2025-06-03': 3};
  }

  @override
  Widget build(BuildContext context) {
    final stats = getMockStatistics();

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê hoạt động đã đăng ký')),
      body: ListView.builder(
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final date = stats.keys.elementAt(index);
          final count = stats[date];

          return ListTile(
            leading: const Icon(Icons.event_note),
            title: Text('Ngày: $date'),
            subtitle: Text('Số hoạt động đã đăng ký: $count'),
          );
        },
      ),
    );
  }
}
