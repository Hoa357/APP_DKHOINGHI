import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/password_validation.dart';
import '../widgets/password_field.dart';
import '../widgets/password_validation_widget.dart';
import '../widgets/success_message.dart';
import 'forgot_password_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _showForgotPassword = false;

  String? _currentPasswordError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(() {
      if (_currentPasswordError != null) {
        setState(() {
          _currentPasswordError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentPassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    if (currentPassword.isEmpty) {
      setState(() {
        _currentPasswordError = 'Vui lòng nhập mật khẩu hiện tại';
      });
      return;
    }

    try {
      await AuthService.checkCurrentPassword(currentPassword);
      setState(() {
        _currentPasswordError = null;
      });
    } catch (e) {
      setState(() {
        _currentPasswordError = e.toString();
      });
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPasswordError != null) {
      _showSnackBar('Vui lòng sửa lỗi mật khẩu hiện tại trước');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newPassword = _newPasswordController.text.trim();
      await AuthService.updatePassword(newPassword);

      setState(() {
        _successMessage = 'Đổi mật khẩu thành công!';
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            message.contains('thành công') ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showForgotPassword) {
      return ForgotPasswordScreen(
        onBack:
            () => setState(() {
              _showForgotPassword = false;
            }),
        onSuccess:
            (message) => setState(() {
              _showForgotPassword = false;
              _successMessage = message;
            }),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.indigo[100]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo trực tiếp
                        Container(
                          child: ClipOval(
                            child: SizedBox(
                              width: 80, // đặt chiều rộng mong muốn
                              height: 80, // đặt chiều cao mong muốn
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        SizedBox(height: 8),

                        SizedBox(height: 24),

                        if (_successMessage != null) ...[
                          SuccessMessage(message: _successMessage!),
                          SizedBox(height: 16),
                        ],

                        PasswordField(
                          controller: _currentPasswordController,
                          label: 'Mật khẩu hiện tại',
                          hint: 'Nhập mật khẩu hiện tại',
                          showPassword: _showCurrentPassword,
                          onToggleVisibility:
                              () => setState(() {
                                _showCurrentPassword = !_showCurrentPassword;
                              }),
                          errorText: _currentPasswordError,
                          onEditingComplete: _checkCurrentPassword,
                        ),
                        SizedBox(height: 16),

                        PasswordField(
                          controller: _newPasswordController,
                          label: 'Mật khẩu mới',
                          hint: 'Nhập mật khẩu mới',
                          showPassword: _showNewPassword,
                          onToggleVisibility:
                              () => setState(() {
                                _showNewPassword = !_showNewPassword;
                              }),
                        ),
                        if (_newPasswordController.text.isNotEmpty) ...[
                          SizedBox(height: 8),
                          PasswordValidationWidget(
                            validation: PasswordValidation.validate(
                              _newPasswordController.text,
                            ),
                          ),
                        ],
                        SizedBox(height: 16),

                        PasswordField(
                          controller: _confirmPasswordController,
                          label: 'Xác nhận mật khẩu mới',
                          hint: 'Xác nhận mật khẩu mới',
                          showPassword: _showConfirmPassword,
                          onToggleVisibility:
                              () => setState(() {
                                _showConfirmPassword = !_showConfirmPassword;
                              }),
                        ),
                        if (_confirmPasswordController.text.isNotEmpty &&
                            _newPasswordController.text !=
                                _confirmPasswordController.text) ...[
                          SizedBox(height: 8),
                          Text(
                            'Mật khẩu xác nhận không khớp',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ],
                        SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                                () => setState(() {
                                  _showForgotPassword = true;
                                }),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Quên mật khẩu?'),
                          ),
                        ),
                        SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _canChangePassword() ? _changePassword : null,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.blue[600],
                            ),
                            child:
                                _isLoading
                                    ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text(
                                      'Đổi mật khẩu',
                                      style: TextStyle(color: Colors.white),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canChangePassword() {
    final validation = PasswordValidation.validate(_newPasswordController.text);
    return validation.isValid &&
        _newPasswordController.text == _confirmPasswordController.text &&
        _currentPasswordError == null &&
        !_isLoading;
  }
}
