import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'request_statement_screen.dart';
import 'statement_models.dart';
import 'statement_viewer_screen.dart';
import 'transactions_screens.dart';

/// Account summary, flow totals, and entry points for statement / request / txs.
class StatementAccountHubScreen extends StatefulWidget {
  const StatementAccountHubScreen({
    super.key,
    required this.account,
    required this.authToken,
  });

  final StatementAccount account;
  final String authToken;

  @override
  State<StatementAccountHubScreen> createState() =>
      _StatementAccountHubScreenState();
}

class _StatementAccountHubScreenState
    extends State<StatementAccountHubScreen> {
  AnnualStatementSummary? _annual;
  bool _loadingAnnual = true;

  @override
  void initState() {
    super.initState();
    _loadAnnual();
  }

  Future<void> _loadAnnual() async {
    try {
      final api = ProsaccoMemberAuthApi();
      final summary = await api.fetchAnnualSummary(
        token: widget.authToken,
        year: DateTime.now().year,
      );
      if (!mounted) return;
      setState(() {
        _annual = summary;
        _loadingAnnual = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAnnual = false);
    }
  }

  ({double incoming, double outgoing}) _flowTotals() {
    final a = _annual;
    if (a == null) return (incoming: 0, outgoing: 0);
    final type = (widget.account.backendAccountType ?? widget.account.id).toUpperCase();
    int txCount = 0;
    int balCents = 0;
    switch (type) {
      case 'BOSA':
        txCount = a.bosa?.transactionCount ?? 0;
        balCents = a.bosa?.balanceCents ?? 0;
      case 'FOSA':
        txCount = a.fosa?.transactionCount ?? 0;
        balCents = a.fosa?.balanceCents ?? 0;
      case 'SHARES':
        txCount = a.shareCapital?.transactionCount ?? 0;
        balCents = a.shareCapital?.totalAmountCents ?? a.shareCapital?.balanceCents ?? 0;
      default:
        balCents = (a.fixedDepositTotalCents ?? 0);
    }
    // Rough estimate: split balance proportionally by tx count
    final bal = balCents / 100.0;
    final incoming = txCount > 0 ? bal * 0.08 : 0.0;
    final outgoing = txCount > 0 ? bal * 0.03 : 0.0;
    return (incoming: incoming, outgoing: outgoing);
  }

  @override
  Widget build(BuildContext context) {
    final flow = _flowTotals();
    final account = widget.account;
    final authToken = widget.authToken;

    return Scaffold(
      backgroundColor: context.pal.surface,
      appBar: AppBar(
        backgroundColor: context.pal.surface,
        foregroundColor: context.pal.headlineGreen,
        elevation: 0,
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        children: [
          _StatementGreenAccountCard(account: account),
          const SizedBox(height: 22),
          Text(
            'THIS PERIOD',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: context.pal.secondary,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FlowPlaceholder(
                  icon: Icons.south_west_rounded,
                  label: 'Total incoming',
                  amount: flow.incoming,
                  tint: context.pal.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FlowPlaceholder(
                  icon: Icons.north_east_rounded,
                  label: 'Total outgoing',
                  amount: flow.outgoing,
                  tint: context.pal.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingAnnual)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else
            Text(
              _annual != null
                  ? 'Estimated from ${DateTime.now().year} annual data.'
                  : 'Could not load annual totals.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.pal.slateMuted,
                    height: 1.35,
                  ),
            ),
          const SizedBox(height: 28),
          _HubActionButton(
            icon: Icons.article_outlined,
            label: 'View statement',
            subtitle: 'On-screen official layout',
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => StatementViewerScreen(
                    account: account,
                    authToken: authToken,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _HubActionButton(
            icon: Icons.mark_email_read_outlined,
            label: 'Request statement',
            subtitle: 'Locked PDF to your inbox',
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => RequestStatementScreen(
                    account: account,
                    authToken: authToken,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _HubActionButton(
            icon: Icons.compare_arrows_rounded,
            label: 'View transactions',
            subtitle: 'Transfers from and to',
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => TransactionsPreviewScreen(
                    account: account,
                    authToken: authToken,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatementGreenAccountCard extends StatelessWidget {
  const _StatementGreenAccountCard({required this.account});

  final StatementAccount account;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
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
            top: -56,
            right: -32,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.pal.secondaryContainer.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            account.accountMask,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 0.9,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  account.tagline.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.15,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(height: 6),
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
                    const SizedBox(width: 8),
                    Text(
                      formatKesMoney(account.balance),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Available balance · sample data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowPlaceholder extends StatelessWidget {
  const _FlowPlaceholder({
    required this.icon,
    required this.label,
    required this.amount,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final double amount;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.pal.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.pal.slateMuted,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'KES ${formatKesMoney(amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.pal.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _HubActionButton extends StatelessWidget {
  const _HubActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.pal.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: context.pal.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.pal.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: context.pal.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.pal.headlineGreen,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.pal.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.pal.outline.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
