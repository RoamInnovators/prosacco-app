/// Demo accounts for pickers & balance checks (replace with API).
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

const List<MemberAccountOption> kMemberAccountOptions = [
  MemberAccountOption(
    id: 'bosa',
    name: 'BOSA Savings',
    mask: 'ACC •••• 9110',
    balance: 842500,
  ),
  MemberAccountOption(
    id: 'fosa',
    name: 'FOSA Account',
    mask: 'ACC •••• 3344',
    balance: 42300,
  ),
  MemberAccountOption(
    id: 'shares',
    name: 'Share Capital',
    mask: 'Member shares',
    balance: 520000,
  ),
  MemberAccountOption(
    id: 'fd',
    name: 'Fixed Deposit',
    mask: 'FD •••• 7781',
    balance: 310000,
  ),
];

/// Kenyan banks for PesaLink-style transfers (sample list).
const List<String> kKenyanBanks = [
  'Equity Bank',
  'KCB Bank',
  'Co-operative Bank',
  'Absa Bank Kenya',
  'NCBA Bank',
  'Stanbic Bank',
  'I&M Bank',
  'DTB Kenya',
  'Standard Chartered',
  'Family Bank',
  'Sidian Bank',
  'Bank of Africa',
  'Prime Bank',
  'Credit Bank',
  'HFC Bank',
  'Victoria Commercial Bank',
  'M-Oriental Bank',
  'SBM Bank Kenya',
];

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

MemberAccountOption? accountById(String id) {
  for (final a in kMemberAccountOptions) {
    if (a.id == id) return a;
  }
  return null;
}
