/// Converts a phone number to the synthetic email format used for Supabase
/// email sign-in (n09xxxxxxxxx@gmail.com) when phone sign-in is not available.
const String _signInEmailSuffix = '@gmail.com';

/// Normalizes raw digits to 09xxxxxxxxx (11 chars). Returns null if invalid.
String? _normalizePhoneDigits(String digits) {
  if (digits.length < 10) return null;
  if (digits.startsWith('63') && digits.length == 12) {
    return '0${digits.substring(2)}';
  }
  if (digits.startsWith('9') && digits.length == 10) {
    return '0$digits';
  }
  if (digits.startsWith('09') && digits.length == 11) return digits;
  return null;
}

/// Converts user input to the synthetic email, e.g. n09123456789@gmail.com.
/// Call after [validatePhoneForSignIn] returns null so input is valid.
String phoneToSignInEmail(String input) {
  final digits = input.trim().replaceAll(RegExp(r'\D'), '');
  final normalized = _normalizePhoneDigits(digits);
  final key = normalized ?? (digits.length >= 11 ? '0${digits.substring(digits.length - 10)}' : '0$digits');
  return 'n$key$_signInEmailSuffix';
}

/// Returns normalized phone digits (09xxxxxxxxx) or null if invalid.
String? normalizePhone(String input) {
  final digits = input.trim().replaceAll(RegExp(r'\D'), '');
  return _normalizePhoneDigits(digits);
}

/// Validates that [value] is a phone number we can convert to sign-in email.
/// Returns an error message (Tagalog) or null if valid.
String? validatePhoneForSignIn(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Ilagay ang iyong numero ng telepono.';
  }
  final digits = value.trim().replaceAll(RegExp(r'\D'), '');
  final normalized = _normalizePhoneDigits(digits);
  if (normalized == null) {
    return 'Ilagay ang wastong numero (hal. 09123456789).';
  }
  return null;
}
