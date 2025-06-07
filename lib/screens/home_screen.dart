import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // Vẫn cần cho lần lấy user ban đầu nếu không dùng UserService
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/models/activity_model.dart';

// Models
import 'package:ungdungflutter/models/user_models.dart'; // Đảm bảo đây là user_model.dart không phải user_models.dart
import 'package:ungdungflutter/screens/StatisticsScreen_screen.dart';


// Screens for navigation
import 'package:ungdungflutter/screens/notification.dart'; // Trang thông báo chung
import 'package:ungdungflutter/screens/registed_activity.dart';
import 'package:ungdungflutter/screens/registed_day.dart';
import 'package:ungdungflutter/screens/search_Screen.dart';


// Services
import 'package:ungdungflutter/services/firestore_service.dart';
import 'package:ungdungflutter/services/user_services.dart'; // Dịch vụ lấy thông tin người dùng

// Widgets

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel?
  _currentUser; // Thông tin người dùng hiện tại (UserModel từ user_services)
  bool _isLoadingUserAndRegisteredActivities = true;
  List<ActivityModel> _registeredTodayActivities = [];

  PageController? _registeredActivitiesPageController;
  int _currentRegisteredActivityPage = 0;
  Timer? _registeredActivitiesPageTimer;

  List<ActivityModel> _allTodayEvents =
      []; // Tất cả sự kiện hôm nay (không lọc theo người dùng)
  bool _isLoadingAllEvents = true; // Still used for endDrawer logic

  final DateFormat timeFormatter = DateFormat.Hm(); // HH:mm
  final String _notificationBoardAsset = 'assets/images/notification_board.png';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadAllTodayEventsData();
  }

  @override
  void dispose() {
    _registeredActivitiesPageController?.dispose();
    _registeredActivitiesPageTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUserAndRegisteredActivities = true;
    });

    // Lấy thông tin người dùng từ UserService
    final userModel =
        await UserService.getCurrentUser(); // Nên dùng hàm trả về UserModel
    if (userModel != null) {
      final activities = await _firestoreService.getTodayRegisteredActivities(
        userModel.uid,
      );
      if (mounted) {
        setState(() {
          _currentUser = userModel;
          _registeredTodayActivities = activities;
          _isLoadingUserAndRegisteredActivities = false;
        });
        _startRegisteredActivitiesAutoSlide();
      }
    } else {
      // Không có người dùng đăng nhập
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
    if (!mounted) return;
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

  void _startRegisteredActivitiesAutoSlide() {
    _registeredActivitiesPageTimer?.cancel(); // Hủy timer cũ nếu có

    if (_registeredTodayActivities.length > 1) {
      _registeredActivitiesPageController ??=
          PageController(); // Khởi tạo nếu chưa có
      if (_registeredActivitiesPageController!.hasClients &&
          _currentRegisteredActivityPage >= _registeredTodayActivities.length) {
        _currentRegisteredActivityPage =
            0; // Reset nếu trang hiện tại không hợp lệ
      }
      if (_registeredActivitiesPageController!.hasClients &&
          _registeredActivitiesPageController!.page?.round() !=
              _currentRegisteredActivityPage) {
        _registeredActivitiesPageController!.jumpToPage(
          _currentRegisteredActivityPage,
        );
      }

      _registeredActivitiesPageTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) {
          if (!mounted ||
              _registeredActivitiesPageController == null ||
              !_registeredActivitiesPageController!.hasClients ||
              _registeredTodayActivities.length <= 1) {
            return;
          }
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
    } else {
      // Nếu chỉ có 1 hoặc 0 sự kiện, không cần tự động trượt
      _currentRegisteredActivityPage = 0;
      if (_registeredActivitiesPageController != null &&
          _registeredActivitiesPageController!.hasClients &&
          _registeredActivitiesPageController!.page != 0) {
        _registeredActivitiesPageController!.jumpToPage(0);
      }
    }
  }

  Widget _buildHeader(BuildContext context) {
    Color headerBlue = Theme.of(context).primaryColor;
    if (headerBlue == Theme.of(context).scaffoldBackgroundColor ||
        headerBlue == Colors.transparent) {
      headerBlue = Colors.blue.shade700;
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
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayRegisteredActivitiesCard() {
    if (_isLoadingUserAndRegisteredActivities) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          height: 130, // Chiều cao tương đối
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: const Text("Vui lòng đăng nhập để xem hoạt động đã đăng ký."),
        ),
      );
    }

    if (_registeredTodayActivities.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Image.asset(
                _notificationBoardAsset,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Bạn không có hoạt động nào đã đăng ký cho hôm nay.",
                  style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 140, // Tăng chiều cao một chút
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hoạt động đã đăng ký hôm nay:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PageView.builder(
                controller: _registeredActivitiesPageController,
                itemCount: _registeredTodayActivities.length,
                onPageChanged: (index) {
                  if (mounted) {
                    setState(() {
                      _currentRegisteredActivityPage = index;
                    });
                  }
                },
                itemBuilder: (context, index) {
                  final activity = _registeredTodayActivities[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Thời gian: ${timeFormatter.format(activity.startTime)}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_registeredTodayActivities.length >
                1) // Chỉ hiển thị dots nếu có nhiều hơn 1 item
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _registeredTodayActivities.length,
                  (index) => Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 2.0,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentRegisteredActivityPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // MODIFIED FUNCTION
  Widget _buildMainActionButtons(BuildContext context, String currentUserId) {
    // The "Xem tất cả" button and its logic have been removed.
    // It's replaced by a static "Chức Năng" label with an icon.
    Widget chucNangLabel = Row(
      mainAxisSize: MainAxisSize.min, // Keep icon and text close together
      children: [
        Icon(
          Icons.widgets_outlined, // Icon for "Chức Năng"
          size: 22,
          color:
              Theme.of(
                context,
              ).primaryColorDark, // Or Theme.of(context).primaryColor
        ),
        const SizedBox(width: 6),
        Text(
          "Chức Năng",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(
                  context,
                ).primaryColorDark, // Or Theme.of(context).primaryColor
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Center(
              child: chucNangLabel, // Displaying the new "Chức Năng" label
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: TextButton.icon(
                icon: Icon(
                  Icons.filter_list,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                label: Text(
                  "Lọc tìm kiếm",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  if (currentUserId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SearchScreen(userId: currentUserId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Vui lòng đăng nhập để sử dụng chức năng tìm kiếm.",
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityCircularButtons(
    BuildContext context,
    String currentUserId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCircularButton(
            context,
            icon: Icons.bar_chart_rounded,
            label: "Thống kê",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
          ),
          _buildCircularButton(
            context,
            icon: Icons.checklist_rtl_rounded,
            label: "Đã ĐK",
            onPressed: () {
              if (currentUserId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            MyRegisteredActivitiesScreen(userId: currentUserId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Vui lòng đăng nhập để xem các hoạt động đã đăng ký.",
                    ),
                  ),
                );
              }
            },
          ),
          _buildCircularButton(
            context,
            icon: Icons.school_outlined,
            label: "Học tập",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chức năng Học tập!")),
              );
            },
          ),
          _buildCircularButton(
            context,
            icon: Icons.more_horiz_rounded,
            label: "Khác",
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Chức năng Khác!")));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 28, color: Theme.of(context).primaryColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      endDrawer:
          (currentUserId.isNotEmpty &&
                  !_isLoadingAllEvents && // Ensure events are loaded before showing drawer
                  _allTodayEvents.isNotEmpty)
              ? TodayEventsNotifierButton(
                todayEvents: _allTodayEvents,
                currentUserId: currentUserId,
                buttonText: "Sự kiện hôm nay (${_allTodayEvents.length})",
              )
              : (_isLoadingAllEvents // Show a loading indicator in drawer if events are loading
                  ? const Drawer(
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : (currentUserId.isEmpty
                      ? const Drawer(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "Vui lòng đăng nhập để xem sự kiện.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                      : const Drawer(
                        // Case: logged in, not loading, but no events
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "Không có sự kiện nào hôm nay.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ))),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
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
                    const Divider(height: 24, thickness: 1),
                    _buildMainActionButtons(context, currentUserId),
                    const Divider(height: 1, thickness: 0.5),
                    _buildUtilityCircularButtons(context, currentUserId),
                    const Divider(height: 24, thickness: 1),
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
