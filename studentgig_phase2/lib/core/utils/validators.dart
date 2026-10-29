abstract final class Validators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? requiredField(String? value, {String label = 'This field'}) =>
      (value == null || value.trim().isEmpty) ? '$label is required.' : null;

  static String? email(String? value) {
    final error = requiredField(value, label: 'Email');
    if (error != null) return error;
    return _emailPattern.hasMatch(value!.trim())
        ? null
        : 'Enter a valid email address.';
  }

  static String? newPassword(String? value) {
    final error = requiredField(value, label: 'Password');
    if (error != null) return error;
    return value!.length >= 8 ? null : 'Use at least 8 characters.';
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    return value == original ? null : 'Passwords do not match.';
  }
}
