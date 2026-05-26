/// Builds a privacy-safe hint for "where we sent the code" copy.
String otpDestinationHint(String? raw) {
  if (raw == null || raw.isEmpty) {
    return 'your registered email or phone';
  }
  final s = raw.trim();
  if (s.contains('@')) {
    final parts = s.split('@');
    if (parts.length != 2) return 'your registered email';
    final local = parts[0];
    final domain = parts[1];
    if (local.isEmpty) return '•••@$domain';
    if (local.length == 1) return '$local•••@$domain';
    return '${local.substring(0, 1)}••••@$domain';
  }
  if (s.length <= 4) return 'your member record';
  return '${s.substring(0, 2)}•••${s.substring(s.length - 2)}';
}
