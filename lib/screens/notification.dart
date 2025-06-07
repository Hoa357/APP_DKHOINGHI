import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ungdungflutter/models/activity_model.dart'; // Đảm bảo đường dẫn đúng
import 'package:ungdungflutter/screens/activity_DetailPage.dart'; // Đảm bảo đường dẫn đúng

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  String _formatTimestamp(
    Timestamp timestamp, {
    String format = 'dd/MM/yyyy HH:mm',
  }) {
    // Đảm bảo 'vi_VN' đã được khởi tạo nếu bạn muốn dùng locale cụ thể
    // Intl.defaultLocale = 'vi_VN'; // Có thể đặt ở main.dart
    return DateFormat(format, 'vi_VN').format(timestamp.toDate().toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // Lấy theme hiện tại

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Báo Mới Nhất'), // Đổi title cho phù hợp
        backgroundColor:
            theme.primaryColor, // Nên dùng theme.colorScheme.primary
        elevation: 2,
        titleTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary, // Màu chữ trên AppBar
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: theme.colorScheme.onPrimary,
        ), // Màu cho nút back
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('activities')
                .orderBy(
                  'createdAt',
                  descending: true,
                ) // Sắp xếp theo createdAt mới nhất
                .limit(5) // Giới hạn chỉ lấy 5 thông báo
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Ghi log lỗi ra console để dễ debug hơn
            print("Firebase Stream Error: ${snapshot.error}");
            print("Error StackTrace: ${snapshot.stackTrace}");

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Không thể tải thông báo.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // Hiển thị thông điệp lỗi thân thiện hơn, chi tiết lỗi có thể xem ở console
                      'Đã có lỗi xảy ra khi tải dữ liệu. Vui lòng thử lại sau.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hiện chưa có thông báo nào.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              // Cẩn thận khi ép kiểu, nên kiểm tra null hoặc dùng try-catch nếu cần
              // Hoặc đảm bảo ActivityModel.fromDocument xử lý được trường hợp thiếu field
              ActivityModel notif;
              try {
                notif = ActivityModel.fromDocument(doc);
              } catch (e) {
                print(
                  "Error parsing ActivityModel from document ${doc.id}: $e",
                );
                // Có thể hiển thị một widget lỗi cho item này hoặc bỏ qua
                return Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Lỗi hiển thị thông báo này: ${doc.id}"),
                  ),
                );
              }

              final Timestamp createdAtTimestamp =
                  doc['createdAt'] as Timestamp? ?? Timestamp.now();

              return Card(
                elevation: 3, // Giảm elevation một chút cho nhẹ nhàng hơn
                margin: const EdgeInsets.only(bottom: 12.0), // Giảm margin
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0), // Bo góc ít hơn
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {
                    final String? currentUserIdFromAuth =
                        FirebaseAuth.instance.currentUser?.uid;

                    if (currentUserIdFromAuth != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ActivityDetailPage(
                                docId: doc.id,
                                currentUserId: currentUserIdFromAuth,
                              ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng đăng nhập để xem chi tiết.'),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.1),
                              child: Icon(
                                Icons
                                    .campaign_outlined, // Hoặc Icons.notifications_active_outlined
                                color: theme.colorScheme.primary,
                                size: 22, // Giảm size icon
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      // Dùng titleMedium
                                      fontWeight:
                                          FontWeight.w600, // Đậm hơn một chút
                                      // fontSize: 16, // Bỏ fixed size, để theme quyết định
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (notif.diadiem.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14, // Giảm size icon
                                          color: theme
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            notif.diadiem,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  // fontSize: 12.5, // Bỏ fixed size
                                                  color: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color
                                                      ?.withOpacity(0.9),
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Chỉ hiển thị content nếu có và không rỗng
                        if (notif.content.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notif.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              // fontSize: 14, // Bỏ fixed size
                              height: 1.3, // Giảm line height
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(
                          height: 10,
                        ), // Tăng khoảng cách trước dòng cuối
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Gom các chip lại nếu có
                            if ((notif.diemCTXH != null &&
                                    notif.diemCTXH != 0 &&
                                    notif.diemCTXH.toString() != 'N/A') ||
                                (notif.diemrl != null &&
                                    notif.diemrl != 0 &&
                                    notif.diemrl.toString() != 'N/A'))
                              Expanded(
                                // Cho phép các chip chiếm không gian
                                child: Wrap(
                                  spacing: 6.0,
                                  runSpacing: 4.0,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    if (notif.diemCTXH != null &&
                                        notif.diemCTXH != 0 &&
                                        notif.diemCTXH.toString() != 'N/A')
                                      Chip(
                                        avatar: Icon(
                                          Icons.star_border_purple500_outlined,
                                          size: 15,
                                          color: theme.colorScheme.primary,
                                        ),
                                        label: Text("${notif.diemCTXH} CTXH"),
                                        backgroundColor: theme
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.6),
                                        labelStyle: TextStyle(
                                          fontSize: 10.5, // Giảm size chữ
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    if (notif.diemrl != null &&
                                        notif.diemrl != 0 &&
                                        notif.diemrl.toString() != 'N/A')
                                      Chip(
                                        avatar: Icon(
                                          Icons.military_tech_outlined,
                                          size: 15,
                                          color: Colors.green.shade700,
                                        ),
                                        label: Text("${notif.diemrl} R.Luyện"),
                                        backgroundColor: Colors.green.shade100
                                            .withOpacity(0.7),
                                        labelStyle: TextStyle(
                                          fontSize: 10.5, // Giảm size chữ
                                          color: Colors.green.shade900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                  ],
                                ),
                              )
                            else
                              const Spacer(), // Nếu không có chip nào, dùng Spacer để đẩy timestamp qua phải

                            Text(
                              _formatTimestamp(
                                createdAtTimestamp,
                                format: 'HH:mm dd/MM', // Format ngắn gọn hơn
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11, // Giảm size chữ
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder:
                (context, index) => const SizedBox(
                  height: 0,
                ), // Không cần separator nữa vì Card đã có margin
          );
        },
      ),
    );
  }
}
