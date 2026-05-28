import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import 'apply_loan_flow.dart';
import 'loan_data.dart';
import 'loan_report_tab.dart';

/// "Personal Loans" top-level tab — loads real products and applications from API.
class PersonalLoansTab extends StatefulWidget {
  const PersonalLoansTab({super.key, required this.authToken});

  final String authToken;

  @override
  State<PersonalLoansTab> createState() => _PersonalLoansTabState();
}

class _PersonalLoansTabState extends State<PersonalLoansTab> {
  bool _loading = true;
  String? _error;
  LoanProductsResponse? _productsResponse;
  List<LoanApplicationData> _applications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ProsaccoMemberAuthApi();
      final results = await Future.wait([
        api.fetchLoanProducts(token: widget.authToken),
        api.fetchLoanApplications(token: widget.authToken),
      ]);
      if (!mounted) return;
      setState(() {
        _productsResponse = results[0] as LoanProductsResponse;
        _applications = results[1] as List<LoanApplicationData>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.pal.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final prereq = _productsResponse!;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: context.pal.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.pal.outline.withValues(alpha: 0.12)),
              ),
              child: TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: context.pal.slateMuted,
                indicator: BoxDecoration(
                  color: context.pal.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
                tabs: const [
                  Tab(text: 'My Loans'),
                  Tab(text: 'Apply Loan'),
                  Tab(text: 'My Applications'),
                  Tab(text: 'Loan Report'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MyLoansList(applications: _applications),
                _ApplyLoanList(
                  productsResponse: prereq,
                  authToken: widget.authToken,
                ),
                _MyApplicationsList(applications: _applications),
                LoanReportTab(authToken: widget.authToken, applications: _applications),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Loans ──────────────────────────────────────────────────────────────────

class _MyLoansList extends StatelessWidget {
  const _MyLoansList({required this.applications});

  final List<LoanApplicationData> applications;

  String _money(int cents) {
    final s = (cents / 100).toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Show only disbursed/active loans
    final activeLoans = applications
        .where((a) =>
            a.loanAccountStatus == 'ACTIVE' ||
            a.status == 'DISBURSED')
        .toList();

    if (activeLoans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payments_outlined,
                  size: 48,
                  color: context.pal.primary.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text('No active loans',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Your active loans will appear here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.pal.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: activeLoans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final l = activeLoans[i];
        final balanceCents = l.loanAccountBalanceCents ?? 0;
        final principalCents = l.requestedAmountCents;
        final progress = principalCents > 0
            ? 1.0 - (balanceCents / principalCents).clamp(0.0, 1.0)
            : 1.0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.pal.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: context.pal.outline.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l.productName ?? l.publicLoanId ?? 'Loan',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.pal.headlineGreen),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.pal.secondaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.pal.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Principal KES ${_money(principalCents)} • Outstanding KES ${_money(balanceCents)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.pal.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: context.pal.surfaceContainerLow,
                  color: context.pal.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Apply Loan ────────────────────────────────────────────────────────────────

class _ApplyLoanList extends StatelessWidget {
  const _ApplyLoanList({
    required this.productsResponse,
    required this.authToken,
  });

  final LoanProductsResponse productsResponse;
  final String authToken;

  @override
  Widget build(BuildContext context) {
    if (!productsResponse.prereqOk && productsResponse.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 48,
                  color: context.pal.outline.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('Not eligible yet',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                productsResponse.prereqMessage ??
                    'You need an active BOSA account and share capital to apply for loans.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.pal.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final products = productsResponse.products;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = products[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.pal.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.productName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: p.eligible
                                  ? context.pal.primary
                                  : context.pal.outline),
                    ),
                  ),
                  if (!p.eligible)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.pal.errorContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('INELIGIBLE',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: context.pal.error)),
                    ),
                ],
              ),
              if (p.description != null) ...[
                const SizedBox(height: 6),
                Text(p.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.pal.onSurfaceVariant)),
              ],
              const SizedBox(height: 6),
              Text(
                '${(p.minLoanAmountCents / 100).toStringAsFixed(0)} – ${(p.maxLoanAmountCents / 100).toStringAsFixed(0)} KES • ${p.interestRatePercent.toStringAsFixed(1)}% p.a.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.pal.slateMuted,
                    fontWeight: FontWeight.w600),
              ),
              if (p.guarantorsRequired)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Guarantors required (${p.minGuarantors ?? 1}–${p.maxGuarantors ?? p.minGuarantors ?? 1})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.pal.secondary,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              if (!p.eligible && p.ineligibleReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(p.ineligibleReason!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.pal.error)),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: p.eligible
                          ? () {
                              // Convert to PersonalLoanProduct for the existing flow
                              final product = PersonalLoanProduct(
                                id: p.id,
                                name: p.productName,
                                tagline: p.description ?? '',
                                maxAmount: p.memberMaxEligibleCents / 100.0,
                                minAmount: p.minLoanAmountCents / 100.0,
                                needsGuarantors: p.guarantorsRequired,
                                rateLabel:
                                    '${p.interestRatePercent.toStringAsFixed(2)}% p.a.',
                              );
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (ctx) => ApplyLoanFlowScreen(
                                    product: product,
                                    authToken: authToken,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: FilledButton.styleFrom(
                          backgroundColor: context.pal.primary),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── My Applications ───────────────────────────────────────────────────────────

class _MyApplicationsList extends StatelessWidget {
  const _MyApplicationsList({required this.applications});

  final List<LoanApplicationData> applications;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 48,
                  color: context.pal.primary.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text('No applications yet',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = applications[i];
        final c = _statusColor(a.status, context);
        final label = _statusLabel(a.status);
        final amountKes = (a.requestedAmountCents / 100).toStringAsFixed(0);
        final date = a.submittedAt.isNotEmpty
            ? a.submittedAt.substring(0, 10)
            : '—';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.pal.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: context.pal.outline.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.productName ?? a.publicLoanId ?? 'Loan',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Submitted $date',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: context.pal.slateMuted)),
                    const SizedBox(height: 6),
                    Text('KES $amountKes',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800, color: c)),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status, BuildContext context) {
    return switch (status.toUpperCase()) {
      'SUBMITTED' || 'AWAITING_GUARANTORS' => const Color(0xFF64748B),
      'APPRAISAL_PENDING' => const Color(0xFFD97706),
      'APPROVED' => const Color(0xFF047857),
      'REJECTED' => const Color(0xFFBA1A1A),
      'DISBURSED' => const Color(0xFF005127),
      _ => const Color(0xFF404940),
    };
  }

  String _statusLabel(String status) {
    return switch (status.toUpperCase()) {
      'SUBMITTED' => 'Submitted',
      'AWAITING_GUARANTORS' => 'Awaiting guarantors',
      'APPRAISAL_PENDING' => 'In review',
      'APPROVED' => 'Approved',
      'REJECTED' => 'Rejected',
      'DISBURSED' => 'Disbursed',
      _ => status,
    };
  }
}
