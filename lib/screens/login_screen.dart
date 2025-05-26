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
    // Theo dõi thay đổi và xóa lỗi khi nhập
    _mssvController.addListener(() {
      if (_mssvError != null) {
        setState(() {
          _mssvError =
              _mssvController.text.isEmpty
                  ? 'Vui lòng điền mã sinh viên'
                  : null;
        });
      }
    });
    _passwordController.addListener(() {
      if (_passwordError != null) {
        setState(() {
          _passwordError =
              _passwordController.text.isEmpty
                  ? 'Vui lòng điền mật khẩu'
                  : null;
        });
      }
    });
  }

  Future<void> _login() async {
    final mssv = _mssvController.text.trim();
    final password = _passwordController.text;

    // Kiểm tra rỗng ngay lập tức
    setState(() {
      _mssvError = mssv.isEmpty ? 'Vui lòng điền mã sinh viên' : null;
      _passwordError = password.isEmpty ? 'Vui lòng điền mật khẩu' : null;
    });

    if (_mssvError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Kiểm tra mã số sinh viên trong Firestore
      final firestore = FirebaseFirestore.instance;
      final querySnapshot =
          await firestore
              .collection('students')
              .where('mssv', isEqualTo: mssv)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _mssvError = 'Mã số sinh viên không tồn tại';
          _isLoading = false;
        });
        return;
      }

      final studentDoc = querySnapshot.docs.first;
      final email = studentDoc['email'] as String?;

      if (email == null || email.isEmpty) {
        setState(() {
          _mssvError = 'Dữ liệu email không hợp lệ';
          _isLoading = false;
        });
        return;
      }

      // Thực hiện đăng nhập với Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Đăng nhập thành công
      setState(() {
        _mssvError = null;
        _passwordError = null;
      });
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'wrong-password':
            _passwordError = 'Sai mật khẩu';
            break;
          case 'user-not-found':
            _mssvError = 'Tài khoản không tồn tại trong hệ thống';
            break;
          case 'invalid-email':
            _mssvError = 'Email không hợp lệ';
            break;
          case 'too-many-requests':
            _mssvError = 'Quá nhiều yêu cầu, vui lòng thử lại sau';
            break;
          default:
            _mssvError = 'Lỗi đăng nhập: ${e.message ?? e.code}';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _mssvError = 'Lỗi không xác định: ${e.toString()}';
        _isLoading = false;
      });
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
    return Scaffold(
      body: Stack(
        children: [
          // Hình nền
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Form đăng nhập
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
                    Image.asset('assets/images/logo.png', height: 100),
                    SizedBox(height: 20),
                    Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30),
                    TextField(
                      controller: _mssvController,
                      onChanged: (value) {
                        if (_mssvError != null) {
                          setState(() {
                            _mssvError =
                                value.isEmpty
                                    ? 'Vui lòng điền mã sinh viên'
                                    : null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Mã số sinh viên',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                        errorText: _mssvError,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (value) {
                        if (_passwordError != null) {
                          setState(() {
                            _passwordError =
                                value.isEmpty ? 'Vui lòng điền mật khẩu' : null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
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
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              textStyle: TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Đăng nhập'),
                          ),
                        ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot_password');
                      },
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: Colors.blue),
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
