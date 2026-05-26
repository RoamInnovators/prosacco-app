import 'package:flutter/material.dart';

import '../theme/prosacco_palette.dart';
import '../utils/prosacco_member_auth_api.dart';
import '../widgets/prosacco_animated_loader.dart';

class HomeAllTransactionsScreen extends StatefulWidget {
  const HomeAllTransactionsScreen({
    super.key,
    required this.authToken,
  });

  final String authToken;

  @override
  State<HomeAllTransactionsScreen> createState() => _HomeAllTransactionsScreenState();
}

class _HomeAllTransactionsScreenState extends State<HomeAllTransactionsScreen> {
  bool _loading = true;
  String? _error;
  List<MemberRecentTransactionData> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final api = ProsaccoMemberAuthApi();
      final rows = await api.fetchMemberRecentTransactions(
        token: widget.authToken,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _transactions = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e?.toString() ?? 'Failed to load transactions.';
        _loading = false;
      });
    }
  }

  String _fmtAmount(int cents) {
    final abs = (cents.abs() / 100).toStringAsFixed(2);
    final parts = abs.split('.');
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
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('All transactions')),
      body: _loading
          ? const Center(child: ProsaccoAnimatedLoader(size: 110))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (_transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'No transactions found.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: p.onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    ..._transactions.map((t) {
                      final credit = t.type.toLowerCase() == 'credit';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                credit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: credit ? p.tertiary : p.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.description,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${t.date} • ${t.account}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: p.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${credit ? '+' : '-'}${_fmtAmount(t.amountCents)}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: credit ? p.tertiary : p.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

