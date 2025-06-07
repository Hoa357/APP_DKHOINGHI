// File: ungdungflutter/pages/activity_detail_page.dart (Tên file đã đổi)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/models/activity_model.dart'; // Đảm bảo đường dẫn đúng
import 'package:ungdungflutter/services/firestore_service.dart'; // Đảm bảo đường dẫn đúng

// ĐỔI TÊN CLASS
class ActivityDetailPage extends StatefulWidget {
  final String docId; // ID của Activity
  final String currentUserId; // ID của người dùng hiện tại

  const ActivityDetailPage({
    // ĐỔI TÊN CONSTRUCTOR
    super.key,
    required this.docId,
    required this.currentUserId,
  });

  @override
  // ĐỔI TÊN STATE CLASS CHO PHÙ HỢP
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

// ĐỔI TÊN STATE CLASS
class _ActivityDetailPageState extends State<ActivityDetailPage> {
  ActivityModel? _activityDetail;
  bool _isLoadingPage = true;
  String _pageErrorMessage = '';

  late bool _isRegistered;
  int _currentRegistrationsCount = 0;
  bool _isLoadingAction = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _isRegistered = false;
    _fetchActivityAndRegistrationStatus();
  }

  Future<void> _fetchActivityAndRegistrationStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPage = true;
      _pageErrorMessage = '';
    });

    try {
      // widget.docId ở đây chính là activityId
      final docSnapshot = await _firestoreService.getActivityDoc(widget.docId);

      if (!mounted) return;

      if (docSnapshot.exists) {
        final activity = ActivityModel.fromDocument(docSnapshot);

        final results = await Future.wait([
          _firestoreService.isUserRegisteredForActivity(
            widget.currentUserId, // Dùng ID của người dùng hiện tại
            widget.docId, // Dùng ID của activity
          ),
          _firestoreService.getRegistrationCountForActivity(
            widget.docId,
          ), // Dùng ID của activity
        ]);

        if (!mounted) return;

        final bool registeredStatus = results[0] as bool;
        final int regCount = results[1] as int;

        setState(() {
          _activityDetail = activity;
          _isRegistered = registeredStatus;
          _currentRegistrationsCount = regCount;
          _isLoadingPage = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _pageErrorMessage = 'Không tìm thấy thông tin chi tiết hoạt động.';
          _isLoadingPage = false;
          _activityDetail = null;
        });
      }
    } catch (e) {
      print("Lỗi khi tải chi tiết hoạt động hoặc trạng thái đăng ký: $e");
      if (!mounted) return;
      setState(() {
        _pageErrorMessage = 'Đã xảy ra lỗi khi tải dữ liệu: ${e.toString()}';
        _isLoadingPage = false;
        _activityDetail = null;
      });
    }
  }

  String _formatTimestamp(
    Timestamp? timestamp, {
    String format = 'HH:mm, dd/MM/yyyy',
  }) {
    if (timestamp == null) return 'N/A';
    return DateFormat(format, 'vi_VN').format(timestamp.toDate().toLocal());
  }

  String _formatLocalDateTime(
    // Giả sử model của bạn dùng DateTime
    DateTime?
    dateTime, { // Thêm ? để xử lý trường hợp registrationDeadline có thể null
    String format = 'HH:mm dd/MM/yyyy',
  }) {
    if (dateTime == null) return 'N/A'; // Xử lý null
    return DateFormat(format, 'vi_VN').format(dateTime.toLocal());
  }

  Future<void> _handleRegistration() async {
    if (_isLoadingAction || _activityDetail == null) return;

    final activity = _activityDetail!;
    final bool isDeadlinePassed =
        activity.registrationDeadline != null &&
        activity.registrationDeadline!.isBefore(
          DateTime.now(),
        ); // Giả sử registrationDeadline là DateTime
    final int maxParticipants = activity.maxParticipants;
    bool isFull =
        maxParticipants > 0 && _currentRegistrationsCount >= maxParticipants;

    if (isDeadlinePassed) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã qua hạn đăng ký.')));
      return;
    }
    if (isFull && !_isRegistered) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hoạt động đã đủ số lượng.')),
        );
      return;
    }

    if (mounted) setState(() => _isLoadingAction = true);

    final String activityId = widget.docId; // Đây là ID của activity
    final String activityTitle = activity.title;

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
        await _firestoreService.registerForActivity(
          widget.currentUserId,
          activityId,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
          await _fetchActivityAndRegistrationStatus();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng ký thất bại: ${e.toString()}')),
          );
        print("ActivityDetailPage: Lỗi khi thực hiện đăng ký: $e");
      }
    }
    if (mounted) setState(() => _isLoadingAction = false);
  }

  Future<void> _handleUnregistration() async {
    if (_isLoadingAction || _activityDetail == null) return;

    if (mounted) setState(() => _isLoadingAction = true);
    final String activityId = widget.docId; // Đây là ID của activity

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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Có',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _firestoreService.unregisterFromActivity(
          widget.currentUserId,
          activityId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy đăng ký thành công.')),
          );
          await _fetchActivityAndRegistrationStatus();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hủy đăng ký thất bại: ${e.toString()}')),
          );
        print("ActivityDetailPage: Lỗi khi thực hiện hủy đăng ký: $e");
      }
    }
    if (mounted) setState(() => _isLoadingAction = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (_isLoadingPage) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đang tải...'),
          backgroundColor: theme.primaryColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_pageErrorMessage.isNotEmpty || _activityDetail == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lỗi'),
          backgroundColor: theme.colorScheme.errorContainer,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: theme.colorScheme.onErrorContainer,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.onErrorContainer),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  _pageErrorMessage.isNotEmpty
                      ? _pageErrorMessage
                      : 'Không có dữ liệu để hiển thị.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  onPressed: _fetchActivityAndRegistrationStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activity = _activityDetail!;

    // Giả định ActivityModel của bạn đã chuyển đổi Timestamp thành DateTime
    // Nếu ActivityModel vẫn giữ Timestamp, dùng _formatTimestamp
    final String formattedStartTime = _formatLocalDateTime(
      activity.startTime,
    ); // Giả sử activity.startTime là DateTime
    final String formattedDeadline = _formatLocalDateTime(
      activity.registrationDeadline,
    ); // Giả sử activity.registrationDeadline là DateTime?
    final String formattedCreatedAt = _formatLocalDateTime(
      activity.createdAt,
    ); // Giả sử activity.createdAt là DateTime

    final int currentRegistrations = _currentRegistrationsCount;
    final int maxParticipants = activity.maxParticipants;

    bool isGenerallyFull =
        maxParticipants > 0 && currentRegistrations >= maxParticipants;
    bool isGenerallyDeadlinePassed =
        activity.registrationDeadline != null &&
        activity.registrationDeadline!.isBefore(
          DateTime.now(),
        ); // Giả sử DateTime

    bool canAttemptRegister = !isGenerallyFull && !isGenerallyDeadlinePassed;
    bool canAttemptUnregister = !isGenerallyDeadlinePassed;

    Widget registerButtonWidget = ElevatedButton.icon(
      icon:
          _isLoadingAction && !_isRegistered
              ? const SizedBox(
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
              ? null
              : _handleRegistration,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            (_isRegistered || !canAttemptRegister)
                ? Colors.grey.shade400
                : theme.colorScheme.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );

    Widget? unregisterButtonWidget;
    if (_isRegistered) {
      unregisterButtonWidget = ElevatedButton.icon(
        icon:
            _isLoadingAction && _isRegistered
                ? const SizedBox(
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
                ? null
                : _handleUnregistration,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              !canAttemptUnregister
                  ? Colors.grey.shade400
                  : Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title, overflow: TextOverflow.ellipsis),
        backgroundColor: theme.primaryColor,
        elevation: 1,
        titleTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.images.isNotEmpty)
              Hero(
                tag: 'activity_image_${widget.docId}',
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(activity.images[0]),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    theme,
                    activity,
                    formattedStartTime,
                    formattedDeadline,
                    formattedCreatedAt,
                  ),
                  const SizedBox(height: 16),
                  if (activity.content.isNotEmpty) ...[
                    _buildSectionTitle(theme, 'Mô Tả Hoạt Động'),
                    Text(
                      activity.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildPointsAndRegistrationSection(
                    theme,
                    activity,
                    currentRegistrations,
                    maxParticipants,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          (_activityDetail == null || _isLoadingPage)
              ? null
              : Material(
                elevation: 8.0,
                color: theme.scaffoldBackgroundColor,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16.0,
                    12.0,
                    16.0,
                    MediaQuery.of(context).padding.bottom + 12.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: registerButtonWidget),
                      if (unregisterButtonWidget != null) ...[
                        const SizedBox(width: 10),
                        Expanded(child: unregisterButtonWidget),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    ThemeData theme,
    ActivityModel activity,
    String startTimeStr,
    String deadlineStr,
    String createdAtStr,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Sử dụng hàm format phù hợp dựa trên kiểu dữ liệu trong ActivityModel
          if (activity.createdAt != null) // Giả sử createdAt là DateTime
            _infoRow(
              theme,
              Icons.calendar_today_outlined,
              'Ngày đăng',
              createdAtStr,
            ),
          if (activity.createdAt != null) const SizedBox(height: 10),

          // Giả sử startTime là DateTime
          _infoRow(theme, Icons.access_time_outlined, 'Bắt đầu', startTimeStr),
          const SizedBox(height: 10),

          // Giả sử registrationDeadline là DateTime?
          if (activity.registrationDeadline != null)
            _infoRow(
              theme,
              Icons.timer_off_outlined,
              'Hạn đăng ký',
              deadlineStr,
              highlight: activity.registrationDeadline!.isBefore(
                DateTime.now(),
              ), // Bỏ .toDate() nếu là DateTime
            ),
          if (activity.registrationDeadline != null) const SizedBox(height: 10),
          _infoRow(
            theme,
            Icons.location_on_outlined,
            'Địa điểm',
            activity.diadiem,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  highlight
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPointsAndRegistrationSection(
    ThemeData theme,
    ActivityModel activity,
    int current,
    int max,
  ) {
    final dynamic diemCTXH = activity.diemCTXH ?? 'N/A';
    final dynamic diemrl = activity.diemrl ?? 'N/A';

    final diemCTXHExists =
        diemCTXH != null &&
        diemCTXH.toString().isNotEmpty &&
        diemCTXH.toString() != 'N/A' &&
        diemCTXH.toString() != '0' &&
        diemCTXH.toString() != '';
    final diemRLExists =
        diemrl != null &&
        diemrl.toString().isNotEmpty &&
        diemrl.toString() != 'N/A' &&
        diemrl.toString() != '0' &&
        diemrl.toString() != '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (diemCTXHExists || diemRLExists) ...[
          _buildSectionTitle(theme, 'Phúc Lợi Dự Kiến'),
          Wrap(
            spacing: 10.0,
            runSpacing: 6.0,
            children: [
              if (diemCTXHExists)
                _pointChip(
                  theme,
                  "CTXH: $diemCTXH",
                  Colors.orange.shade700,
                  Colors.orange.shade50,
                  Icons.star_rounded,
                ),
              if (diemRLExists)
                _pointChip(
                  theme,
                  "R.Luyện: $diemrl",
                  Colors.lightBlue.shade700,
                  Colors.lightBlue.shade50,
                  Icons.shield_rounded,
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        _buildSectionTitle(theme, 'Số Lượng Tham Gia'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  color: theme.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '$current / ${max > 0 ? max : "Không giới hạn"}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (max > 0 && current >= max)
              Text(
                "Đã đủ số lượng",
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              )
            else if (max > 0)
              Text(
                "Còn ${max - current} suất",
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        if (max > 0) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:
                  max > 0
                      ? (current.toDouble() / max.toDouble()).clamp(0.0, 1.0)
                      : 0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                current >= max && max > 0
                    ? theme.colorScheme.error
                    : Colors.green.shade600,
              ),
              minHeight: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _pointChip(
    ThemeData theme,
    String label,
    Color fgColor,
    Color bgColor,
    IconData icon,
  ) {
    return Chip(
      avatar: Icon(icon, color: fgColor, size: 18),
      label: Text(label),
      labelStyle: TextStyle(
        color: fgColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: bgColor.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: fgColor.withOpacity(0.3)),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
