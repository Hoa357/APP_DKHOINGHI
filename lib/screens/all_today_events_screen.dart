// screens/all_today_events_screen.dart (Ví dụ)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/models/notification_model.dart';
import 'package:ungdungflutter/screens/notification_detail_sreen.dart';
import 'package:ungdungflutter/services/firestore_service.dart'; // Nếu fetch lại

class AllTodayEventsScreen extends StatefulWidget {
  final List<NotificationModel>?
  initialEvents; // Tùy chọn: nhận danh sách đã fetch

  const AllTodayEventsScreen({super.key, this.initialEvents});

  @override
  State<AllTodayEventsScreen> createState() => _AllTodayEventsScreenState();
}

class _AllTodayEventsScreenState extends State<AllTodayEventsScreen> {
  List<NotificationModel> _events = [];
  bool _isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat timeFormatter = DateFormat.Hm();

  @override
  void initState() {
    super.initState();
    if (widget.initialEvents != null && widget.initialEvents!.isNotEmpty) {
      _events = widget.initialEvents!;
      _isLoading = false;
    } else {
      _fetchAllTodayEvents();
    }
  }

  Future<void> _fetchAllTodayEvents() async {
    setState(() => _isLoading = true);
    final fetchedEvents = await _firestoreService.getAllTodayActivities();
    if (mounted) {
      setState(() {
        _events = fetchedEvents;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tất cả sự kiện hôm nay"), elevation: 1),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Không có sự kiện nào diễn ra hôm nay.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors
                            .primaries[index % Colors.primaries.length]
                            .withOpacity(0.2),
                        child: Icon(
                          Icons.event_note_outlined,
                          color:
                              Colors.primaries[index % Colors.primaries.length],
                        ),
                      ),
                      title: Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        "${timeFormatter.format(event.startTime)} tại ${event.diadiem}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => NotificationDetailPage(docId: event.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
