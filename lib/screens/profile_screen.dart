import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ungdungflutter/models/user_models.dart';
import 'package:ungdungflutter/services/user_services.dart';

import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await UserService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Lỗi tải thông tin: ${e.toString()}');
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.logout, color: Colors.red[600]),
                SizedBox(width: 8),
                Text('Đăng xuất'),
              ],
            ),
            content: Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Đăng xuất', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        await UserService.signOut();
        // Navigate to login screen
        Navigator.of(context).pushReplacementNamed('/login');
      } catch (e) {
        _showSnackBar('Lỗi đăng xuất: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            message.contains('thành công') ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Widget để tạo menu item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.blue[600])?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor ?? Colors.blue[600], size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.grey[200],
            indent: 60,
            endIndent: 16,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue[600]),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải thông tin...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header với thông tin user
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue[600]!, Colors.blue[800]!],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child:
                                      _currentUser?.avatarUrl != null
                                          ? ClipOval(
                                            child: Image.network(
                                              _currentUser!.avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.person,
                                                    color: Colors.blue[600],
                                                    size: 30,
                                                  ),
                                            ),
                                          )
                                          : Icon(
                                            Icons.person,
                                            color: Colors.blue[600],
                                            size: 30,
                                          ),
                                ),
                                SizedBox(width: 16),

                                // Thông tin user
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentUser?.name ?? 'Đang tải...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Mssv: ${_currentUser?.mssv ?? '...'}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Menu items
                      Container(
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              title: 'Thông tin sinh viên',
                              onTap: () {
                                // Navigate to student info screen
                                _showSnackBar('Chức năng đang phát triển');
                              },
                              iconColor: Colors.blue[600],
                            ),

                            _buildMenuItem(
                              icon: Icons.lock_outline,
                              title: 'Đổi mật khẩu',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChangePasswordScreen(),
                                  ),
                                );
                              },
                              iconColor: Colors.orange[600],
                            ),

                            _buildMenuItem(
                              icon: Icons.description_outlined,
                              title: 'Điều khoản và chính sách',
                              onTap: () {
                                _showSnackBar('Chức năng đang phát triển');
                              },
                              iconColor: Colors.green[600],
                            ),

                            _buildMenuItem(
                              icon: Icons.feedback_outlined,
                              title: 'Góp ý ứng dụng',
                              onTap: () {
                                _showSnackBar('Chức năng đang phát triển');
                              },
                              iconColor: Colors.purple[600],
                            ),

                            _buildMenuItem(
                              icon: Icons.notifications_outlined,
                              title: 'Thông báo',
                              onTap: () {
                                _showSnackBar('Chức năng đang phát triển');
                              },
                              iconColor: Colors.amber[600],
                            ),

                            _buildMenuItem(
                              icon: Icons.logout,
                              title: 'Đăng xuất',
                              onTap: _handleLogout,
                              iconColor: Colors.red[600],
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
