// Models for statements & transactions.

class StatementAccount {
  const StatementAccount({
    required this.id,
    required this.name,
    required this.accountMask,
    required this.balance,
    required this.tagline,
    this.backendAccountType,
  });

  final String id;
  final String name;
  final String accountMask;
  final double balance;
  final String tagline;

  /// Backend statement account type expected by `/member/statements/*` endpoints.
  /// Examples: `BOSA`, `FOSA`, `SHARES`, `FD`.
  final String? backendAccountType;
}

String formatKesMoney(double n) {
  final parts = n.abs().toStringAsFixed(2).split('.');
  final w = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < w.length; i++) {
    if (i > 0 && (w.length - i) % 3 == 0) buf.write(',');
    buf.write(w[i]);
  }
  return '$buf.${parts[1]}';
}
