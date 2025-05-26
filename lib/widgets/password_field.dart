import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool showPassword;
  final VoidCallback onToggleVisibility;
  final String? errorText;
  final VoidCallback? onEditingComplete;
  final String? Function(String?)? validator;

  const PasswordField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.showPassword,
    required this.onToggleVisibility,
    this.errorText,
    this.onEditingComplete,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      onEditingComplete: onEditingComplete,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập $label';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
