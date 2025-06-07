import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/models/activity_model.dart';
import 'package:ungdungflutter/models/activity_registration_model.dart';
import 'package:ungdungflutter/services/firestore_service.dart';

// Enum cho các tab filter (giữ nguyên để đồng bộ với ParticipationStatus)
enum ActivityLogFilter {
  all,
  pendingApproval,
  registered,
  checkedIn,
  absent,
  cancelled,
}

// Class helper để chứa dữ liệu đã được "làm giàu"
class EnrichedActivityLogItem {
  final ActivityRegistrationModel registration;
  final ActivityModel activity;

  EnrichedActivityLogItem({required this.registration, required this.activity});
}

class ActivityLogScreen extends StatefulWidget {
  final String userId;
  const ActivityLogScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ActivityLogScreenState createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<EnrichedActivityLogItem>> _futureAllUserActivitiesLog;
  List<EnrichedActivityLogItem> _allLogs = [];
  List<EnrichedActivityLogItem> _filteredLogs = [];

  ActivityLogFilter _selectedFilter = ActivityLogFilter.all;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ActivityLogFilter.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabSelection);
    _loadAllUserActivitiesLog();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.index !=
        ActivityLogFilter.values.indexOf(_selectedFilter)) {
      if (mounted) {
        setState(() {
          _selectedFilter = ActivityLogFilter.values[_tabController.index];
          _applyFilters();
        });
      }
    }
  }

  Future<void> _loadAllUserActivitiesLog() async {
    if (widget.userId.isEmpty) {
      if (mounted) {
        setState(() {
          _futureAllUserActivitiesLog = Future.value([]);
          _allLogs = [];
          _filteredLogs = [];
        });
      }
      return;
    }

    final newFuture = _fetchAllAndEnrichLogs();
    if (mounted) {
      setState(() {
        _futureAllUserActivitiesLog = newFuture;
      });
    }

    try {
      final logs = await newFuture;
      if (mounted) {
        setState(() {
          _allLogs = logs;
          _applyFilters();
        });
      }
    } catch (e) {
      print("Error loading activity logs: $e");
      if (mounted) {
        setState(() {
          _futureAllUserActivitiesLog = Future.value([]);
          _allLogs = [];
          _filteredLogs = [];
        });
      }
    }
  }

  Future<List<EnrichedActivityLogItem>> _fetchAllAndEnrichLogs() async {
    final registrations = await _firestoreService.getAllRegisteredActivities(
      widget.userId,
    );
    if (registrations.isEmpty) return [];

    List<EnrichedActivityLogItem> enrichedList = [];
    for (var reg in registrations) {
      try {
        final activity = await _firestoreService.getActivityById(
          reg.activityId,
        );
        if (activity != null && activity.startTime != null) {
          enrichedList.add(
            EnrichedActivityLogItem(registration: reg, activity: activity),
          );
        } else {
          if (activity == null) {
            print(
              "Activity not found for registration ${reg.id}, activityId: ${reg.activityId}",
            );
          } else {
            print(
              "Activity ${activity.id} for registration ${reg.id} has null startTime, skipping.",
            );
          }
        }
      } catch (e) {
        print("Error enriching log for registration ${reg.id}: $e");
      }
    }
    enrichedList.sort(
      (a, b) => b.activity.startTime.compareTo(a.activity.startTime),
    );
    return enrichedList;
  }

  void _applyFilters() {
    if (_selectedFilter == ActivityLogFilter.all) {
      _filteredLogs = List.from(_allLogs);
    } else {
      _filteredLogs =
          _allLogs.where((log) {
            ParticipationStatus targetStatus;
            switch (_selectedFilter) {
              case ActivityLogFilter.pendingApproval:
                targetStatus = ParticipationStatus.pendingApproval;
                break;
              case ActivityLogFilter.registered:
                targetStatus = ParticipationStatus.registered;
                break;
              case ActivityLogFilter.checkedIn:
                targetStatus = ParticipationStatus.checkedIn;
                break;
              case ActivityLogFilter.absent:
                targetStatus = ParticipationStatus.absent;
                break;
              case ActivityLogFilter.cancelled:
                targetStatus = ParticipationStatus.cancelled;
                break;
              case ActivityLogFilter.all:
                return true;
            }
            return log.registration.status == targetStatus;
          }).toList();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Color _getBackgroundColorForStatus(
    ParticipationStatus status,
    ThemeData theme,
  ) {
    switch (status) {
      case ParticipationStatus.checkedIn:
        return Colors.green.shade50;
      case ParticipationStatus.absent:
        return Colors.red.shade50;
      case ParticipationStatus.pendingApproval:
        return Colors.orange.shade50;
      case ParticipationStatus.registered:
        return Colors.blue.shade50;
      case ParticipationStatus.cancelled:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(ParticipationStatus status, ThemeData theme) {
    switch (status) {
      case ParticipationStatus.checkedIn:
        return Colors.green.shade700;
      case ParticipationStatus.absent:
        return Colors.red.shade700;
      case ParticipationStatus.pendingApproval:
        return Colors.orange.shade800;
      case ParticipationStatus.registered:
        return Colors.blue.shade700;
      case ParticipationStatus.cancelled:
        return Colors.grey.shade700;
    }
  }

  String _getStatusText(
    ParticipationStatus status,
    DateTime activityStartTime,
  ) {
    bool isToday = DateUtils.isSameDay(activityStartTime, DateTime.now());
    switch (status) {
      case ParticipationStatus.pendingApproval:
        return "Chờ duyệt";
      case ParticipationStatus.registered:
        if (isToday) return "Hôm nay diễn ra";
        return "Sắp diễn ra";
      case ParticipationStatus.checkedIn:
        return "Đã tham gia";
      case ParticipationStatus.absent:
        return "Vắng mặt";
      case ParticipationStatus.cancelled:
        return "Đã hủy";
    }
  }

  String _formatLocalDateTime(
    DateTime dateTime, {
    String format = 'dd/MM/yyyy HH:mm',
  }) {
    return DateFormat(format, 'vi_VN').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử Hoạt động'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs:
              ActivityLogFilter.values.map((filter) {
                String text;
                switch (filter) {
                  case ActivityLogFilter.all:
                    text = 'Tất cả';
                    break;
                  case ActivityLogFilter.pendingApproval:
                    text = 'Chờ duyệt';
                    break;
                  case ActivityLogFilter.registered:
                    text = 'Sắp diễn ra';
                    break;
                  case ActivityLogFilter.checkedIn:
                    text = 'Đã tham gia';
                    break;
                  case ActivityLogFilter.absent:
                    text = 'Vắng mặt';
                    break;
                  case ActivityLogFilter.cancelled:
                    text = 'Đã hủy';
                    break;
                }
                return Tab(text: text);
              }).toList(),
        ),
      ),
      body: FutureBuilder<List<EnrichedActivityLogItem>>(
        future: _futureAllUserActivitiesLog,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _allLogs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && _allLogs.isEmpty) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }
          if (_allLogs.isEmpty &&
              snapshot.connectionState != ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Bạn chưa đăng ký hoạt động nào.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
            );
          }
          if (_filteredLogs.isEmpty &&
              _selectedFilter != ActivityLogFilter.all) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Không có hoạt động nào ở trạng thái này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
            );
          }

          final List<EnrichedActivityLogItem> itemsToDisplay = _filteredLogs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: itemsToDisplay.length,
            itemBuilder: (context, index) {
              final logItem = itemsToDisplay[index];
              final activity = logItem.activity;
              final registration = logItem.registration;
              final status = registration.status;

              return Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 8.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color: _getStatusTextColor(status, theme).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                color: _getBackgroundColorForStatus(status, theme),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Chi tiết: ${activity.title}')),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Diễn ra: ${_formatLocalDateTime(activity.startTime)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                        if (activity.diadiem.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Địa điểm: ${activity.diadiem}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (registration.checkInTime != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Điểm danh: ${_formatLocalDateTime(registration.checkInTime!.toDate())}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (registration.updatedBy != null &&
                            registration.updatedBy!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cập nhật bởi: ${registration.updatedBy}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusTextColor(
                                status,
                                theme,
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _getStatusText(status, activity.startTime),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getStatusTextColor(status, theme),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllUserActivitiesLog,
        child: Icon(Icons.refresh),
        tooltip: 'Làm mới',
      ),
    );
  }
}

// Extensions (DateTimeExtension, StringExtension)
extension DateTimeExtension on DateTime {
  DateTime dateOnly() {
    return DateTime(year, month, day);
  }

  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999, 999);
  }
}

extension StringExtension on String {
  String formatEnumName() {
    if (isEmpty) return this;
    String spacedString = replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
      (Match m) => ' ${m[0]}',
    );
    return spacedString;
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
