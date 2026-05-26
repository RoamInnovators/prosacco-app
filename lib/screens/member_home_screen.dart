import 'package:flutter/material.dart';

import '../theme/prosacco_palette.dart';
import '../utils/prosacco_member_auth_api.dart';
import '../widgets/prosacco_animated_loader.dart';
import 'home_all_transactions_screen.dart';
import 'loans/member_loans_shell.dart';
import 'member_accounts_screen.dart';
import 'member_notifications_screen.dart';
import 'profile/member_profile_shell.dart';
import 'statements/member_statements_shell.dart';

/// Member dashboard — `prosacco design/home_dashboard/code.html`.
/// Sample figures until `GET /member/me/summary` and recent-transactions are wired.
class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({
    super.key,
    this.displayName = 'Member',
    required this.authToken,
    this.onSignedOut,
  });

  final String displayName;
  final String authToken;
  final VoidCallback? onSignedOut;

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;
  late final TabController _loansTabController;
  bool _showBalance = false;
  bool _loadingHome = true;

  int _bosaBalanceCents = 0;
  int _fosaBalanceCents = 0;
  int _shareCapitalBalanceCents = 0;
  int _activeLoanBalanceCents = 0;
  int _unreadNotificationsCount = 0;
  List<MemberRecentTransactionData> _recentTransactions = const [];

  @override
  void initState() {
    super.initState();
    _loansTabController = TabController(length: 3, vsync: this);
    _loadHomeData();
  }

  @override
  void dispose() {
    _loansTabController.dispose();
    super.dispose();
  }

  static const _navLabels = [
    'Home',
    'Accounts',
    'Loans',
    'Statements',
    'Profile',
  ];

  void _stub(String action) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action — coming soon')),
    );
  }

  Future<void> _loadHomeData() async {
    final token = widget.authToken;
    if (token.isEmpty) return;

    try {
      setState(() => _loadingHome = true);
      final api = ProsaccoMemberAuthApi();
      final summary = await api.fetchMeSummary(token: token);
      final activeLoanCents = await api.fetchActiveLoanBalanceCents(token: token);
      final recent = await api.fetchMemberRecentTransactions(token: token, limit: 25);
      final unread = await api.fetchUnreadNotificationsCount(token: token);

      if (!mounted) return;
      setState(() {
        _bosaBalanceCents = summary.bosaBalanceCents;
        _fosaBalanceCents = summary.fosaBalanceCents;
        _shareCapitalBalanceCents = summary.shareCapitalBalanceCents;
        _activeLoanBalanceCents = activeLoanCents;
        _recentTransactions = recent;
        _unreadNotificationsCount = unread;
        _loadingHome = false;
      });
    } catch (_) {
      // Keep sample defaults visible if API fails.
      if (!mounted) return;
      setState(() => _loadingHome = false);
    }
  }

  String _firstName(String name) {
    final s = name.trim();
    if (s.isEmpty) return 'Member';
    final parts = s.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : s;
  }

  Future<void> _openNotificationsPage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MemberNotificationsScreen(authToken: widget.authToken),
      ),
    );
    if (!mounted) return;
    try {
      final api = ProsaccoMemberAuthApi();
      final unread = await api.fetchUnreadNotificationsCount(token: widget.authToken);
      if (!mounted) return;
      setState(() => _unreadNotificationsCount = unread);
    } catch (_) {}
  }

  Future<void> _openAllTransactionsPage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HomeAllTransactionsScreen(authToken: widget.authToken),
      ),
    );
  }

  void _onQuickChipTap(String label) {
    switch (label) {
      case 'Apply Loan':
        setState(() {
          _navIndex = 2;
          _loansTabController.index = 0;
        });
      case 'Statement':
        setState(() => _navIndex = 3);
      case 'View Guarantor':
        setState(() {
          _navIndex = 2;
          _loansTabController.index = 2;
        });
      case 'Open FD':
        setState(() => _navIndex = 1);
      default:
        _stub(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_navIndex == 1) {
      return Scaffold(
        backgroundColor: context.pal.surface,
        appBar: AppBar(
          backgroundColor: context.pal.surface,
          foregroundColor: context.pal.headlineGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _navIndex = 0),
          ),
          title: const Text('Your Accounts'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _openNotificationsPage,
              icon: const Icon(Icons.notifications_outlined),
              color: context.pal.headlineGreen,
            ),
          ],
        ),
        body: MemberAccountsScreen(
          onActionStub: _stub,
          authToken: widget.authToken,
        ),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    if (_navIndex == 2) {
      return Scaffold(
        backgroundColor: context.pal.surface,
        appBar: AppBar(
          backgroundColor: context.pal.surface,
          foregroundColor: context.pal.headlineGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _navIndex = 0),
          ),
          title: const Text('Loans'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _openNotificationsPage,
              icon: const Icon(Icons.notifications_outlined),
              color: context.pal.headlineGreen,
            ),
          ],
        ),
        body: MemberLoansShell(tabController: _loansTabController, authToken: widget.authToken),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    if (_navIndex == 3) {
      return Scaffold(
        backgroundColor: context.pal.surface,
        appBar: AppBar(
          backgroundColor: context.pal.surface,
          foregroundColor: context.pal.headlineGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _navIndex = 0),
          ),
          title: const Text('Statements'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _openNotificationsPage,
              icon: const Icon(Icons.notifications_outlined),
              color: context.pal.headlineGreen,
            ),
          ],
        ),
        body: MemberStatementsShell(authToken: widget.authToken),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    if (_navIndex == 4) {
      return Scaffold(
        backgroundColor: context.pal.surface,
        appBar: AppBar(
          backgroundColor: context.pal.surface,
          foregroundColor: context.pal.headlineGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _navIndex = 0),
          ),
          title: const Text('Profile & security'),
          centerTitle: true,
        ),
        body: MemberProfileShell(
          authToken: widget.authToken,
          onSignedOut: widget.onSignedOut ?? () {},
        ),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    if (_navIndex != 0) {
      return Scaffold(
        backgroundColor: context.pal.surface,
        appBar: AppBar(
          backgroundColor: context.pal.surface,
          foregroundColor: context.pal.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _navIndex = 0),
          ),
          title: Text(_navLabels[_navIndex]),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${_navLabels[_navIndex]} will connect to member routes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.pal.onSurfaceVariant,
                  ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    return Scaffold(
      backgroundColor: context.pal.surface,
      bottomNavigationBar: _buildBottomNav(context),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AnnouncementBanner(onTap: () => _stub('Announcement')),
            _TopBar(
              displayName: _firstName(widget.displayName),
              onSearch: () => _stub('Search'),
              unreadCount: _unreadNotificationsCount,
              onNotifications: _openNotificationsPage,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                children: [
                  _BalanceHero(
                    fosaBalanceCents: _loadingHome ? 0 : _fosaBalanceCents,
                    showBalance: _showBalance,
                    onToggleBalance: () =>
                        setState(() => _showBalance = !_showBalance),
                    onDeposit: () => setState(() => _navIndex = 1),
                    onTransfer: () => setState(() => _navIndex = 1),
                    onWithdraw: () => setState(() => _navIndex = 1),
                  ),
                  const SizedBox(height: 32),
                  _BentoGrid(
                    bosa: _shortKes(_bosaBalanceCents / 100.0),
                    loans: _shortKes(_activeLoanBalanceCents / 100.0),
                    shares: _shortKes(_shareCapitalBalanceCents / 100.0),
                    fosa: _shortKes(_fosaBalanceCents / 100.0),
                  ),
                  const SizedBox(height: 24),
                  _QuickChips(onChip: _onQuickChipTap),
                  const SizedBox(height: 28),
                  _RecentTransactions(
                    transactions: _recentTransactions.take(5).toList(),
                    loading: _loadingHome,
                    onSeeAll: _openAllTransactionsPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.pal.surface.withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: context.pal.primary.withValues(alpha: 0.05),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: _navIndex == 0,
                filledIcon: true,
                onTap: () => setState(() => _navIndex = 0),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Accounts',
                selected: _navIndex == 1,
                onTap: () => setState(() => _navIndex = 1),
              ),
              _NavItem(
                icon: Icons.payments_outlined,
                label: 'Loans',
                selected: _navIndex == 2,
                onTap: () => setState(() => _navIndex = 2),
              ),
              _NavItem(
                icon: Icons.description_outlined,
                label: 'Statements',
                selected: _navIndex == 3,
                onTap: () => setState(() => _navIndex = 3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: _navIndex == 4,
                onTap: () => setState(() => _navIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ——— Sample aggregates (replace with `/member/me/summary`) ———
const double _kSamplePortfolio = 4820150.00;
const double _kSampleBosa = 1200000;
const double _kSampleLoans = 450000;
const double _kSampleShares = 300000;
const double _kSampleFosa = 2800000;

String _formatThousands(double n) {
  final parts = n.toStringAsFixed(2).split('.');
  final w = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < w.length; i++) {
    if (i > 0 && (w.length - i) % 3 == 0) buf.write(',');
    buf.write(w[i]);
  }
  return '$buf.${parts[1]}';
}

String _shortKes(double v) {
  if (v == 0) return '0';
  if (v >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
  if (v >= 1000) {
    return '${(v / 1000).toStringAsFixed(0)}K';
  }
  return _formatThousands(v);
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.pal.primary,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'New: Apply for the Landmark Asset Loan today and get 2% off interest!',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  height: 1.35,
                ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.displayName,
    required this.onSearch,
    required this.unreadCount,
    required this.onNotifications,
  });

  final String displayName;
  final VoidCallback onSearch;
  final int unreadCount;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLow.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.pal.secondaryContainer,
            ),
            child: Icon(
              Icons.person_rounded,
              color: context.pal.onSecondaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME BACK',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                        color: context.pal.slateMuted,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Hello, $displayName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.pal.headlineGreen,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(width: 6),
                    const _WavingHand(),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
            color: context.pal.slateMuted,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_outlined),
                color: context.pal.headlineGreen,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: context.pal.error,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: context.pal.surface, width: 1.5),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.fosaBalanceCents,
    required this.showBalance,
    required this.onToggleBalance,
    required this.onDeposit,
    required this.onTransfer,
    required this.onWithdraw,
  });

  final int fosaBalanceCents;
  final bool showBalance;
  final VoidCallback onToggleBalance;

  final VoidCallback onDeposit;
  final VoidCallback onTransfer;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final fosaKes = fosaBalanceCents / 100.0;
    final balanceText =
        showBalance ? _formatThousands(fosaKes) : '••••••••';
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
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
          ),
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.pal.secondaryContainer.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.pal.tertiaryFixed,
                          boxShadow: [
                            BoxShadow(
                              color: context.pal.tertiaryFixed
                                  .withValues(alpha: 0.55),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FOSA ACCOUNT',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'FOSA Balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'KES',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          balanceText,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                                height: 1.05,
                              ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleBalance,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        showBalance
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onDeposit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: context.pal.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Deposit',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTransfer,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Transfer',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onWithdraw,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Withdraw',
                          style: TextStyle(fontWeight: FontWeight.w700),
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

class _BentoGrid extends StatelessWidget {
  const _BentoGrid({
    required this.bosa,
    required this.loans,
    required this.shares,
    required this.fosa,
  });

  final String bosa;
  final String loans;
  final String shares;
  final String fosa;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.account_balance_rounded,
                iconBg: const Color(0xFFD1FAE5),
                iconFg: context.pal.primary,
                label: 'BOSA Savings',
                value: bosa,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _BentoTile(
                icon: Icons.payments_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconFg: const Color(0xFFB45309),
                label: 'Active Loans',
                value: loans,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.pie_chart_outline_rounded,
                iconBg: const Color(0xFFDBEAFE),
                iconFg: const Color(0xFF1D4ED8),
                label: 'Share Capital',
                value: shares,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _BentoTile(
                icon: Icons.account_balance_wallet_rounded,
                iconBg: const Color(0xFFEDE9FE),
                iconFg: const Color(0xFF6D28D9),
                label: 'FOSA Balance',
                value: fosa,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.pal.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        splashColor: context.pal.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconFg, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: context.pal.slateMuted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.pal.headlineGreen,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChips extends StatelessWidget {
  const _QuickChips({required this.onChip});

  final void Function(String label) onChip;

  @override
  Widget build(BuildContext context) {
    final chips = [
      (
        Icons.add_card_rounded,
        'Apply Loan',
        true,
      ),
      (
        Icons.description_outlined,
        'Statement',
        false,
      ),
      (
        Icons.group_outlined,
        'View Guarantor',
        false,
      ),
      (
        Icons.lock_outline_rounded,
        'Open FD',
        false,
      ),
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = chips[i];
          return _ActionChip(
            icon: c.$1,
            label: c.$2,
            primary: c.$3,
            onTap: () => onChip(c.$2),
          );
        },
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary
          ? context.pal.secondaryContainer
          : context.pal.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: primary
                ? null
                : Border.all(
                    color: context.pal.outline.withValues(alpha: 0.2),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: primary
                    ? context.pal.onSecondaryContainer
                    : context.pal.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: primary
                          ? context.pal.onSecondaryContainer
                          : context.pal.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({
    required this.transactions,
    required this.loading,
    required this.onSeeAll,
  });

  final List<MemberRecentTransactionData> transactions;
  final bool loading;
  final VoidCallback onSeeAll;

  String _fmtAmount(int cents) {
    final n = (cents.abs() / 100).toStringAsFixed(2);
    final parts = n.split('.');
    final w = parts[0];
    final b = StringBuffer();
    for (var i = 0; i < w.length; i++) {
      if (i > 0 && (w.length - i) % 3 == 0) b.write(',');
      b.write(w[i]);
    }
    return '$b.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.pal.onSurface,
                  ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.pal.primary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: ProsaccoAnimatedLoader(size: 90)),
          )
        else if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No recent transactions available.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.pal.onSurfaceVariant,
                  ),
            ),
          )
        else
          ...transactions.map((t) {
            final credit = t.type.toLowerCase() == 'credit';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TxnRow(
                icon: credit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                iconBg: (credit ? context.pal.tertiary : context.pal.error).withValues(alpha: 0.08),
                iconFg: credit ? context.pal.tertiary : context.pal.error,
                title: t.description,
                subtitle: '${t.date} • ${t.account}',
                amount: '${credit ? '+' : '-'}${_fmtAmount(t.amountCents)}',
                amountColor: credit ? context.pal.tertiary : context.pal.onSurface,
                status: t.account,
              ),
            );
          }),
      ],
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.status,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.pal.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconFg, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.pal.headlineGreen,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
                    amount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: amountColor,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
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

class _TxnSkeletonRow extends StatelessWidget {
  const _TxnSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLowest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                height: 14,
                width: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 10,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.filledIcon = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool filledIcon;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? context.pal.headlineGreen
        : context.pal.slateMuted.withValues(alpha: 0.75);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? context.pal.secondaryContainer.withValues(alpha: 0.45)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                filledIcon ? Icons.home_rounded : icon,
                size: 24,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: fg,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated waving hand emoji that rocks back and forth.
class _WavingHand extends StatefulWidget {
  const _WavingHand();

  @override
  State<_WavingHand> createState() => _WavingHandState();
}

class _WavingHandState extends State<_WavingHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: -0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // Play once on mount, then repeat twice more
    _ctrl.forward().then((_) {
      if (!mounted) return;
      _ctrl.reset();
      _ctrl.forward().then((_) {
        if (!mounted) return;
        _ctrl.reset();
        _ctrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (_, __) => Transform.rotate(
        angle: _rotation.value,
        alignment: Alignment.bottomCenter,
        child: const Text('👋', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
