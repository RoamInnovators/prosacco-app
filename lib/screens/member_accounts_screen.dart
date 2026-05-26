import 'package:flutter/material.dart';

import '../theme/prosacco_palette.dart';
import '../utils/prosacco_member_auth_api.dart';
import '../widgets/prosacco_animated_loader.dart';
import 'accounts/buy_shares_screen.dart';
import 'accounts/deposit_screen.dart';
import 'accounts/transfer_hub_screen.dart';
import 'accounts/withdraw_screen.dart';

/// Accounts overview — horizontal account cards (home-style green hero), actions, activity.
class MemberAccountsScreen extends StatefulWidget {
  const MemberAccountsScreen({
    super.key,
    required this.onActionStub,
    required this.authToken,
  });

  final void Function(String label) onActionStub;
  final String authToken;

  @override
  State<MemberAccountsScreen> createState() => _MemberAccountsScreenState();
}

class _MemberAccountsScreenState extends State<MemberAccountsScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;
  late List<bool> _balanceHidden;

  List<_AccountSlide> _accountSlides = _kEmptyAccountSlides;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _balanceHidden = List<bool>.filled(_accountSlides.length, true);
    _pageController = PageController(
      viewportFraction: 0.86,
      initialPage: 0,
    );
    _loadAccounts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  _AccountSlide? get _current =>
      _accountSlides.isEmpty ? null : _accountSlides[_pageIndex];

  Future<void> _loadAccounts() async {
    final token = widget.authToken;
    if (token.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      setState(() => _loadError = 'Missing auth token. Please sign in again.');
      setState(() => _accountSlides = _kEmptyAccountSlides);
      return;
    }

    try {
      setState(() => _loading = true);
      final api = ProsaccoMemberAuthApi();
      final overview = await api.fetchMemberAccountsOverview(token: token);

      final slides = <_AccountSlide>[
        _slideFromBosa(overview.bosa),
        _slideFromFosa(overview.fosa),
        _slideFromShareCapital(overview.shareCapital),
      ];

      // Show up to 2 fixed deposits.
      if (overview.fixedDeposits.deposits.isEmpty) {
        slides.add(_fallbackFdSlide());
      } else {
        slides.addAll(
          overview.fixedDeposits.deposits
              .take(2)
              .map((d) => _slideFromFixedDeposit(d))
              .toList(),
        );
      }

      // Show up to 2 special savings accounts.
      final specials = overview.specialSavings.accounts;
      if (specials is List && specials.isNotEmpty) {
        slides.addAll(
          specials.take(2).map((s) => _slideFromSpecialSavings(s)).toList(),
        );
      }

      if (!mounted) return;
      setState(() {
        _accountSlides = slides;
        _balanceHidden = List<bool>.filled(_accountSlides.length, true);
        _pageIndex = 0;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e?.toString() ?? 'Failed to load accounts from server.';
        _accountSlides = _kEmptyAccountSlides;
        _balanceHidden = List<bool>.filled(_accountSlides.length, true);
        _pageIndex = 0;
      });
    }
  }

  double _kesFromCents(int cents) => cents / 100.0;

  String _maskAccount(String prefix, String accountNumber) {
    final s = accountNumber.trim();
    if (s.isEmpty) return prefix;
    final last4 = s.length >= 4 ? s.substring(s.length - 4) : s;
    return '$prefix •••• $last4';
  }

  String _monthShort(dynamic dateValue) {
    final dt = _tryParseDate(dateValue);
    if (dt == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[dt.month - 1];
  }

  DateTime? _tryParseDate(dynamic dateValue) {
    try {
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String && dateValue.isNotEmpty) {
        return DateTime.parse(dateValue);
      }
    } catch (_) {}
    return null;
  }

  _AccountSlide _fallbackFdSlide() {
    return _AccountSlide(
      name: 'Fixed Deposit',
      accountMask: 'FD',
      balance: 0,
      tagline: 'No active fixed deposits',
      transactions: <_FlowTxn>[],
    );
  }

  _AccountSlide _slideFromBosa(dynamic bosa) {
    final account = bosa.account;
    final balanceCents = account?.balanceCents ?? 0;
    final name = account?.productName?.isNotEmpty == true
        ? 'BOSA Savings'
        : 'BOSA Savings';
    final accountMask = _maskAccount('ACC', account?.accountNumber ?? '');
    final tagline = account == null
        ? 'No active BOSA'
        : (account.interestRatePercent != null
            ? '${account.interestRatePercent}% interest'
            : 'Primary savings');

    final List<_FlowTxn> txns = bosa.transactions
        .take(6)
        .map<_FlowTxn>((t) => _flowTxnFromBosaTxn(t))
        .toList();

    return _AccountSlide(
      name: name,
      accountMask: accountMask,
      balance: _kesFromCents(balanceCents),
      tagline: tagline,
      transactions: txns,
    );
  }

  _FlowTxn _flowTxnFromBosaTxn(dynamic t) {
    final incoming = t.creditCents != null && t.debitCents == null;
    final amountCents = incoming ? t.creditCents ?? 0 : t.debitCents ?? 0;
    return _FlowTxn(
      incoming: incoming,
      title: t.desc,
      subtitle: '${_monthShort(t.date)} • ${incoming ? 'Credit' : 'Debit'}',
      amountLabel:
          '${incoming ? '+ ' : '- '}${_formatMoney2(_kesFromCents(amountCents))}',
      footNote: (t.paymentMethod ?? t.reference ?? '').toString().trim(),
    );
  }

  _AccountSlide _slideFromFosa(dynamic fosa) {
    final account = fosa.account;
    final balanceCents = account?.balanceCents ?? 0;
    final accountMask = _maskAccount('ACC', account?.accountNumber ?? '');
    final tagline = account == null ? 'No active FOSA' : 'Transactional';
    final List<_FlowTxn> txns = fosa.transactions
        .take(6)
        .map<_FlowTxn>((t) => _flowTxnFromFosaTxn(t))
        .toList();

    return _AccountSlide(
      name: 'FOSA Account',
      accountMask: accountMask,
      balance: _kesFromCents(balanceCents),
      tagline: tagline,
      transactions: txns,
    );
  }

  _FlowTxn _flowTxnFromFosaTxn(dynamic t) {
    final incoming = t.creditCents != null && t.debitCents == null;
    final amountCents = incoming ? t.creditCents ?? 0 : t.debitCents ?? 0;
    return _FlowTxn(
      incoming: incoming,
      title: t.desc,
      subtitle: '${_monthShort(t.date)} • ${incoming ? 'Credit' : 'Debit'}',
      amountLabel:
          '${incoming ? '+ ' : '- '}${_formatMoney2(_kesFromCents(amountCents))}',
      footNote: (t.paymentMethod ?? t.reference ?? '').toString().trim(),
    );
  }

  _AccountSlide _slideFromShareCapital(
    dynamic share, {
    int maxTxns = 4,
  }) {
    final account = share.account;
    final balanceCents = account?.totalAmountCents ?? 0;
    final units = account?.totalShares ?? 0;
    final accountMask = 'Shares';
    final tagline = units > 0 ? '$units units' : 'No active shares';

    final List<_FlowTxn> txns = share.transactions.take(maxTxns).map<_FlowTxn>((t) {
      final type = t.typeLabel;
      final incoming = type.toLowerCase().contains('purchase');
      final amountKes = _kesFromCents(t.amountCents);
      return _FlowTxn(
        incoming: incoming,
        title: type,
        subtitle: '${_monthShort(t.date)} • ${incoming ? 'Credit' : 'Debit'}',
        amountLabel: '${incoming ? '+ ' : '- '}${_formatMoney2(amountKes)}',
        footNote: '${t.shares} units',
      );
    }).toList();

    return _AccountSlide(
      name: 'Share Capital',
      accountMask: accountMask,
      balance: _kesFromCents(balanceCents),
      tagline: tagline,
      transactions: txns,
    );
  }

  _AccountSlide _slideFromSpecialSavings(dynamic special) {
    final row = special;
    final balanceCents = row.balanceCents ?? 0;
    final productName = row.productName?.toString() ?? 'Special Savings';
    final accountNumber = row.accountNumber?.toString() ?? '';
    final label = row.label?.toString();
    final status = row.status?.toString();

    return _AccountSlide(
      name: productName,
      accountMask: _maskAccount('ACC', accountNumber),
      balance: balanceCents is num
          ? _kesFromCents(balanceCents.toInt())
          : 0,
      tagline: label != null && label.isNotEmpty
          ? label
          : (status != null && status.isNotEmpty ? status : 'Special'),
      transactions: const <_FlowTxn>[],
    );
  }

  _AccountSlide _slideFromFixedDeposit(dynamic d) {
    final accountMask = _maskAccount('FD', d.accountNumber);
    final balanceCents = d.principalCents;
    final tagline = d.termMonths != null
        ? '${d.termMonths} months'
        : 'Fixed Deposit';
    return _AccountSlide(
      name: d.productName,
      accountMask: accountMask,
      balance: _kesFromCents(balanceCents),
      tagline: tagline,
      transactions: const <_FlowTxn>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: ProsaccoAnimatedLoader(size: 110),
        ),
      );
    }

    if (_loadError != null && _accountSlides.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load your accounts.\n$_loadError',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      );
    }

    final current = _current;
    final txns = current?.transactions ?? const <_FlowTxn>[];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: Text(
              'Swipe to switch accounts. Quick actions use the highlighted card for context.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.pal.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 232,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _accountSlides.length,
              onPageChanged: (i) => setState(() => _pageIndex = i),
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _AccountGreenCard(
                    slide: _accountSlides[i],
                    balanceHidden: _balanceHidden[i],
                    onToggleBalance: () => setState(() {
                      _balanceHidden[i] = !_balanceHidden[i];
                    }),
                  ),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                    _accountSlides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _pageIndex ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _pageIndex
                        ? context.pal.primary
                        : context.pal.outline.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildActionStrip(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'Recent activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.pal.onSurface,
                  ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final t = txns[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FlowTxnRow(txn: t),
                );
              },
              childCount: txns.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionStrip(BuildContext context) {
    final currentName = _current?.name ?? '';
    final isShareCapital = currentName == 'Share Capital';

    final actions = <(IconData, String)>[
      isShareCapital
          ? (Icons.bar_chart_rounded, 'Buy Shares')
          : (Icons.savings_outlined, 'Deposit'),
      (Icons.payments_outlined, 'Withdraw'),
      (Icons.swap_horiz_rounded, 'Transfer'),
    ];

    Future<void> open(Widget page) async {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
      if (!mounted) return;
      await _loadAccounts();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: actions.map((a) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _ActionChip(
              icon: a.$1,
              label: a.$2,
              onTap: () {
                switch (a.$2) {
                  case 'Deposit':
                    open(DepositScreen(authToken: widget.authToken));
                  case 'Buy Shares':
                    open(BuySharesScreen(authToken: widget.authToken));
                  case 'Withdraw':
                    open(WithdrawScreen(authToken: widget.authToken));
                  case 'Transfer':
                    open(TransferHubScreen(authToken: widget.authToken));
                  default:
                    widget.onActionStub(
                        '${a.$2} (${_current?.name ?? 'Account'})');
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ——— Models & sample data (replace with `/member/accounts/*`) ———

class _AccountSlide {
  const _AccountSlide({
    required this.name,
    required this.accountMask,
    required this.balance,
    required this.tagline,
    required this.transactions,
  });

  final String name;
  final String accountMask;
  final double balance;
  final String tagline;
  final List<_FlowTxn> transactions;
}

class _FlowTxn {
  const _FlowTxn({
    required this.incoming,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.footNote,
  });

  final bool incoming;
  final String title;
  final String subtitle;
  final String amountLabel;
  final String footNote;
}

final List<_AccountSlide> _kFallbackAccountSlides = [
  _AccountSlide(
    name: 'BOSA Savings',
    accountMask: 'ACC •••• 9110',
    balance: 842500,
    tagline: 'Primary savings',
    transactions: [
      _FlowTxn(
        incoming: true,
        title: 'Salary checkoff',
        subtitle: 'Today • Credit',
        amountLabel: '+ 18,400.00',
        footNote: 'Completed',
      ),
      _FlowTxn(
        incoming: false,
        title: 'ATM withdrawal',
        subtitle: 'Yesterday • Debit',
        amountLabel: '- 5,000.00',
        footNote: 'Agent',
      ),
      _FlowTxn(
        incoming: true,
        title: 'Dividend allocation',
        subtitle: 'Mon • Credit',
        amountLabel: '+ 12,500.00',
        footNote: 'Posted',
      ),
      _FlowTxn(
        incoming: false,
        title: 'Standing order',
        subtitle: 'Sun • Debit',
        amountLabel: '- 3,200.00',
        footNote: 'Auto',
      ),
    ],
  ),
  _AccountSlide(
    name: 'FOSA Account',
    accountMask: 'ACC •••• 3344',
    balance: 42300,
    tagline: 'Transactional',
    transactions: [
      _FlowTxn(
        incoming: false,
        title: 'M-Pesa send',
        subtitle: 'Today • Debit',
        amountLabel: '- 2,500.00',
        footNote: 'PesaLink',
      ),
      _FlowTxn(
        incoming: true,
        title: 'Internal transfer in',
        subtitle: 'Yesterday • Credit',
        amountLabel: '+ 10,000.00',
        footNote: 'From BOSA',
      ),
      _FlowTxn(
        incoming: false,
        title: 'POS purchase',
        subtitle: 'Sat • Debit',
        amountLabel: '- 1,180.00',
        footNote: 'Retail',
      ),
    ],
  ),
  _AccountSlide(
    name: 'Share Capital',
    accountMask: 'Member shares',
    balance: 520000,
    tagline: '5,200 units',
    transactions: [
      _FlowTxn(
        incoming: true,
        title: 'Share purchase',
        subtitle: 'Oct • Credit',
        amountLabel: '+ 25,000.00',
        footNote: 'Units',
      ),
      _FlowTxn(
        incoming: false,
        title: 'Transfer to savings',
        subtitle: 'Sep • Debit',
        amountLabel: '- 8,000.00',
        footNote: 'Redeem',
      ),
    ],
  ),
  _AccountSlide(
    name: 'Fixed Deposit',
    accountMask: 'FD •••• 7781',
    balance: 310000,
    tagline: '12-month tenor',
    transactions: [
      _FlowTxn(
        incoming: true,
        title: 'Interest accrual',
        subtitle: 'Month end • Credit',
        amountLabel: '+ 4,120.00',
        footNote: 'Accrued',
      ),
      _FlowTxn(
        incoming: false,
        title: 'Principal lock',
        subtitle: 'Open • Debit',
        amountLabel: '- 300,000.00',
        footNote: 'Placement',
      ),
    ],
  ),
];

const List<_AccountSlide> _kEmptyAccountSlides = <_AccountSlide>[];

String _formatMoney2(double n) {
  final parts = n.toStringAsFixed(2).split('.');
  final w = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < w.length; i++) {
    if (i > 0 && (w.length - i) % 3 == 0) buf.write(',');
    buf.write(w[i]);
  }
  return '$buf.${parts[1]}';
}

class _AccountGreenCard extends StatelessWidget {
  const _AccountGreenCard({
    required this.slide,
    required this.balanceHidden,
    required this.onToggleBalance,
  });

  final _AccountSlide slide;
  final bool balanceHidden;
  final VoidCallback onToggleBalance;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.pal.primary,
                  context.pal.primaryContainer,
                ],
              ),
            ),
          ),
          Positioned(
            top: -48,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.pal.secondaryContainer.withValues(alpha: 0.18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide.accountMask,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: onToggleBalance,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                balanceHidden
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  slide.tagline.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'KES',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          balanceHidden ? '••••••' : _formatMoney2(slide.balance),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.pal.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.pal.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: context.pal.primary, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.pal.headlineGreen,
                      height: 1.1,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowTxnRow extends StatelessWidget {
  const _FlowTxnRow({required this.txn});

  final _FlowTxn txn;

  @override
  Widget build(BuildContext context) {
    final arrowBg = txn.incoming
        ? context.pal.tertiary.withValues(alpha: 0.12)
        : context.pal.error.withValues(alpha: 0.1);
    final arrowFg =
        txn.incoming ? context.pal.tertiary : context.pal.error;
    final amountColor =
        txn.incoming ? context.pal.tertiary : context.pal.error;

    return Material(
      color: context.pal.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: arrowBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  txn.incoming
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: arrowFg,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.pal.headlineGreen,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      txn.subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.pal.slateMuted,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    txn.amountLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: amountColor,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    txn.footNote.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: context.pal.slateMuted.withValues(
                            alpha: 0.85,
                          ),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
