import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Models
import 'package:ungdungflutter/models/notification_model.dart';
import 'package:ungdungflutter/models/user_models.dart';

// Screens for navigation
import 'package:ungdungflutter/screens/notification.dart'; // Trang thông báo chung
import 'package:ungdungflutter/screens/notification_detail_sreen.dart'; // Trang chi tiết hoạt động/sự kiện
import 'package:ungdungflutter/screens/all_today_events_screen.dart'; // Trang hiển thị tất cả sự kiện hôm nay

// Services
import 'package:ungdungflutter/services/firestore_service.dart';
import 'package:ungdungflutter/services/user_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final UserService _userService = UserService();

  // User State & Registered Activities State
  UserModel? _currentUser;
  bool _isLoadingUserAndRegisteredActivities = true;
  List<NotificationModel> _registeredTodayActivities = [];

  // PageView controller for registered activities
  PageController? _registeredActivitiesPageController;
  int _currentRegisteredActivityPage = 0;
  Timer? _registeredActivitiesPageTimer;

  // State cho tất cả sự kiện hôm nay (để quyết định hiển thị nút)
  List<NotificationModel> _allTodayEvents = [];
  bool _isLoadingAllEvents = true;

  // Formatters and Assets
  final DateFormat timeFormatter = DateFormat.Hm(); // Format: 10:30
  final String _notificationBoardAsset = 'assets/images/notification_board.png';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadAllTodayEventsData(); // Tải dữ liệu cho nút "Xem tất cả sự kiện"
  }

  @override
  void dispose() {
    _registeredActivitiesPageController?.dispose();
    _registeredActivitiesPageTimer?.cancel();
    super.dispose();
  }

  // --- LOGIC LOADING DATA ---
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingUserAndRegisteredActivities = true;
    });

    final user = await UserService.getCurrentUser();
    if (user != null) {
      final activities = await _firestoreService.getTodayRegisteredActivities(
        user.uid,
      );
      if (mounted) {
        setState(() {
          _currentUser = user;
          _registeredTodayActivities = activities;
          _isLoadingUserAndRegisteredActivities = false;
        });
        _startRegisteredActivitiesAutoSlide();
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingUserAndRegisteredActivities = false;
          _currentUser = null;
          _registeredTodayActivities = [];
        });
      }
    }
  }

  Future<void> _loadAllTodayEventsData() async {
    setState(() {
      _isLoadingAllEvents = true;
    });
    final events = await _firestoreService.getAllTodayActivities();
    if (mounted) {
      setState(() {
        _allTodayEvents = events;
        _isLoadingAllEvents = false;
      });
    }
  }

  // --- LOGIC AUTO SLIDE CHO CARD HOẠT ĐỘNG ĐÃ ĐĂNG KÝ ---
  void _startRegisteredActivitiesAutoSlide() {
    if (_registeredTodayActivities.length > 1) {
      _registeredActivitiesPageController = PageController();
      _registeredActivitiesPageTimer?.cancel();
      _registeredActivitiesPageTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) {
          if (_registeredActivitiesPageController == null ||
              !_registeredActivitiesPageController!.hasClients)
            return;

          _currentRegisteredActivityPage =
              (_currentRegisteredActivityPage + 1) %
              _registeredTodayActivities.length;
          _registeredActivitiesPageController!.animateToPage(
            _currentRegisteredActivityPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      );
    } else if (_registeredActivitiesPageController != null &&
        _registeredTodayActivities.length <= 1) {
      _registeredActivitiesPageTimer?.cancel();
      _registeredActivitiesPageTimer = null;
    }
  }

  // --- BUILD METHODS CHO CÁC PHẦN CỦA UI ---

  Widget _buildHeader(BuildContext context) {
    Color headerBlue = Theme.of(context).primaryColor;
    if (headerBlue == Theme.of(context).scaffoldBackgroundColor ||
        headerBlue == Colors.transparent) {
      headerBlue = Colors.blue.shade700; // Fallback color
    }

    return Container(
      color: headerBlue,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8.0,
        bottom: 16.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child:
                _isLoadingUserAndRegisteredActivities ||
                        _currentUser?.avatarUrl == null ||
                        _currentUser!.avatarUrl!.isEmpty
                    ? Icon(
                      Icons.person,
                      size: 28,
                      color: Colors.white.withOpacity(0.8),
                    )
                    : ClipOval(
                      child: Image.network(
                        _currentUser!.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.white.withOpacity(0.8),
                            ),
                      ),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Xin chào,",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 2),
                _isLoadingUserAndRegisteredActivities
                    ? Container(
                      height: 18,
                      width: 130,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                    : Text(
                      _currentUser?.name ?? 'Người dùng',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              size: 28,
              color: Colors.white,
            ),
            tooltip: "Thông báo",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayRegisteredActivitiesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Image.asset(
                _notificationBoardAsset,
                fit: BoxFit.contain,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.campaign_rounded,
                    size: 60,
                    color: Colors.grey.shade300,
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 90,
              child:
                  _isLoadingUserAndRegisteredActivities
                      ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                      : _registeredTodayActivities.isEmpty
                      ? Center(
                        child: Text(
                          "Không có hoạt động nào bạn đã đăng ký diễn ra hôm nay.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      )
                      : PageView.builder(
                        controller: _registeredActivitiesPageController,
                        scrollDirection: Axis.vertical,
                        itemCount: _registeredTodayActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _registeredTodayActivities[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => NotificationDetailPage(
                                        docId: activity.id,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    activity.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Bắt đầu: ${timeFormatter.format(activity.startTime)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Địa điểm: ${activity.diadiem}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllEventsNavigationButton() {
    // Nếu đang load thì không hiển thị gì cả (hoặc một placeholder nhỏ)
    if (_isLoadingAllEvents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      );
    }

    // Nếu không loading và không có sự kiện nào, hiển thị thông báo

    if (_allTodayEvents.isEmpty && !_isLoadingAllEvents) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            "Hôm nay không có sự kiện",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ), // Đóng Text
        ), // Đóng Center
      ); //
    }
    // Nếu có sự kiện, hiển thị nút
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 20.0),
      child: Center(
        child: OutlinedButton.icon(
          icon: Icon(
            Icons.calendar_month_outlined, // Icon đã thay đổi cho phù hợp hơn
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          label: Text(
            "Xem tất cả sự kiện trong ngày",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            side: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AllTodayEventsScreen(
                      // Nếu AllTodayEventsScreen tự fetch, không cần truyền initialEvents
                      // Nếu AllTodayEventsScreen nhận initialEvents, bạn có thể truyền:
                      // initialEvents: _allTodayEvents,
                    ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Khi kéo làm mới, load lại tất cả dữ liệu cần thiết
                await _loadInitialData();
                await _loadAllTodayEventsData();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayRegisteredActivitiesCard(),
                    _buildAllEventsNavigationButton(), // Nút điều hướng
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
