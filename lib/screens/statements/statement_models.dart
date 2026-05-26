// Sample models for statements & transactions (replace with API).

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

const String kSampleMemberName = 'Samuel K. Maina';
const String kSampleMemberAddress =
    'P.O. Box 40100-00100\nNairobi, Kenya';

final List<StatementAccount> kStatementAccounts = [
  const StatementAccount(
    id: 'bosa',
    name: 'BOSA Savings',
    accountMask: '1004 8829 110',
    balance: 842500,
    tagline: 'Primary savings',
  ),
  const StatementAccount(
    id: 'fosa',
    name: 'FOSA Account',
    accountMask: '2001 4412 889',
    balance: 42300,
    tagline: 'Transactional',
  ),
  const StatementAccount(
    id: 'shares',
    name: 'Share Capital',
    accountMask: 'Member shares',
    balance: 520000,
    tagline: '5,200 units',
  ),
  const StatementAccount(
    id: 'fd',
    name: 'Fixed Deposit',
    accountMask: 'FD 7781 902',
    balance: 310000,
    tagline: '12-month tenor',
  ),
];

StatementSummary sampleSummaryFor(StatementAccount account) {
  final base = account.balance;
  final opening = base * 0.94;
  final credits = base * 0.08;
  final debits = base * 0.02;
  return StatementSummary(
    periodLabel: 'October 01 — October 31, 2025',
    statementDateLabel: 'November 01, 2025',
    openingBalance: opening,
    totalCredits: credits,
    totalDebits: debits,
    closingBalance: base,
    lines: [
      const StatementLine(
        dateLabel: 'Oct 28',
        title: 'M-Pesa contribution',
        subtitle: 'Ref: QW789HKL89',
        credit: 15000,
      ),
      const StatementLine(
        dateLabel: 'Oct 22',
        title: 'Loan repayment',
        subtitle: 'Automatic deduction',
        debit: 10000,
      ),
      const StatementLine(
        dateLabel: 'Oct 15',
        title: 'Dividend distribution',
        subtitle: 'Q3 2025 earnings',
        credit: 42500,
      ),
      const StatementLine(
        dateLabel: 'Oct 05',
        title: 'Monthly deposit',
        subtitle: 'Payroll deduction',
        credit: 5000,
      ),
    ],
    footerId: '${account.id.toUpperCase()}-OCT25',
    generatedAtLabel: '01/11/2025 10:42:15 AM EAT',
  );
}

/// Period totals for hub placeholders.
({double incoming, double outgoing}) sampleFlowTotals(StatementAccount account) {
  return (
    incoming: account.balance * 0.11,
    outgoing: account.balance * 0.04,
  );
}

List<TransferTransaction> sampleTransfersFor(StatementAccount account) {
  return [
    TransferTransaction(
      dateLabel: '28 Oct',
      title: 'M-Pesa contribution',
      subtitle: 'Mobile money',
      fromLabel: 'M-Pesa • 2547••••821',
      toLabel: '${account.name} • ${account.accountMask}',
      amount: 15000,
      isIncoming: true,
    ),
    TransferTransaction(
      dateLabel: '22 Oct',
      title: 'Internal transfer',
      subtitle: 'Member initiated',
      fromLabel: account.name,
      toLabel: 'Loan recovery • Principal',
      amount: 10000,
      isIncoming: false,
    ),
    TransferTransaction(
      dateLabel: '18 Oct',
      title: 'PesaLink transfer in',
      subtitle: 'From another bank',
      fromLabel: 'KCB **** 9012',
      toLabel: '${account.name} • ${account.accountMask}',
      amount: 25000,
      isIncoming: true,
    ),
    TransferTransaction(
      dateLabel: '15 Oct',
      title: 'Dividend credit',
      subtitle: 'Sacco distribution',
      fromLabel: 'ProSacco dividend pool',
      toLabel: account.name,
      amount: 42500,
      isIncoming: true,
    ),
    TransferTransaction(
      dateLabel: '11 Oct',
      title: 'ATM withdrawal',
      subtitle: 'Agent network',
      fromLabel: account.name,
      toLabel: 'Cash • Agent 8821',
      amount: 5000,
      isIncoming: false,
    ),
    TransferTransaction(
      dateLabel: '09 Oct',
      title: 'Standing order',
      subtitle: 'Scheduled debit',
      fromLabel: account.name,
      toLabel: 'BOSA Savings • 1004 **** 110',
      amount: 3200,
      isIncoming: false,
    ),
    TransferTransaction(
      dateLabel: '05 Oct',
      title: 'Salary checkoff',
      subtitle: 'Employer batch',
      fromLabel: 'Employer • ACME Ltd',
      toLabel: '${account.name} • ${account.accountMask}',
      amount: 18400,
      isIncoming: true,
    ),
    TransferTransaction(
      dateLabel: '02 Oct',
      title: 'POS purchase',
      subtitle: 'Retail',
      fromLabel: account.name,
      toLabel: 'Naivas Supermarket',
      amount: 1180,
      isIncoming: false,
    ),
  ];
}
