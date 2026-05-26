import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import 'apply_loan_flow.dart';
import 'loan_data.dart';

/// "Loans" tab — shows the SACCO's real loan product catalogue from the API.
/// Tapping a product opens a detail sheet; eligible members can apply directly.
class LoansCatalogTab extends StatefulWidget {
  const LoansCatalogTab({super.key, required this.authToken});

  final String authToken;

  @override
  State<LoansCatalogTab> createState() => _LoansCatalogTabState();
}

class _LoansCatalogTabState extends State<LoansCatalogTab> {
  bool _loading = true;
  String? _error;
  LoanProductsResponse? _response;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ProsaccoMemberAuthApi();
      final res = await api.fetchLoanProducts(token: widget.authToken);
      if (!mounted) return;
      setState(() { _response = res; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

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

    final products = _response?.products ?? [];

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_outlined,
                  size: 56, color: context.pal.outline.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('No loan products available',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Your SACCO has not published any loan products yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.pal.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = products[i];
          return _ProductCard(
            product: p,
            authToken: widget.authToken,
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.authToken});

  final LoanProductData product;
  final String authToken;

  String _kes(int cents) {
    final v = cents / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(0)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: p.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: product.eligible
                      ? p.secondaryContainer.withValues(alpha: 0.45)
                      : p.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: product.eligible ? p.primary : p.outline,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.productName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: product.eligible
                                      ? p.headlineGreen
                                      : p.outline,
                                ),
                          ),
                        ),
                        if (!product.eligible)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: p.errorContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('INELIGIBLE',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: p.error)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Up to ${product.maxRepaymentMonths} months · '
                      '${product.interestRatePercent.toStringAsFixed(1)}% p.a.',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: p.slateMuted),
                    ),
                    if (product.eligible) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Your limit: ${_kes(product.memberMaxEligibleCents)}',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                              color: p.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.outline),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductDetailSheet(
        product: product,
        authToken: authToken,
      ),
    );
  }
}

class _ProductDetailSheet extends StatelessWidget {
  const _ProductDetailSheet({required this.product, required this.authToken});

  final LoanProductData product;
  final String authToken;

  String _kes(int cents) {
    final v = cents / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(0)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: p.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.outline.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  Text(product.productName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  if (product.description != null) ...[
                    const SizedBox(height: 10),
                    Text(product.description!,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: p.onSurfaceVariant,
                              height: 1.5,
                            )),
                  ],
                  const SizedBox(height: 20),
                  _row(context, 'Min amount', _kes(product.minLoanAmountCents)),
                  _row(context, 'Max amount', _kes(product.maxLoanAmountCents)),
                  _row(context, 'Interest rate',
                      '${product.interestRatePercent.toStringAsFixed(2)}% p.a.'),
                  _row(context, 'Repayment',
                      '${product.minRepaymentMonths}–${product.maxRepaymentMonths} months'),
                  if (product.guarantorsRequired)
                    _row(context, 'Guarantors',
                        '${product.minGuarantors ?? 1}–${product.maxGuarantors ?? 1} required'),
                  if (product.eligible)
                    _row(context, 'Your limit',
                        _kes(product.memberMaxEligibleCents),
                        highlight: true),
                  if (!product.eligible && product.ineligibleReason != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: p.errorContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: p.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: p.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(product.ineligibleReason!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: p.error)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (product.eligible)
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final lp = PersonalLoanProduct(
                          id: product.id,
                          name: product.productName,
                          tagline: product.description ?? '',
                          maxAmount: product.memberMaxEligibleCents / 100.0,
                          minAmount: product.minLoanAmountCents / 100.0,
                          needsGuarantors: product.guarantorsRequired,
                          rateLabel:
                              '${product.interestRatePercent.toStringAsFixed(2)}% p.a.',
                          minGuarantors: product.minGuarantors ?? 1,
                          maxGuarantors: product.maxGuarantors ?? 1,
                          minRepaymentMonths: product.minRepaymentMonths,
                          maxRepaymentMonths: product.maxRepaymentMonths,
                        );
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ApplyLoanFlowScreen(
                              product: lp,
                              authToken: authToken,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: p.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply now',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool highlight = false}) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: p.outline, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: highlight ? p.primary : p.onSurface,
                    )),
          ),
        ],
      ),
    );
  }
}
