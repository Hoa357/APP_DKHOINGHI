import 'package:flutter/material.dart';
import 'package:ungdungflutter/models/user_models.dart';

class StudentInfoScreen extends StatelessWidget {
  final UserModel user;

  const StudentInfoScreen({Key? key, required this.user}) : super(key: key);

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String? value, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            ":",
            style: TextStyle(
              fontSize: 15.5,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              (value != null && value.trim().isNotEmpty)
                  ? value
                  : 'Chưa cập nhật',
              style: TextStyle(
                fontSize: 15.5,
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themePrimaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin sinh viên'),
        backgroundColor: themePrimaryColor,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themePrimaryColor,
                    Color.lerp(themePrimaryColor, Colors.black, 0.15)!,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white70,
                    child: CircleAvatar(
                      radius: 57,
                      backgroundImage:
                          (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                      child:
                          (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                              ? Icon(
                                Icons.person_rounded,
                                size: 65,
                                color: themePrimaryColor.withOpacity(0.8),
                              )
                              : null,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    user.name ?? 'Không có tên',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(context, 'MSSV', user.mssv),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(context, 'Giới tính', user.gender),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(
                        context,
                        'Ngày sinh',
                        user.getFormattedDateOfBirth() ?? 'Chưa cập nhật',
                      ),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(context, 'Email', user.email),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(context, 'Điện thoại', user.phone),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(context, 'Khoa', user.faculty),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(context, 'Lớp', user.className),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(
                        context,
                        'Bậc đào tạo',
                        user.educationLevel,
                      ),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(
                        context,
                        'Loại hình đào tạo',
                        user.trainingType,
                      ),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(context, 'Khóa học', user.academicYear),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(
                        context,
                        'Chuyên ngành',
                        user.specialization,
                      ),
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildInfoRow(
                        context,
                        'Ngày sinh',
                        user.getFormattedDateOfBirth(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
