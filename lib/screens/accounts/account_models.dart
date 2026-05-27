/// Account picker model for money movement screens (loaded from API).
class MemberAccountOption {
  const MemberAccountOption({
    required this.id,
    required this.name,
    required this.mask,
    required this.balance,
  });

  final String id;
  final String name;
  final String mask;
  final double balance;
}

String formatKes(double n) {
  final parts = n.toStringAsFixed(2).split('.');
  final w = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < w.length; i++) {
    if (i > 0 && (w.length - i) % 3 == 0) buf.write(',');
    buf.write(w[i]);
  }
  return '$buf.${parts[1]}';
}
