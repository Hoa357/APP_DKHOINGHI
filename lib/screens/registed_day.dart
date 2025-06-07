import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/models/activity_model.dart'; // Cập nhật đường dẫn nếu cần
import 'package:ungdungflutter/screens/activity_DetailPage.dart'; // Cập nhật đường dẫn nếu cần

// 1. Sửa TodayEventsNotifierButton để nhận currentUserId
class TodayEventsNotifierButton extends StatelessWidget {
  final List<ActivityModel> todayEvents;
  final String buttonText;
  final String currentUserId; // << THÊM DÒNG NÀY

  const TodayEventsNotifierButton({
    Key? key,
    required this.todayEvents,
    this.buttonText = "Sự kiện Hôm Nay",
    required this.currentUserId, // << THÊM VÀO CONSTRUCTOR
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (todayEvents.isEmpty) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text("Thông báo"),
                  content: const Text(
                    "Không có sự kiện nào được đăng ký hôm nay.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đóng"),
                    ),
                  ],
                ),
          );
        } else {
          showDialog(
            context: context,
            builder:
                (context) => _EventsCarouselDialog(
                  todayEvents: todayEvents,
                  currentUserId:
                      currentUserId, // << TRUYỀN currentUserId XUỐNG DIALOG
                ),
          );
        }
      },
      child: Text(buttonText),
    );
  }
}

// 2. Sửa _EventsCarouselDialog để nhận currentUserId
class _EventsCarouselDialog extends StatefulWidget {
  final List<ActivityModel> todayEvents;
  final String currentUserId; // << THÊM DÒNG NÀY

  const _EventsCarouselDialog({
    Key? key,
    required this.todayEvents,
    required this.currentUserId, // << THÊM VÀO CONSTRUCTOR
  }) : super(key: key);

  @override
  _EventsCarouselDialogState createState() => _EventsCarouselDialogState();
}

class _EventsCarouselDialogState extends State<_EventsCarouselDialog> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  final DateFormat _dateTimeFormatter = DateFormat('HH:mm, dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.todayEvents.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (!mounted) return;
        _currentPage = (_currentPage + 1) % widget.todayEvents.length;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Sự kiện đã đăng ký hôm nay",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 180,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.todayEvents.length,
          itemBuilder: (context, index) {
            final event = widget.todayEvents[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 8.0,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Thời gian: ${_dateTimeFormatter.format(event.startTime)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Đóng dialog trước
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ActivityDetailPage(
                                    docId: event.id,
                                    // 3. Sử dụng widget.currentUserId để truyền vào ActivityDetailPage
                                    currentUserId:
                                        widget.currentUserId, // << SỬA Ở ĐÂY
                                  ),
                            ),
                          );
                        },
                        child: const Text("Chi tiết"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Đóng"),
        ),
      ],
    );
  }
}
