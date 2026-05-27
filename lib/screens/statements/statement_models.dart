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

class StatementSummary {
  const StatementSummary({
    required this.periodLabel,
    required this.statementDateLabel,
    required this.openingBalance,
    required this.totalCredits,
    required this.totalDebits,
    required this.closingBalance,
    required this.lines,
    required this.footerId,
    required this.generatedAtLabel,
  });

  final String periodLabel;
  final String statementDateLabel;
  final double openingBalance;
  final double totalCredits;
  final double totalDebits;
  final double closingBalance;
  final List<StatementLine> lines;
  final String footerId;
  final String generatedAtLabel;
}

class StatementLine {
  const StatementLine({
    required this.dateLabel,
    required this.title,
    required this.subtitle,
    this.debit,
    this.credit,
  });

  final String dateLabel;
  final String title;
  final String subtitle;
  final double? debit;
  final double? credit;
}

class TransferTransaction {
  const TransferTransaction({
    required this.dateLabel,
    required this.title,
    required this.subtitle,
    required this.fromLabel,
    required this.toLabel,
    required this.amount,
    required this.isIncoming,
  });

  final String dateLabel;
  final String title;
  final String subtitle;
  final String fromLabel;
  final String toLabel;
  final double amount;
  final bool isIncoming;
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
