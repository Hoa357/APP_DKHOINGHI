import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/services/firestore_service.dart'; // Đảm bảo đường dẫn đúng
import 'package:ungdungflutter/widgets/activityCard.dart'; // Đảm bảo đường dẫn đúng

class SearchScreen extends StatefulWidget {
  final String userId;
  final bool showBackButton;

  const SearchScreen({
    Key? key,
    required this.userId,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Tất cả';

  // KHAI BÁO FirestoreService và Cache
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, bool> _registrationStatusCache = {};

  @override
  void initState() {
    super.initState();
    // Không cần làm gì đặc biệt ở đây nữa nếu cache được xử lý trong FutureBuilder
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _registrationStatusCache.clear(); // XÓA CACHE KHI ĐỔI NGÀY
      });
    }
  }

  // HÀM CALLBACK ĐĂNG KÝ (SẼ ĐƯỢC TRUYỀN XUỐNG ActivityCard)
  Future<void> registerForActivityCallback(String activityId) async {
    // Dialog xác nhận đăng ký đã được xử lý bên trong ActivityCard (_handleRegistration)
    try {
      await _firestoreService.registerForActivity(widget.userId, activityId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
        // Cập nhật cache và ActivityCard sẽ tự cập nhật state nội bộ của nó
        _registrationStatusCache[activityId] = true;
        // Gọi setState ở đây nếu bạn muốn SearchScreen rebuild ngay lập tức
        // để FutureBuilder có thể đọc giá trị cache mới ngay.
        // Tuy nhiên, ActivityCard đã có logic tự cập nhật _isRegistered.
        // Nếu bạn thấy UI không cập nhật ngay, có thể thêm setState({}) ở đây.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng ký thất bại: ${e.toString()}')),
        );
      }
      throw e; // Ném lại lỗi để ActivityCard có thể bắt và không thay đổi state sai
    }
  }

  // HÀM CALLBACK HỦY ĐĂNG KÝ (SẼ ĐƯỢC TRUYỀN XUỐNG ActivityCard)
  Future<void> unregisterFromActivityCallback(String activityId) async {
    // Dialog xác nhận hủy sẽ nằm ở ĐÂY (trong SearchScreen)
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận hủy đăng ký'),
          content: const Text(
            'Bạn có chắc chắn muốn hủy đăng ký hoạt động này?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Không'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text(
                'Có',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _firestoreService.unregisterFromActivity(
          widget.userId,
          activityId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy đăng ký thành công.')),
          );
          _registrationStatusCache[activityId] = false;
          // ActivityCard sẽ tự cập nhật state nội bộ của nó
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hủy đăng ký thất bại: ${e.toString()}')),
          );
        }
        throw e; // Ném lại lỗi
      }
    } else {
      print("Người dùng đã chọn KHÔNG hủy đăng ký.");
      // Ném lỗi để ActivityCard biết và không thay đổi trạng thái _isRegistered
      throw Exception("UserCancelledUnregistration");
    }
  }

  // Hàm formatTimestamp không còn dùng trực tiếp trong SearchScreen nếu ActivityCard tự format
  // String formatTimestamp(Timestamp timestamp, {String format = 'dd/MM/yyyy HH:mm'}) {
  //   final date = timestamp.toDate();
  //   return DateFormat(format).format(date.toLocal());
  // }

  Widget _buildCategoryDrawer() {
    // ... (Giữ nguyên code của bạn)
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 120,
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorDark,
            ),
            alignment: Alignment.bottomLeft,
            child: const Text(
              'CHỌN DANH MỤC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(Icons.apps_outlined, 'Tất cả', 'Tất cả'),
          _buildDrawerItem(
            Icons.groups_2_outlined,
            'Hoạt động đoàn',
            'Hoạt động đoàn',
          ),
          _buildDrawerItem(
            Icons.school_outlined,
            'Hoạt động khoa',
            'Hoạt động khoa',
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, String category) {
    // ... (Giữ nguyên code của bạn)
    bool isSelected = _selectedCategory == category;
    return ListTile(
      leading: Icon(
        icon,
        color:
            isSelected
                ? Theme.of(context).colorScheme.secondary
                : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.secondary.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedCategory = category;
          // Khi đổi category, cũng nên cân nhắc xóa cache vì danh sách hoạt động có thể thay đổi
          // _registrationStatusCache.clear(); // Tùy chọn: xóa cache khi đổi category
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildDatePickerButton(BuildContext context) {
    // ... (Giữ nguyên code của bạn)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedCategory == 'Tất cả'
                ? "Hoạt động trong ngày:"
                : "Sự kiện ${(_selectedCategory.split(' ').last).toLowerCase()} ngày:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          TextButton.icon(
            icon: Icon(
              Icons.calendar_month_outlined,
              color: Theme.of(context).primaryColorDark,
              size: 22,
            ),
            label: Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _selectDate(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Theme.of(
                context,
              ).primaryColorLight.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Query Firestore dựa trên ngày đã chọn
    Query activitiesQuery = FirebaseFirestore.instance
        .collection('activities')
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            _startOfDay(_selectedDate),
          ),
        )
        .where(
          'startTime',
          isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(_selectedDate)),
        )
        .orderBy('startTime', descending: false);
    // Cân nhắc thêm .where('status', isEqualTo: true) nếu bạn có trường status cho activity

    return Scaffold(
      appBar: AppBar(
        // ... (Giữ nguyên AppBar của bạn)
        leading:
            widget.showBackButton && Navigator.canPop(context)
                ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
        title: const Text(
          'HOẠT ĐỘNG',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.filter_list_alt, color: Colors.white),
                  tooltip: 'Lọc danh mục',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
          ),
        ],
      ),
      endDrawer: _buildCategoryDrawer(),
      body: Column(
        children: [
          _buildDatePickerButton(context),
          const Divider(height: 1, thickness: 0.7, indent: 16, endIndent: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: activitiesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Lỗi StreamBuilder: ${snapshot.error}");
                  return Center(
                    child: Text(
                      'Lỗi khi tải dữ liệu: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs;
                if (docs == null || docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Không có hoạt động nào diễn ra vào ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                List<DocumentSnapshot> filteredDocs = List.from(docs);

                // Lọc client-side (hạn đăng ký và category)
                filteredDocs.retainWhere((doc) {
                  final data = doc.data()! as Map<String, dynamic>;
                  final Timestamp? registrationDeadline =
                      data['registrationDeadline'] as Timestamp?;
                  // Lọc bỏ những hoạt động đã qua hạn đăng ký (so với đầu ngày hiện tại)
                  // ActivityCard sẽ có logic chi tiết hơn để disable nút dựa trên DateTime.now()
                  bool isRegistrationPeriodOver =
                      registrationDeadline != null &&
                      registrationDeadline.toDate().isBefore(
                        _startOfDay(DateTime.now()),
                      );
                  if (isRegistrationPeriodOver) return false;

                  if (_selectedCategory != 'Tất cả') {
                    final activityType = data['activityType'] as String?;
                    if (_selectedCategory == 'Hoạt động đoàn')
                      return activityType == 'truong';
                    if (_selectedCategory == 'Hoạt động khoa')
                      return activityType == 'khoa';
                    return false;
                  }
                  return true;
                });

                if (filteredDocs.isEmpty) {
                  String message =
                      'Không có hoạt động "$_selectedCategory" nào (còn hạn đăng ký)\nvào ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)}.';
                  if (_selectedCategory == 'Tất cả') {
                    message =
                        'Không có hoạt động nào (còn hạn đăng ký)\nvào ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)}.';
                  }
                  return Center(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 70.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final activityId = doc.id;

                    return FutureBuilder<bool>(
                      key: ValueKey(activityId + widget.userId),
                      future:
                          _registrationStatusCache.containsKey(activityId)
                              ? Future.value(
                                _registrationStatusCache[activityId]!,
                              )
                              : _firestoreService
                                  .isUserRegisteredForActivity(
                                    widget.userId,
                                    activityId,
                                  )
                                  .then((status) {
                                    if (mounted) {
                                      _registrationStatusCache[activityId] =
                                          status;
                                    }
                                    return status;
                                  }),
                      builder: (context, isRegisteredSnapshot) {
                        bool isInitiallyRegistered =
                            _registrationStatusCache[activityId] ?? false;
                        if (isRegisteredSnapshot.connectionState ==
                                ConnectionState.done &&
                            isRegisteredSnapshot.hasData) {
                          isInitiallyRegistered = isRegisteredSnapshot.data!;
                        }
                        // Nếu isRegisteredSnapshot đang waiting và chưa có trong cache,
                        // isInitiallyRegistered sẽ là giá trị mặc định (false).
                        // ActivityCard sẽ hiển thị trạng thái "chưa đăng ký" tạm thời.

                        return ActivityCard(
                          doc: doc,
                          onRegisterCallback: registerForActivityCallback,
                          onUnregisterCallback: unregisterFromActivityCallback,
                          isInitiallyRegistered: isInitiallyRegistered,
                          currentUserId: widget.userId,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
