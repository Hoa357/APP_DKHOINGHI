import 'dart:math';
import 'dart:async';

class OtpService {
  static String generateOtp() {
    final random = Random();
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  static Future<void> sendOtpEmail(String email, String otp) async {
    // Tích hợp với service email thực tế
    // SendGrid, AWS SES, Firebase Functions, etc.

    try {
      // Ví dụ với HTTP request
      /*
      final response = await http.post(
        Uri.parse('https://your-api.com/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'subject': 'Mã xác thực đổi mật khẩu',
          'message': 'Mã OTP của bạn là: $otp. Mã có hiệu lực trong 5 phút.',
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Không thể gửi email');
      }
      */

      // Demo: delay để giả lập gửi email
      await Future.delayed(Duration(seconds: 2));
      print('OTP được gửi: $otp'); // Debug only
    } catch (e) {
      throw Exception('Lỗi gửi email: ${e.toString()}');
    }
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
