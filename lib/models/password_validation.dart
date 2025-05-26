class PasswordValidation {
  final bool isValid;
  final bool minLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;

  PasswordValidation({
    required this.isValid,
    required this.minLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
  });

  factory PasswordValidation.validate(String password) {
    final minLength = password.length >= 6;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    return PasswordValidation(
      isValid: minLength && hasUppercase && hasLowercase && hasNumber,
      minLength: minLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
    );
  }
}
