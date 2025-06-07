import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/services/firestore_service.dart'; // Đảm bảo đường dẫn

class ActivityCard extends StatefulWidget {
  final DocumentSnapshot doc; // DocumentSnapshot của activity
  final Future<void> Function(String activityId) onRegisterCallback; // BẮT BUỘC
  final Future<void> Function(String activityId)
  onUnregisterCallback; // BẮT BUỘC
  final bool isInitiallyRegistered;
  final String currentUserId;

  const ActivityCard({
    Key? key,
    required this.doc,
    required this.onRegisterCallback,
    required this.onUnregisterCallback,
    required this.isInitiallyRegistered,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  late bool _isRegistered; // Trạng thái đăng ký nội bộ của card
  bool _isLoadingAction = false; // Để hiển thị loading trên nút khi đang xử lý
  final FirestoreService _firestoreService =
      FirestoreService(); // Để kiểm tra lại state

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.isInitiallyRegistered;
  }

  @override
  void didUpdateWidget(covariant ActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInitiallyRegistered != oldWidget.isInitiallyRegistered &&
        widget.isInitiallyRegistered != _isRegistered) {
      if (mounted) {
        setState(() {
          _isRegistered = widget.isInitiallyRegistered;
        });
      }
    }
  }

  String formatTimestamp(
    Timestamp timestamp, {
    String format = 'HH:mm dd/MM/yyyy',
  }) {
    return DateFormat(format, 'vi_VN').format(timestamp.toDate().toLocal());
  }

  Future<void> _handleRegistration(
    String activityId,
    String activityTitle,
  ) async {
    if (_isLoadingAction) return;
    if (mounted) setState(() => _isLoadingAction = true);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận đăng ký'),
          content: Text(
            'Bạn có chắc chắn muốn đăng ký hoạt động "$activityTitle"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Có',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await widget.onRegisterCallback(activityId);
        // Sau khi callback thành công, kiểm tra lại trạng thái thực tế từ DB
        bool nowRegistered = await _firestoreService
            .isUserRegisteredForActivity(widget.currentUserId, activityId);
        if (mounted) {
          setState(() {
            _isRegistered = nowRegistered;
          });
        }
      } catch (e) {
        // Lỗi đã được xử lý ở SearchScreen (SnackBar)
        print("ActivityCard: Lỗi khi thực hiện onRegisterCallback: $e");
        // Kiểm tra lại trạng thái để đảm bảo UI đúng nếu callback thất bại
        bool currentStatus = await _firestoreService
            .isUserRegisteredForActivity(widget.currentUserId, activityId);
        if (mounted) {
          setState(() {
            _isRegistered = currentStatus;
          });
        }
      }
    }
    if (mounted) setState(() => _isLoadingAction = false);
  }

  Future<void> _handleUnregistration(String activityId) async {
    if (_isLoadingAction) return;
    if (mounted) setState(() => _isLoadingAction = true);

    try {
      // Dialog xác nhận hủy nằm trong onUnregisterCallback (ở SearchScreen)
      await widget.onUnregisterCallback(activityId);
      // Sau khi callback thành công (người dùng đã xác nhận "Có" VÀ Firestore xử lý xong)
      // kiểm tra lại trạng thái thực tế từ DB
      bool stillRegistered = await _firestoreService
          .isUserRegisteredForActivity(widget.currentUserId, activityId);
      if (mounted) {
        setState(() {
          _isRegistered = stillRegistered;
        });
      }
    } catch (e) {
      // Nếu người dùng chọn "Không" hủy, onUnregisterCallback ở SearchScreen sẽ throw "UserCancelledUnregistration"
      // Hoặc nếu có lỗi thực sự khi hủy trên Firestore.
      print("ActivityCard: Lỗi hoặc hủy bỏ từ onUnregisterCallback: $e");
      // Kiểm tra lại trạng thái để đảm bảo UI đúng
      bool currentStatus = await _firestoreService.isUserRegisteredForActivity(
        widget.currentUserId,
        activityId,
      );
      if (mounted) {
        setState(() {
          _isRegistered = currentStatus;
        });
      }
    }
    if (mounted) setState(() => _isLoadingAction = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data()! as Map<String, dynamic>;
    final String activityId = widget.doc.id;

    final title = data['title'] ?? 'Chưa có tiêu đề';
    final Timestamp? startTime =
        data['startTime'] as Timestamp?; // Giả định model trả về Timestamp
    final Timestamp? registrationDeadline =
        data['registrationDeadline'] as Timestamp?;
    final location = data['location'] ?? 'Chưa cập nhật';
    final int maxParticipants = data['maxParticipants'] ?? 0;
    final int currentRegistrations =
        data['currentRegistrations'] ??
        0; // Sẽ tự cập nhật khi StreamBuilder cha rebuild
    final dynamic ctxhPoints = data['socialWorkPoints'] ?? 'N/A';
    final dynamic renLuyenPoints = data['trainingPoints'] ?? 'N/A';

    bool isGenerallyFull =
        maxParticipants > 0 && currentRegistrations >= maxParticipants;
    bool isGenerallyDeadlinePassed =
        registrationDeadline != null &&
        registrationDeadline.toDate().isBefore(DateTime.now());

    // --- Logic cho Bookmark ---
    String bookmarkTextValue;
    IconData bookmarkIconValue;
    Color bookmarkColorValue;

    if (_isRegistered) {
      bookmarkTextValue = "Đã đăng ký";
      bookmarkIconValue = Icons.check_circle_outline;
      bookmarkColorValue = Colors.blue.shade700; // Xanh biển
    } else if (isGenerallyFull) {
      bookmarkTextValue = "Full";
      bookmarkIconValue = Icons.lock_outline;
      bookmarkColorValue = Colors.red.shade700;
    } else if (isGenerallyDeadlinePassed) {
      bookmarkTextValue = "Hết hạn ĐK";
      bookmarkIconValue = Icons.timer_off_outlined;
      bookmarkColorValue = Colors.orange.shade700;
    } else {
      bookmarkTextValue = "Còn slot";
      bookmarkIconValue = Icons.lock_open_outlined;
      bookmarkColorValue = Colors.green.shade700;
    }
    // --- Kết thúc Logic Bookmark ---

    // --- Logic cho các nút ---
    bool canAttemptRegister =
        !isGenerallyFull &&
        !isGenerallyDeadlinePassed; // Điều kiện cơ bản để có thể đăng ký
    bool canAttemptUnregister =
        !isGenerallyDeadlinePassed; // Điều kiện cơ bản để có thể hủy

    Widget registerButton = ElevatedButton.icon(
      icon:
          _isLoadingAction && !_isRegistered
              ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.app_registration_outlined, size: 18),
      label: const Text('Đăng ký'),
      onPressed:
          (_isRegistered || !canAttemptRegister || _isLoadingAction)
              ? null // Disable nếu đã ĐK, hoặc không thể ĐK, hoặc đang loading
              : () => _handleRegistration(activityId, title),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            (_isRegistered || !canAttemptRegister)
                ? Colors.grey.shade400
                : Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );

    Widget? unregisterButton;
    if (_isRegistered) {
      unregisterButton = ElevatedButton.icon(
        icon:
            _isLoadingAction && _isRegistered
                ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('Hủy ĐK'),
        onPressed:
            (!canAttemptUnregister || _isLoadingAction)
                ? null // Disable nếu đã qua hạn hủy hoặc đang loading
                : () => _handleUnregistration(activityId),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              !canAttemptUnregister
                  ? Colors.grey.shade400
                  : Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Card(
      // ... (Giữ nguyên UI của Card: margin, elevation, shape, clipBehavior)
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Theme.of(context).primaryColorLight.withOpacity(0.7),
          width: 0.7,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                const SizedBox(height: 12),
                if (startTime != null)
                  _buildInfoRow(
                    Icons.event_note_outlined,
                    'Diễn ra: ${formatTimestamp(startTime)}',
                    Colors.teal.shade600,
                  ),
                if (registrationDeadline != null)
                  _buildInfoRow(
                    Icons.timer,
                    'Hạn ĐK: ${formatTimestamp(registrationDeadline, format: 'dd/MM/yyyy')}',
                    Colors.orange.shade800,
                  ),
                _buildInfoRow(
                  Icons.location_city,
                  'Địa điểm: $location',
                  Colors.blue.shade700,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPointInfo(
                      Icons.stars_outlined,
                      '$ctxhPoints CTXH',
                      Colors.purple.shade600,
                    ),
                    _buildPointInfo(
                      Icons.verified_user_outlined,
                      '$renLuyenPoints R.Luyện',
                      Colors.amber.shade900,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    registerButton, // Nút đăng ký luôn hiển thị
                    if (unregisterButton != null) ...[
                      // Nếu có nút hủy (tức là đã đăng ký)
                      const SizedBox(width: 8),
                      unregisterButton,
                    ],
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            // Bookmark
            top: 0,
            right: 0,
            child: Container(
              // ... (UI Bookmark giữ nguyên)
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bookmarkColorValue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(-1, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(bookmarkIconValue, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    bookmarkTextValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    /* ... Giữ nguyên ... */
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointInfo(IconData icon, String text, Color color) {
    /* ... Giữ nguyên ... */
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
