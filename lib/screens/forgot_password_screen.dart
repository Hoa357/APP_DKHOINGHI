import 'package:flutter/material.dart';
import 'dart:async';
import '../services/otp_service.dart';
import '../widgets/password_field.dart';
import '../widgets/password_validation_widget.dart';
import '../models/password_validation.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String) onSuccess;

  const ForgotPasswordScreen({
    Key? key,
    required this.onBack,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _resetPasswordController = TextEditingController();
  final _resetConfirmPasswordController = TextEditingController();

  bool _showResetPassword = false;
  bool _showResetConfirmPassword = false;
  bool _isLoading = false;
  int _forgotPasswordStep = 1;
  String? _generatedOtp;
  int _otpResendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _resetPasswordController.dispose();
    _resetConfirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _otpResendCountdown = 60;
    });
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_otpResendCountdown > 0) {
        setState(() {
          _otpResendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtpEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !OtpService.isValidEmail(email)) {
      _showSnackBar('Vui lòng nhập email hợp lệ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _generatedOtp = OtpService.generateOtp();
      await OtpService.sendOtpEmail(email, _generatedOtp!);
      setState(() => _forgotPasswordStep = 2);
      _startResendCountdown();
      _showSnackBar('Mã OTP đã được gửi đến email của bạn');
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      _showSnackBar('Vui lòng nhập đủ 6 số');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(Duration(seconds: 1));

    if (enteredOtp == _generatedOtp) {
      setState(() => _forgotPasswordStep = 3);
      _showSnackBar('Xác thực thành công!');
    } else {
      _showSnackBar('Mã OTP không đúng. Vui lòng thử lại.');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _resendOtp() async {
    if (_otpResendCountdown > 0) return;
    setState(() => _isLoading = true);

    try {
      _generatedOtp = OtpService.generateOtp();
      await OtpService.sendOtpEmail(
        _emailController.text.trim(),
        _generatedOtp!,
      );
      _startResendCountdown();
      _showSnackBar('Mã OTP mới đã được gửi');
    } catch (e) {
      _showSnackBar('Lỗi gửi lại OTP: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final resetPassword = _resetPasswordController.text.trim();
    final validation = PasswordValidation.validate(resetPassword);

    if (!validation.isValid ||
        resetPassword != _resetConfirmPasswordController.text.trim()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(Duration(seconds: 2));
      widget.onSuccess('Đặt lại mật khẩu thành công!');
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: widget.onBack,
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 16),
                            child: Card(
                              color: Colors.white,
                              elevation: 12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(24, 64, 24, 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Quên mật khẩu',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _getSubtitle(),
                                      style: TextStyle(color: Colors.grey[600]),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 24),
                                    _buildStepContent(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    switch (_forgotPasswordStep) {
      case 1:
        return 'Nhập email để nhận mã xác thực';
      case 2:
        return 'Nhập mã xác thực đã gửi đến email';
      case 3:
        return 'Tạo mật khẩu mới';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_forgotPasswordStep) {
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildOtpStep();
      case 3:
        return _buildResetPasswordStep();
      default:
        return Container();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Nhập email của bạn',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _emailController.text.isNotEmpty && !_isLoading
                    ? _sendOtpEmail
                    : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.blue[600],
            ),
            child:
                _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                      'Gửi mã xác thực',
                      style: TextStyle(color: Colors.white),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, letterSpacing: 4),
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Mã xác thực',
            hintText: 'Nhập mã 6 số',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            counterText: '',
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Không nhận được mã? '),
            TextButton(
              onPressed:
                  _otpResendCountdown == 0 && !_isLoading ? _resendOtp : null,
              child: Text(
                _otpResendCountdown > 0
                    ? 'Gửi lại (${_otpResendCountdown}s)'
                    : 'Gửi lại',
                style: TextStyle(
                  color: _otpResendCountdown > 0 ? Colors.grey : Colors.blue,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _otpController.text.length == 6 && !_isLoading
                    ? _verifyOtp
                    : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.blue[600],
            ),
            child:
                _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Xác thực', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordStep() {
    final validation = PasswordValidation.validate(
      _resetPasswordController.text,
    );

    return Column(
      children: [
        PasswordField(
          controller: _resetPasswordController,
          label: 'Mật khẩu mới',
          hint: 'Nhập mật khẩu mới',
          showPassword: _showResetPassword,
          onToggleVisibility:
              () => setState(() => _showResetPassword = !_showResetPassword),
        ),
        if (_resetPasswordController.text.isNotEmpty) ...[
          SizedBox(height: 8),
          PasswordValidationWidget(validation: validation),
        ],
        SizedBox(height: 16),
        PasswordField(
          controller: _resetConfirmPasswordController,
          label: 'Xác nhận mật khẩu mới',
          hint: 'Xác nhận mật khẩu mới',
          showPassword: _showResetConfirmPassword,
          onToggleVisibility:
              () => setState(
                () => _showResetConfirmPassword = !_showResetConfirmPassword,
              ),
        ),
        if (_resetConfirmPasswordController.text.isNotEmpty &&
            _resetPasswordController.text !=
                _resetConfirmPasswordController.text) ...[
          SizedBox(height: 8),
          Text(
            'Mật khẩu xác nhận không khớp',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                validation.isValid &&
                        _resetPasswordController.text ==
                            _resetConfirmPasswordController.text &&
                        !_isLoading
                    ? _resetPassword
                    : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.blue[600],
            ),
            child:
                _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                      'Đặt lại mật khẩu',
                      style: TextStyle(color: Colors.white),
                    ),
          ),
        ),
      ],
    );
  }
}
