import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import 'guarantor_request_detail_screen.dart';

/// Guarantor requests tab — loads live data from GET /member/loans/guarantor/inbox.
class GuarantorInboxTab extends StatefulWidget {
  const GuarantorInboxTab({super.key, required this.authToken});

  final String authToken;

  @override
  State<GuarantorInboxTab> createState() => _GuarantorInboxTabState();
}

class _GuarantorInboxTabState extends State<GuarantorInboxTab> {
  bool _loading = true;
  String? _error;
  List<GuarantorInboxItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ProsaccoMemberAuthApi();
      final items = await api.fetchGuarantorInbox(token: widget.authToken);
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: context.pal.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 56, color: context.pal.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('No pending requests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('You have no guarantor requests awaiting your review.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.pal.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('PENDING APPROVALS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  letterSpacing: 1.4, color: context.pal.secondary)),
          const SizedBox(height: 8),
          Text('Help your peers grow.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: context.pal.primary)),
          const SizedBox(height: 8),
          Text('Review loan requests from members seeking your guarantee.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.pal.onSurfaceVariant)),
          const SizedBox(height: 24),
          ..._items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _InboxCard(
              item: item,
              authToken: widget.authToken,
              onActioned: _load,
            ),
          )),
        ],
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.item,
    required this.authToken,
    required this.onActioned,
  });

  final GuarantorInboxItem item;
  final String authToken;
  final VoidCallback onActioned;

  String _money(int cents) {
    final v = cents / 100.0;
    final s = v.toStringAsFixed(2).split('.');
    final w = s[0];
    final buf = StringBuffer();
    for (var i = 0; i < w.length; i++) {
      if (i > 0 && (w.length - i) % 3 == 0) buf.write(',');
      buf.write(w[i]);
    }
    return '$buf.${s[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final urgent = item.isUrgent;
    const amber = Color(0xFFF59E0B);

    return Material(
      color: context.pal.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: urgent ? amber : Colors.transparent,
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
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
                        Text('BORROWER',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10, fontWeight: FontWeight.w800,
                                letterSpacing: 1.2, color: context.pal.slateMuted)),
                        Text(item.borrowerMemberNumber,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: urgent
                          ? amber.withValues(alpha: 0.12)
                          : context.pal.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          urgent ? Icons.timer_rounded : Icons.calendar_today_rounded,
                          size: 14,
                          color: urgent ? amber : context.pal.slateMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(item.expiryLabel.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 9, fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: urgent ? amber : context.pal.slateMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _miniCell(context, 'Product', item.productName)),
                  const SizedBox(width: 12),
                  Expanded(child: _miniCell(context, 'Your lock',
                      'KES ${_money(item.requiredLockCents)}')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LOAN AMOUNT',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              color: context.pal.slateMuted)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('KES ',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.pal.slateMuted)),
                          Text(_money(item.requestedAmountCents),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                  FilledButton(
                    onPressed: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (ctx) => GuarantorRequestDetailScreen(
                            item: item,
                            authToken: authToken,
                          ),
                        ),
                      );
                      onActioned();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.pal.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Review',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniCell(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  letterSpacing: 1, color: context.pal.slateMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: label == 'Product'
                      ? context.pal.primary
                      : context.pal.onSurface)),
        ],
      ),
    );
  }
}
