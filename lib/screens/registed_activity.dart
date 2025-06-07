import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '/models/activity_registration_model.dart'; // Import ParticipationStatus từ đây
import '/models/activity_model.dart';
import '/services/firestore_service.dart';

class EnrichedRegistrationData {
  final ActivityRegistrationModel registration;
  final ActivityModel activity;
  final ParticipationStatus displayStatus;

  EnrichedRegistrationData({
    required this.registration,
    required this.activity,
    required this.displayStatus,
  });
}

class MyRegisteredActivitiesScreen extends StatefulWidget {
  final String userId;
  const MyRegisteredActivitiesScreen({super.key, required this.userId});

  @override
  State<MyRegisteredActivitiesScreen> createState() =>
      _MyRegisteredActivitiesScreenState();
}

class _MyRegisteredActivitiesScreenState
    extends State<MyRegisteredActivitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<EnrichedRegistrationData>> _futureEnrichedUserRegistrations;
  DateTimeRange? _lastLoadedWeekRange;

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _eventsByDayForCalendar = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = null; // Mặc định không chọn ngày, hiển thị cả tuần
    _focusedDay = DateTime.now();
    _loadRegisteredActivities();
  }

  DateTimeRange _getWeekRange(DateTime focusedDay) {
    DateTime startOfWeek =
        focusedDay.subtract(Duration(days: focusedDay.weekday - 1)).dateOnly();
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6)).endOfDay();
    return DateTimeRange(start: startOfWeek, end: endOfWeek);
  }

  void _loadRegisteredActivities() {
    if (widget.userId.isEmpty) {
      setState(() {
        _futureEnrichedUserRegistrations = Future.value([]);
        _eventsByDayForCalendar = {};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để xem hoạt động.')),
      );
      return;
    }

    final weekRange = _getWeekRange(_focusedDay);
    if (_lastLoadedWeekRange == weekRange) {
      return; // Tránh tải lại nếu tuần không thay đổi
    }
    _lastLoadedWeekRange = weekRange;

    print(
      "MyRegisteredActivitiesScreen: Loading activities for week: ${weekRange.start} - ${weekRange.end}",
    );

    final newFuture = _fetchAndEnrichRegistrations(weekRange);
    setState(() {
      _futureEnrichedUserRegistrations = newFuture;
    });

    newFuture
        .then((enrichedDataList) {
          final Map<DateTime, List<dynamic>> newEvents = {};
          for (var enrichedData in enrichedDataList) {
            if (enrichedData.activity.startTime != null) {
              final day = enrichedData.activity.startTime.dateOnly();
              newEvents[day] ??= [];
              newEvents[day]!.add({
                'title': enrichedData.activity.title,
                'startTime': enrichedData.activity.startTime,
              });
            }
          }
          if (mounted) {
            setState(() {
              _eventsByDayForCalendar = newEvents;
            });
          }
        })
        .catchError((error) {
          print(
            "Error processing enriched registrations for calendar events: $error",
          );
          if (mounted) {
            setState(() {
              _eventsByDayForCalendar = {};
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi tải lịch hoạt động: $error')),
            );
          }
        });
  }

  Future<List<EnrichedRegistrationData>> _fetchAndEnrichRegistrations(
    DateTimeRange dateRange,
  ) async {
    if (widget.userId.isEmpty) return [];

    final registrations = await _firestoreService.getAllRegisteredActivities(
      widget.userId,
      dateRange: dateRange,
    );

    if (registrations.isEmpty) return [];

    List<EnrichedRegistrationData> enrichedList = [];

    for (var reg in registrations) {
      try {
        final activity = await _firestoreService.getActivityById(
          reg.activityId,
        );
        if (activity != null) {
          final displayStatus = _calculateDisplayStatus(reg, activity);

          enrichedList.add(
            EnrichedRegistrationData(
              registration: reg,
              activity: activity,
              displayStatus: displayStatus,
            ),
          );
        } else {
          print(
            "Activity not found for registration ${reg.id}, activityId: ${reg.activityId}",
          );
        }
      } catch (e) {
        print("Error enriching registration ${reg.id}: $e");
      }
    }
    return enrichedList;
  }

  DateTime _getDefaultEndTime(DateTime startTime) {
    final dateOnly = startTime.dateOnly();
    final noonOfDay = DateTime(
      dateOnly.year,
      dateOnly.month,
      dateOnly.day,
      12,
      0,
    );
    final sixPmOfDay = DateTime(
      dateOnly.year,
      dateOnly.month,
      dateOnly.day,
      18,
      0,
    );

    if (startTime.isBefore(noonOfDay) ||
        startTime.isAtSameMomentAs(noonOfDay)) {
      return noonOfDay;
    }
    return sixPmOfDay;
  }

  ParticipationStatus _calculateDisplayStatus(
    ActivityRegistrationModel registration,
    ActivityModel activity,
  ) {
    final effectiveEndTime =
        registration.endTime?.toDate() ??
        _getDefaultEndTime(activity.startTime);
    final now = DateTime.now();

    if (registration.status == ParticipationStatus.cancelled) {
      return ParticipationStatus.cancelled;
    }
    if (activity.startTime.isBefore(now) && effectiveEndTime.isBefore(now)) {
      return ParticipationStatus.absent;
    }
    if (activity.startTime.isBefore(now) && now.isBefore(effectiveEndTime)) {
      return ParticipationStatus.registered; // Đang diễn ra
    }
    return registration.status;
  }

  String _formatLocalDateTime(
    DateTime dateTime, {
    String format = 'HH:mm, dd/MM/yyyy',
  }) {
    return DateFormat(format, 'vi_VN').format(dateTime.toLocal());
  }

  Widget _buildStatusIndicator(
    ParticipationStatus status,
    ActivityModel activity,
    ThemeData theme,
  ) {
    bool isToday = isSameDay(
      activity.startTime.dateOnly(),
      DateTime.now().dateOnly(),
    );
    IconData iconData = Icons.event_note_outlined;
    Color iconColor = theme.hintColor;
    Color bookmarkColor = Colors.transparent;
    IconData? bookmarkIcon;

    switch (status) {
      case ParticipationStatus.pendingApproval:
        iconData = Icons.hourglass_empty_rounded;
        iconColor = Colors.orange.shade800;
        bookmarkColor = Colors.orange.shade700;
        bookmarkIcon = Icons.hourglass_bottom_rounded;
        break;
      case ParticipationStatus.registered:
        if (isToday) {
          iconData = Icons.today_rounded;
          iconColor = theme.primaryColorDark;
        } else {
          iconData = Icons.event_available;
          iconColor = Colors.blue.shade700;
        }
        break;
      case ParticipationStatus.checkedIn:
        iconData = Icons.check_circle_rounded;
        iconColor = Colors.green.shade700;
        bookmarkColor = Colors.green.shade600;
        bookmarkIcon = Icons.check_rounded;
        break;
      case ParticipationStatus.absent:
        iconData = Icons.cancel_rounded;
        iconColor = Colors.red.shade700;
        bookmarkColor = Colors.red.shade600;
        bookmarkIcon = Icons.close_rounded;
        break;
      case ParticipationStatus.cancelled:
        iconData = Icons.do_not_disturb_on_outlined;
        iconColor = Colors.grey.shade600;
        bookmarkColor = Colors.grey.shade500;
        bookmarkIcon = Icons.block_rounded;
        break;
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          if (bookmarkColor != Colors.transparent &&
              bookmarkIcon != null &&
              (status == ParticipationStatus.checkedIn ||
                  status == ParticipationStatus.absent ||
                  status == ParticipationStatus.pendingApproval ||
                  status == ParticipationStatus.cancelled))
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: bookmarkColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Icon(bookmarkIcon, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionalTimestampText(
    ParticipationStatus displayStatus,
    DateTime registrationTime,
    ThemeData theme,
  ) {
    TextStyle? style = theme.textTheme.labelSmall?.copyWith(
      color: theme.hintColor.withOpacity(0.8),
      fontSize: 11,
    );

    if (displayStatus == ParticipationStatus.pendingApproval) {
      return Text(
        'Đăng ký lúc: ${_formatLocalDateTime(registrationTime, format: "HH:mm dd/MM")}',
        style: style,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLoadingCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(backgroundColor: theme.splashColor, radius: 20),
        ),
        title: Container(
          height: 14,
          width: 120,
          decoration: BoxDecoration(
            color: theme.splashColor,
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.only(bottom: 6),
        ),
        subtitle: Container(
          height: 10,
          width: 80,
          decoration: BoxDecoration(
            color: theme.splashColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Color _getBorderColorForStatus(ParticipationStatus status, ThemeData theme) {
    switch (status) {
      case ParticipationStatus.checkedIn:
        return Colors.green.shade600;
      case ParticipationStatus.absent:
        return Colors.red.shade600;
      case ParticipationStatus.pendingApproval:
        return Colors.orange.shade700;
      case ParticipationStatus.registered:
        return Colors.blue.shade600;
      case ParticipationStatus.cancelled:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText(
    ParticipationStatus status,
    DateTime activityStartTime,
    DateTime activityEndTime,
  ) {
    final now = DateTime.now();
    final isToday = isSameDay(activityStartTime.dateOnly(), now.dateOnly());
    final isOngoing =
        now.isAtSameMomentAs(activityStartTime) ||
        (now.isAfter(activityStartTime) && now.isBefore(activityEndTime));

    switch (status) {
      case ParticipationStatus.pendingApproval:
        return "Chờ duyệt";
      case ParticipationStatus.registered:
        if (isOngoing) return "Đang diễn ra";
        if (isToday) return "Hôm nay diễn ra";
        return "Sắp diễn ra";
      case ParticipationStatus.checkedIn:
        return "Đã điểm danh";
      case ParticipationStatus.absent:
        return "Vắng mặt";
      case ParticipationStatus.cancelled:
        return "Đã hủy";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoạt Động Trong Tuần'),
        backgroundColor: theme.primaryColor,
        titleTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: TableCalendar(
              locale: 'vi_VN',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate:
                  (day) => isSameDay(_selectedDay, day.dateOnly()),
              eventLoader:
                  (day) => _eventsByDayForCalendar[day.dateOnly()] ?? [],
              calendarBuilders: CalendarBuilders(
                selectedBuilder:
                    (context, date, events) => Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
                    ),
                todayBuilder:
                    (context, date, events) => Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 5,
                      bottom: 5,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.error.withOpacity(0.9),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay.dateOnly())) {
                  setState(() {
                    _selectedDay = selectedDay.dateOnly();
                  });
                }
              },
              onPageChanged: (focusedDay) {
                if (!isSameDay(_focusedDay, focusedDay.dateOnly())) {
                  setState(() {
                    _focusedDay = focusedDay.dateOnly();
                    _selectedDay = null; // Reset chọn ngày khi chuyển tuần
                  });
                  _loadRegisteredActivities();
                }
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: theme.primaryColorDark.withOpacity(0.8),
                ),
                tablePadding: const EdgeInsets.only(bottom: 4),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.titleLarge?.color,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: theme.primaryColor,
                  size: 28,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.primaryColor,
                  size: 28,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                ),
                weekendStyle: TextStyle(
                  fontSize: 13,
                  color: theme.primaryColor.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              startingDayOfWeek: StartingDayOfWeek.monday,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<EnrichedRegistrationData>>(
              future: _futureEnrichedUserRegistrations,
              builder: (context, snapshot) {
                if (widget.userId.isEmpty) {
                  return const Center(child: Text("Vui lòng đăng nhập."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: List.generate(3, (_) => _buildLoadingCard()),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Lỗi tải dữ liệu: ${snapshot.error?.toString() ?? 'Unknown error'}",
                    ),
                  );
                }

                final enrichedRegistrations = snapshot.data;
                if (enrichedRegistrations == null ||
                    enrichedRegistrations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_view_week_outlined,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không có hoạt động nào trong tuần này.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Lọc danh sách theo ngày được chọn hoặc hiển thị cả tuần
                final filteredRegistrations =
                    _selectedDay != null
                        ? enrichedRegistrations.where(
                          (data) => isSameDay(
                            data.activity.startTime.dateOnly(),
                            _selectedDay!,
                          ),
                        )
                        : enrichedRegistrations;

                return RefreshIndicator(
                  onRefresh: () async => _loadRegisteredActivities(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
                    itemCount: filteredRegistrations.length,
                    itemBuilder: (context, index) {
                      final enrichedData = filteredRegistrations.elementAt(
                        index,
                      );
                      final activity = enrichedData.activity;
                      final registration = enrichedData.registration;
                      final displayStatus = enrichedData.displayStatus;
                      final effectiveEndTime =
                          registration.endTime?.toDate() ??
                          _getDefaultEndTime(activity.startTime);

                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: _getBorderColorForStatus(
                              displayStatus,
                              theme,
                            ).withOpacity(0.7),
                            width: 1.2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Chi tiết: ${activity.title}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                _buildStatusIndicator(
                                  displayStatus,
                                  activity,
                                  theme,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.title,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _getStatusText(
                                          displayStatus,
                                          activity.startTime,
                                          effectiveEndTime,
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: _getBorderColorForStatus(
                                                displayStatus,
                                                theme,
                                              ),
                                              fontSize: 11.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Thời gian: ${_formatLocalDateTime(activity.startTime, format: "E, dd/MM HH:mm")} - ${_formatLocalDateTime(effectiveEndTime, format: "HH:mm")}',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: theme.hintColor,
                                              fontSize: 11.5,
                                            ),
                                      ),
                                      _buildOptionalTimestampText(
                                        displayStatus,
                                        registration.registerTime.toDate(),
                                        theme,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 15,
                                  color: theme.hintColor.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime dateOnly() {
    return DateTime(year, month, day);
  }

  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999, 999);
  }

  bool isAtSameMomentAsOrAfter(DateTime other) {
    return isAtSameMomentAs(other) || isAfter(other);
  }
}

extension StringExtension on String {
  String formatEnumName() {
    if (isEmpty) return this;
    String spacedString = replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
      (Match m) => ' ${m[0]}',
    );
    return spacedString.capitalizeFirstLetterOfEachWord();
  }

  String capitalizeFirstLetterOfEachWord() {
    if (isEmpty) return this;
    return split(' ')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
