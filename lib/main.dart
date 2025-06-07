import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/history_activity_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';

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
          color: Colors.blue,
          elevation: 8.0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [const Locale('en', ''), const Locale('vi', '')],
      home: AuthWrapper(),
      routes: {'/login': (context) => LoginScreen()},
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
          return MainPage(userId: snapshot.data!.uid);
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

class MainPage extends StatefulWidget {
  final String userId;

  const MainPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(),
      ActivityLogScreen(userId: widget.userId),
      ScanScreen(),
      ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
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
    final iconColor = Colors.white;
    final textColor = Colors.white;

    Color itemBackgroundColor;
    if (isSelected) {
      itemBackgroundColor = Color.lerp(bottomAppBarColor, Colors.black, 0.15)!;
    } else {
      itemBackgroundColor = Colors.transparent;
    }

    return Expanded(
      child: Material(
        color: itemBackgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(8.0),
          splashColor: Colors.white.withOpacity(0.12),
          highlightColor: Colors.white.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 24),
                SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(color: textColor, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: kBottomNavigationBarHeight,
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildTabItem(
                icon: Icons.home_outlined,
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
                icon: Icons.qr_code_scanner_outlined,
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
