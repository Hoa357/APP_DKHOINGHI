import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ungdungflutter/screens/scan_screen.dart'; // Đảm bảo import đúng

import 'screens/home_screen.dart';
import 'screens/activity_log_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';

// --- BỎ COMMENT CÁC MÀN HÌNH GIẢ LẬP NẾU BẠN CHƯA CÓ FILE THẬT ---
// (Hoặc tạo file thật cho chúng)
// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Home")), body: Center(child: Text('Home Screen')));
// }
// class ActivityLogScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Activity Log")), body: Center(child: Text('Activity Log Screen')));
// }
// class ProfileScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Profile")), body: Center(child: Text('Profile Screen')));
// }
// class LoginScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => Scaffold(
//         appBar: AppBar(title: Text("Login")),
//         body: Center(
//           child: ElevatedButton(
//             onPressed: () async {
//               // Giả lập đăng nhập thành công cho mục đích UI
//               // Trong ứng dụng thật, bạn sẽ dùng FirebaseAuth.instance.signIn...
//               // Để StreamBuilder hoạt động đúng, cần có sự kiện authStateChanges
//               // Cách đơn giản để test UI là bỏ qua AuthWrapper và home: MainPage()
//               // Hoặc thực hiện một đăng nhập ẩn danh nếu Firebase được cấu hình
//               try {
//                 await FirebaseAuth.instance.signInAnonymously();
//                 // Navigator.pushReplacementNamed(context, '/main'); // Không cần thiết nếu dùng StreamBuilder
//               } catch (e) {
//                 print("Lỗi đăng nhập ẩn danh: $e");
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text("Không thể đăng nhập ẩn danh để test: $e"))
//                 );
//               }
//             },
//             child: Text('Login (Anonymous Test)'),
//           ),
//         ),
//       );
// }
// --- KẾT THÚC PHẦN GIẢ LẬP ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng hoạt động học thuật CNTT',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 0, 36, 66),
        bottomAppBarTheme: BottomAppBarTheme(
          color: Colors.blue, // Màu nền xanh cho BottomAppBar
          elevation: 8.0, // Thêm chút bóng đổ cho BottomAppBar
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainPage(),
        // Bạn có thể thêm các route khác ở đây nếu cần
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData && snapshot.data != null) {
          return MainPage(); // Đã đăng nhập
        } else {
          return LoginScreen(); // Chưa đăng nhập
        }
      },
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // Thêm GlobalKey để có thể truy cập Scaffold từ bên ngoài nếu cần (ví dụ: hiển thị SnackBar)
  // final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Đảm bảo bạn đã tạo các file screen này trong thư mục 'screens'
  final List<Widget> _screens = [
    HomeScreen(),
    ActivityLogScreen(),
    ScanScreen(), // Màn hình Scan của bạn
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    // Nếu người dùng nhấn vào tab Scan (index 2) mà ScanScreen được thiết kế
    // để điều hướng đi nơi khác (ví dụ mở camera toàn màn hình rồi quay lại),
    // bạn có thể không muốn thay đổi _selectedIndex ngay lập tức
    // hoặc bạn muốn xử lý đặc biệt.
    // Trong trường hợp này, ScanScreen là một phần của PageView/IndexedStack
    // nên việc thay đổi _selectedIndex là đúng.
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    final isSelected = _selectedIndex == index;
    final bottomAppBarColor =
        Theme.of(context).bottomAppBarTheme.color ?? Colors.blue;
    final iconColor = Colors.white; // Icon và text luôn màu trắng
    final textColor = Colors.white;

    Color itemBackgroundColor;
    if (isSelected) {
      // Tạo hiệu ứng "lõm" bằng cách làm màu nền tối hơn một chút
      // Bạn có thể thử HSLColor để giảm độ sáng (lightness)
      // Hoặc trộn với màu đen
      itemBackgroundColor = Color.lerp(bottomAppBarColor, Colors.black, 0.15)!;
      // Hoặc một cách khác:
      // itemBackgroundColor = bottomAppBarColor.withBlue(bottomAppBarColor.blue - 20).withGreen(bottomAppBarColor.green - 20);
    } else {
      itemBackgroundColor =
          Colors.transparent; // Nền trong suốt khi không được chọn
    }

    return Expanded(
      child: Material(
        color: itemBackgroundColor, // Màu nền đã được tính toán
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(
            8.0,
          ), // Cần cho hiệu ứng splash khớp với bo góc
          splashColor: Colors.white.withOpacity(0.12),
          highlightColor: Colors.white.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
            ), // Giảm padding dọc một chút
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 24), // Kích thước icon chuẩn
                SizedBox(height: 3), // Giảm khoảng cách
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11, // Giảm nhẹ fontSize để tránh overflow
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1, // Đảm bảo text chỉ trên 1 dòng
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key: _scaffoldKey, // Nếu cần
      body: IndexedStack(
        // Sử dụng IndexedStack để giữ trạng thái các màn hình
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomAppBar(
        // shape, notchMargin không còn cần thiết
        child: Container(
          // Giảm chiều cao của BottomAppBar
          height:
              kBottomNavigationBarHeight, // Chiều cao tiêu chuẩn (thường là 56.0)
          padding: EdgeInsets.symmetric(
            horizontal: 4.0,
            vertical: 2.0,
          ), // Điều chỉnh padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildTabItem(
                icon:
                    Icons
                        .home_outlined, // Sử dụng icon outlined cho trạng thái không active
                label: 'Trang Chủ',
                index: 0,
                context: context,
              ),
              _buildTabItem(
                icon: Icons.list_alt_outlined,
                label: 'Nhật ký',
                index: 1,
                context: context,
              ),
              _buildTabItem(
                icon: Icons.qr_code_scanner_outlined, // Icon phù hợp cho scan
                label: 'Scan',
                index: 2,
                context: context,
              ),
              _buildTabItem(
                icon: Icons.person_outline,
                label: 'Cá nhân',
                index: 3,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
