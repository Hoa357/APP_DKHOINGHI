// ungdungflutter/screens/profile_screen.dart
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Không cần trực tiếp ở đây nếu UserService xử lý
import 'package:ungdungflutter/models/user_models.dart'; // Đảm bảo đường dẫn này đúng
import 'package:ungdungflutter/services/user_services.dart'; // Đảm bảo đường dẫn này đúng

import 'change_password_screen.dart'; // Màn hình đổi mật khẩu
import 'student_info_screen.dart'; // Màn hình thông tin sinh viên chi tiết

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
    if (!mounted) return; // Kiểm tra widget có còn trong cây không
    setState(() {
      _isLoading = true; // Bắt đầu tải thì hiện loading
    });

    try {
      final user = await UserService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) _showSnackBar('Lỗi tải thông tin: ${e.toString()}');
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
                Icon(Icons.logout_rounded, color: Colors.red[700]),
                SizedBox(width: 10),
                Text(
                  'Xác nhận đăng xuất',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Hủy',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text('Đăng xuất', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        await UserService.signOut();
        // AuthWrapper (trong main.dart) sẽ tự động chuyển về màn hình login.
        // Không cần Navigator.pushReplacementNamed('/login') ở đây nếu AuthWrapper hoạt động đúng.
        // Nếu bạn muốn điều hướng tường minh (ví dụ, AuthWrapper không có):
        // if (mounted) {
        //   Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
        // }
      } catch (e) {
        if (mounted) _showSnackBar('Lỗi đăng xuất: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor:
            message.toLowerCase().contains('thành công')
                ? Colors.green[600]
                : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.fromLTRB(15, 5, 15, 15), // Margin cho SnackBar
        duration: Duration(seconds: 3),
      ),
    );
  }

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
            padding: EdgeInsets.all(10), // Tăng padding cho icon
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(
                0.12,
              ),
              borderRadius: BorderRadius.circular(10), // Bo tròn hơn
            ),
            child: Icon(
              icon,
              color: iconColor ?? Theme.of(context).primaryColor,
              size: 22,
            ), // Tăng size icon
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16.5, // Tăng nhẹ font size
              fontWeight: FontWeight.w500,
              color: Colors.grey[850],
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18, // Tăng nhẹ size mũi tên
            color: Colors.grey[400],
          ),
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ), // Tăng vertical padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          // hoverColor: Colors.grey[100], // Hiệu ứng khi hover (cho web/desktop)
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(
              left: 68.0,
              right: 16.0,
            ), // Điều chỉnh indent/endIndent
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: Colors.grey[200],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themePrimaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền nhẹ nhàng hơn
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: themePrimaryColor),
                    SizedBox(height: 20),
                    Text(
                      'Đang tải thông tin người dùng...',
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadUserData,
                color: themePrimaryColor,
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  // Sử dụng CustomScrollView để có thể có header cố định hoặc hiệu ứng parallax sau này
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 180.0, // Chiều cao của header khi mở rộng
                      floating: false,
                      pinned: true, // Header sẽ được ghim lại khi cuộn
                      elevation: 2,
                      backgroundColor: themePrimaryColor,
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: false, // Tiêu đề không ở giữa
                        titlePadding: EdgeInsetsDirectional.only(
                          start: 72,
                          bottom: 16,
                        ), // Padding cho tiêu đề
                        title: Text(
                          _currentUser?.name ?? 'Thông tin cá nhân',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                themePrimaryColor.withOpacity(0.9),
                                Color.lerp(
                                  themePrimaryColor,
                                  Colors.black,
                                  0.2,
                                )!, // Màu tối hơn một chút
                              ],
                            ),
                          ),
                          child: SafeArea(
                            // Chỉ áp dụng SafeArea cho phần nội dung bên trong background
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: kToolbarHeight - 10,
                                bottom: 50,
                              ), // Điều chỉnh padding để avatar nằm dưới appbar title
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Avatar
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child:
                                          (_currentUser?.avatarUrl != null &&
                                                  _currentUser!
                                                      .avatarUrl!
                                                      .isNotEmpty)
                                              ? Image.network(
                                                _currentUser!.avatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.person_rounded,
                                                      color: themePrimaryColor,
                                                      size: 35,
                                                    ),
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white70),
                                                      value:
                                                          loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                    ),
                                                  );
                                                },
                                              )
                                              : Icon(
                                                Icons.person_rounded,
                                                color: themePrimaryColor,
                                                size: 35,
                                              ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // Thông tin user (chỉ MSSV, tên đã lên title)
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center, // Căn giữa theo chiều dọc
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 25,
                                        ), // Khoảng trống để tên trên title không bị che
                                        Text(
                                          'MSSV: ${_currentUser?.mssv ?? 'N/A'}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.95,
                                            ),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
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
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 20.0,
                        ), // Khoảng cách giữa header và menu
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.account_circle_outlined,
                                title: 'Thông tin sinh viên',
                                onTap: () {
                                  if (_currentUser != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => StudentInfoScreen(
                                              user: _currentUser!,
                                            ),
                                      ),
                                    );
                                  } else {
                                    _showSnackBar(
                                      'Không có dữ liệu người dùng để hiển thị.',
                                    );
                                  }
                                },
                                iconColor: Colors.blue[700],
                              ),
                              _buildMenuItem(
                                icon: Icons.lock_outline_rounded,
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
                                iconColor: Colors.orange[700],
                              ),
                              _buildMenuItem(
                                icon: Icons.description_outlined,
                                title: 'Điều khoản và chính sách',
                                onTap: () {
                                  _showSnackBar('Chức năng đang phát triển');
                                },
                                iconColor: Colors.green[700],
                              ),
                              _buildMenuItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'Góp ý ứng dụng',
                                onTap: () {
                                  _showSnackBar('Chức năng đang phát triển');
                                },
                                iconColor: Colors.purple[700],
                              ),
                              _buildMenuItem(
                                icon: Icons.notifications_none_rounded,
                                title: 'Thông báo',
                                onTap: () {
                                  _showSnackBar('Chức năng đang phát triển');
                                },
                                iconColor: Colors.amber[700],
                                // showDivider: false, // Ví dụ nếu đây là mục cuối trong 1 nhóm
                              ),
                              _buildMenuItem(
                                // Mục đăng xuất
                                icon: Icons.logout_rounded,
                                title: 'Đăng xuất',
                                onTap: _handleLogout,
                                iconColor: Colors.red[700],
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      // Đảm bảo nội dung có thể cuộn nếu ít item
                      hasScrollBody: false,
                      child: SizedBox(height: 20), // Khoảng trống ở cuối
                    ),
                  ],
                ),
              ),
    );
  }
}
