import 'package:flutter/material.dart';
import '../models/password_validation.dart';

class PasswordValidationWidget extends StatelessWidget {
  final PasswordValidation validation;

  const PasswordValidationWidget({Key? key, required this.validation})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildValidationItem('Ít nhất 6 ký tự', validation.minLength),
        _buildValidationItem('Có chữ cái viết hoa', validation.hasUppercase),
        _buildValidationItem('Có chữ cái viết thường', validation.hasLowercase),
        _buildValidationItem('Có ít nhất 1 số', validation.hasNumber),
      ],
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(Icons.check, size: 16, color: isValid ? Colors.green : Colors.red),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isValid ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
