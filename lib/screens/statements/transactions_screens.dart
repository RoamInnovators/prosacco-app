import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/balance_visibility.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'statement_models.dart';

class TransactionsPreviewScreen extends StatefulWidget {
  const TransactionsPreviewScreen({
    super.key,
    required this.account,
    required this.authToken,
  });

  final StatementAccount account;
  final String authToken;

  @override
  State<TransactionsPreviewScreen> createState() =>
      _TransactionsPreviewScreenState();
}

class _TransactionsPreviewScreenState
    extends State<TransactionsPreviewScreen> {
  StatementGenerateResult? _result;
  bool _loading = true;
  String? _loadError;

  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month, now.day);
    _load();
  }

  String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final api = ProsaccoMemberAuthApi();
      final result = await api.generateStatement(
        token: widget.authToken,
        accountType: widget.account.backendAccountType ??
            widget.account.id.toUpperCase(),
        from: _fmt(_from),
        to: _fmt(_to),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load transactions.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.headlineGreen,
        elevation: 0,
        title: const Text('Transactions',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: ProsaccoAnimatedLoader(size: 110))
          : _loadError != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_loadError!,
                      style: Theme.of(context).textTheme.bodyMedium))
              : _TxnList(result: _result!),
    );
  }
}

class _TxnList extends StatelessWidget {
  const _TxnList({required this.result});

  final StatementGenerateResult result;

  @override
  Widget build(BuildContext context) {
    final txns = result.transactions;
    if (txns.isEmpty) {
      return Center(
        child: Text('No transactions this period.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.pal.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      itemCount: txns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _TxnCard(txn: txns[i]),
    );
  }
}

class _TxnCard extends StatelessWidget {
  const _TxnCard({required this.txn});

  final StatementTxnRow txn;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isCredit = txn.isCredit;
    final amtColor = isCredit ? p.success : p.onSurface;
    final prefix = isCredit ? '+' : '−';
    final visibility = BalanceVisibilityScope.maybeOf(context);
    final amountLabel = visibility?.formatAmount(
          '$prefix KES ${formatKesMoney(txn.amountKes)}',
          hidden: '••••',
        ) ??
        '$prefix KES ${formatKesMoney(txn.amountKes)}';
    final balanceLabel = txn.balanceAfterKes == null
        ? null
        : (visibility?.formatAmount(
              'Bal: ${formatKesMoney(txn.balanceAfterKes!)}',
              hidden: 'Bal: ••••',
            ) ??
            'Bal: ${formatKesMoney(txn.balanceAfterKes!)}');

    return Container(
      decoration: BoxDecoration(
        color: p.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCredit
                  ? p.success.withValues(alpha: 0.1)
                  : p.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: isCredit ? p.success : p.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.typeLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800, color: p.headlineGreen)),
                const SizedBox(height: 2),
                Text(txn.date,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: p.slateMuted, fontSize: 12)),
                if (txn.reference != null && txn.reference!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(txn.reference!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: p.onSurfaceVariant, fontSize: 11)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900, color: amtColor)),
              if (balanceLabel != null) ...[
                const SizedBox(height: 2),
                Text(balanceLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: p.slateMuted, fontSize: 11)),
              ],
              if (txn.shares != null) ...[
                const SizedBox(height: 2),
                Text('${txn.shares} units',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: p.onSurfaceVariant, fontSize: 11)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
