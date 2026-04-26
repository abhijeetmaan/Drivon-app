// Shared validation for email / phone login identifiers and passwords.

final _emailRegex = RegExp(r'^[\w.+-]+@[\w.-]+\.\w{2,}$');

bool isValidEmailFormat(String value) {
  final v = value.trim();
  return _emailRegex.hasMatch(v);
}

bool isValidPhoneFormat(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 10;
}

/// Accepts email (with @) or phone (10+ digits after stripping).
String? validateLoginId(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return 'Enter your email or phone number';
  }
  final s = raw.trim();
  if (s.contains('@')) {
    if (!isValidEmailFormat(s)) return 'Enter a valid email address';
    return null;
  }
  if (!isValidPhoneFormat(s)) {
    return 'Enter a valid phone number (at least 10 digits)';
  }
  return null;
}

String? validatePasswordSignup(String? raw, {int minLength = 6}) {
  if (raw == null || raw.isEmpty) return 'Password is required';
  if (raw.length < minLength) return 'Password must be at least $minLength characters';
  return null;
}

String? validatePasswordLogin(String? raw) {
  if (raw == null || raw.isEmpty) return 'Password is required';
  return null;
}

String normalizeLoginId(String raw) {
  final s = raw.trim();
  if (s.contains('@')) return s.toLowerCase();
  return s.replaceAll(RegExp(r'\D'), '');
}
