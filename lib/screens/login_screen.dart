import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mssvController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _mssvError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _mssvController.addListener(() {
      if (_mssvError != null && _mssvController.text.isNotEmpty) {
        setState(() {
          _mssvError = null;
        });
      }
    });
    _passwordController.addListener(() {
      if (_passwordError != null && _passwordController.text.isNotEmpty) {
        setState(() {
          _passwordError = null;
        });
      }
    });
  }

  Future<void> _login() async {
    // 1. Xóa lỗi cũ và bật loading
    setState(() {
      _mssvError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final mssv = _mssvController.text.trim();
    final password = _passwordController.text;

    // 2. Validate trường rỗng
    bool hasValidationError = false;
    if (mssv.isEmpty) {
      setState(() => _mssvError = 'Vui lòng điền mã số sinh viên');
      hasValidationError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Vui lòng điền mật khẩu');
      hasValidationError = true;
    }

    if (hasValidationError) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot =
          await firestore
              .collection('students')
              .where('mssv', isEqualTo: mssv)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        // Người dùng nhập MSSV không tồn tại trong collection 'students'
        setState(() {
          _mssvError = 'Mã số sinh viên không tồn tại.';
        });
        return;
      }

      final studentDoc = querySnapshot.docs.first;
      final rawEmail = studentDoc.data()['email'];
      final email = rawEmail?.toString().trim() ?? '';

      if (email.isEmpty) {
        // MSSV tồn tại, nhưng không có email liên kết trong Firestore hoặc email rỗng
        setState(() {
          _mssvError =
              'Mã số sinh viên này chưa được cấp thông tin đăng nhập. Vui lòng liên hệ quản trị viên.';
        });
        return;
      }

      // Kiểm tra sơ bộ định dạng email trước khi gọi Firebase Auth
      // (Firebase Auth cũng sẽ kiểm tra, nhưng đây là bước kiểm tra sớm)
      final bool isValidEmailFormat = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+$",
      ).hasMatch(email);

      if (!isValidEmailFormat) {
        // Email lấy từ Firestore không đúng định dạng
        setState(() {
          _mssvError =
              'Thông tin đăng nhập liên kết với mã số sinh viên này không hợp lệ. Vui lòng liên hệ quản trị viên.';
        });
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, // email này được lấy từ MSSV
        password: password,
      );

      // Đăng nhập thành công
      // Navigator.pushReplacementNamed(context, '/main'); // AuthWrapper sẽ xử lý
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          // MSSV đúng, tài khoản (email) tồn tại, nhưng mật khẩu sai
          setState(
            () => _passwordError = 'Sai mật khẩu. Vui lòng kiểm tra lại.',
          );
          break;
        case 'user-not-found':
          // MSSV đã được tìm thấy trong Firestore và có email liên kết,
          // NHƯNG email đó không tồn tại trong Firebase Authentication.
          // Nghĩa là tài khoản chưa được tạo trong hệ thống Auth.
          setState(
            () =>
                _mssvError =
                    'Tài khoản đăng nhập cho mã số sinh viên này không tồn tại hoặc chưa được kích hoạt.',
          );
          break;
        case 'invalid-email':
          // Email dùng để đăng nhập (lấy từ MSSV) có định dạng không hợp lệ theo Firebase Auth
          // Trường hợp này ít xảy ra nếu đã kiểm tra regex ở trên, nhưng vẫn nên có.
          setState(
            () =>
                _mssvError =
                    'Thông tin đăng nhập liên kết với mã số sinh viên này không hợp lệ. Vui lòng liên hệ quản trị viên.',
          );
          break;
        case 'user-disabled':
          // Tài khoản (email) liên kết với MSSV đã bị vô hiệu hóa
          setState(
            () =>
                _mssvError =
                    'Tài khoản đăng nhập của mã số sinh viên này đã bị vô hiệu hóa.',
          );
          break;
        case 'too-many-requests':
          setState(
            () =>
                _mssvError =
                    'Bạn đã thử đăng nhập quá nhiều lần với mã số sinh viên này. Vui lòng thử lại sau.',
          );
          break;
        default:
          // Các lỗi khác từ Firebase Auth
          setState(() => _mssvError = 'Không có mã số sinh viên này ');
      }
    } catch (e) {
      // Lỗi chung (ví dụ: không có mạng, lỗi Firestore...)
      setState(() {
        _mssvError = 'Đã xảy ra lỗi không mong muốn: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mssvController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (Phần UI giữ nguyên)
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/background.png',
                ), // Đảm bảo bạn có ảnh này
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                    ), // Đảm bảo bạn có ảnh này
                    SizedBox(height: 20),
                    Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    SizedBox(height: 30),
                    TextField(
                      controller: _mssvController,
                      decoration: InputDecoration(
                        labelText: 'Mã số sinh viên',
                        hintText: 'Nhập MSSV của bạn',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.badge_outlined),
                        errorText: _mssvError,
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu của bạn',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        errorText: _passwordError,
                      ),
                    ),
                    SizedBox(height: 25),
                    _isLoading
                        ? CircularProgressIndicator()
                        : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Đăng nhập'),
                          ),
                        ),
                    SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        // Navigator.pushNamed(context, '/forgot_password'); // Nếu có màn hình này
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Chức năng quên mật khẩu đang được phát triển!',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
