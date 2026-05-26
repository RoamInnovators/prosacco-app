import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import 'loan_application_review_screen.dart';
import 'loan_data.dart';

class ApplyLoanFlowScreen extends StatefulWidget {
  const ApplyLoanFlowScreen({
    super.key,
    required this.product,
    required this.authToken,
  });

  final PersonalLoanProduct product;
  final String authToken;

  @override
  State<ApplyLoanFlowScreen> createState() => _ApplyLoanFlowScreenState();
}

class _ApplyLoanFlowScreenState extends State<ApplyLoanFlowScreen> {
  final _amountCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  late int _termMonths;
  final List<GuarantorSearchResult> _guarantors = [];
  int _step = 0;

  @override
  void initState() {
    super.initState();
    final mid = ((widget.product.minRepaymentMonths +
                widget.product.maxRepaymentMonths) /
            2)
        .round();
    _termMonths = mid;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  double get _amountParsed =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

  double get _emi {
    final a = _amountParsed;
    if (a <= 0 || _termMonths <= 0) return 0;
    return (a / _termMonths) * 1.08;
  }

  int get _totalSteps => widget.product.needsGuarantors ? 2 : 1;

  List<int> _termOptions() {
    final min = widget.product.minRepaymentMonths;
    final max = widget.product.maxRepaymentMonths;
    final candidates = [6, 12, 18, 24, 36, 48, 60, 72, 84];
    final opts = candidates.where((m) => m >= min && m <= max).toList();
    if (opts.isEmpty) opts.add(min);
    if (!opts.contains(max) && max != min) opts.add(max);
    opts.sort();
    return opts;
  }

  void _validateAndContinue() {
    if (_step == 0) {
      final a = _amountParsed;
      if (a < widget.product.minAmount || a > widget.product.maxAmount) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Amount must be between '
            '${widget.product.minAmount.toStringAsFixed(0)} and '
            '${widget.product.maxAmount.toStringAsFixed(0)} KES.',
          ),
        ));
        return;
      }
      if (!widget.product.needsGuarantors) {
        _openReview();
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1 && widget.product.needsGuarantors) {
      if (_guarantors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one guarantor for this product.'),
        ));
        return;
      }
      _openReview();
    }
  }

  void _openReview() {
    final amt = _amountParsed;
    if (amt < widget.product.minAmount || amt > widget.product.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Enter an amount between '
          '${widget.product.minAmount.toStringAsFixed(0)} and '
          '${widget.product.maxAmount.toStringAsFixed(0)} KES.',
        ),
      ));
      return;
    }
    if (widget.product.needsGuarantors && _guarantors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one guarantor for this product.'),
      ));
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (ctx) => LoanApplicationReviewScreen(
          product: widget.product,
          amount: amt,
          termMonths: _termMonths,
          monthlyInstallment: _emi,
          guarantorNames: widget.product.needsGuarantors
              ? _guarantors.map((g) => g.fullName).toList()
              : [],
          guarantorIds: widget.product.needsGuarantors
              ? _guarantors.map((g) => g.id).toList()
              : [],
          authToken: widget.authToken,
          onSubmitSuccess: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black.withValues(alpha: 0.5),
              builder: (c) => const LoanSubmitSuccessDialog(),
            );
          },
        ),
      ),
    );
  }

  Future<void> _searchGuarantor(BuildContext context) async {
    final result = await showDialog<GuarantorSearchResult>(
      context: context,
      builder: (ctx) => _GuarantorSearchDialog(authToken: widget.authToken),
    );
    if (result == null) return;
    if (_guarantors.any((g) => g.id == result.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This member is already added.')),
        );
      }
      return;
    }
    setState(() => _guarantors.add(result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pal.surface,
      appBar: AppBar(
        backgroundColor: context.pal.surface,
        foregroundColor: context.pal.primary,
        elevation: 0,
        centerTitle: true,
        title: Text('Apply — ${widget.product.name}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _buildStepHeader(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _step == 0
                  ? _buildAmountCard(context)
                  : _buildGuarantorsCard(context),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    final progress = (_step + 1) / _totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('STEP ${_step + 1} OF $_totalSteps',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: context.pal.primary,
                    )),
            Text('${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.pal.outline,
                    )),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: context.pal.surfaceContainerHighest,
            color: context.pal.primary,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.product.needsGuarantors)
          Row(
            children: [
              _stepDot(context, 0, 'Amount', Icons.payments_outlined),
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: _step >= 1
                      ? context.pal.primary
                      : context.pal.surfaceContainerHighest,
                ),
              ),
              _stepDot(context, 1, 'Guarantors', Icons.group_outlined),
            ],
          )
        else
          Center(
            child: _stepDot(context, 0, 'Amount & term', Icons.payments_outlined),
          ),
      ],
    );
  }

  Widget _stepDot(BuildContext context, int index, String label, IconData icon) {
    final active = _step == index;
    final done = _step > index;
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (done || active) ? context.pal.primary : context.pal.surfaceContainerHigh,
            boxShadow: (active || done)
                ? [BoxShadow(
                    color: context.pal.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )]
                : null,
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            color: (done || active) ? Colors.white : context.pal.outline,
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: (active || done)
                      ? context.pal.headlineGreen
                      : context.pal.slateMuted,
                )),
      ],
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.pal.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOAN AMOUNT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: context.pal.onSurfaceVariant,
                  )),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            focusNode: _amountFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.pal.onSurface,
                ),
            decoration: InputDecoration(
              hintText: 'e.g. ${widget.product.minAmount.toStringAsFixed(0)}',
              hintStyle: TextStyle(color: context.pal.outline.withValues(alpha: 0.45)),
              filled: true,
              fillColor: context.pal.surfaceContainerLow,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.pal.primary, width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixText: 'KES ',
              prefixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.pal.outline,
                  ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            'Eligible range: ${widget.product.minAmount.toStringAsFixed(0)} – '
            '${widget.product.maxAmount.toStringAsFixed(0)} KES',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: context.pal.slateMuted),
          ),
          const SizedBox(height: 22),
          Text('REPAYMENT DURATION',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: context.pal.onSurfaceVariant,
                  )),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _termOptions().map((m) {
              final sel = _termMonths == m;
              return Material(
                color: sel
                    ? context.pal.secondaryContainer
                    : context.pal.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => setState(() => _termMonths = m),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? context.pal.primary
                            : context.pal.outline.withValues(alpha: 0.2),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sel) ...[
                          Icon(Icons.check_rounded,
                              size: 18, color: context.pal.primary),
                          const SizedBox(width: 6),
                        ],
                        Text('$m mo',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: sel
                                      ? context.pal.headlineGreen
                                      : context.pal.onSurface,
                                )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.pal.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: context.pal.primary.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: context.pal.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estimated installment ~ KES ${_emi.toStringAsFixed(2)} / month '
                    '(illustrative). Final schedule confirmed on approval.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.pal.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantorsCard(BuildContext context) {
    final minG = widget.product.minGuarantors;
    final maxG = widget.product.maxGuarantors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.pal.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GUARANTORS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: context.pal.onSurfaceVariant,
                  )),
          const SizedBox(height: 6),
          Text(
            'Add $minG–$maxG member(s) who have agreed to stand as guarantors.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.pal.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          ..._guarantors.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.pal.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: context.pal.outline.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: context.pal.secondaryContainer,
                        child: Text(
                          g.fullName
                              .split(' ')
                              .where((e) => e.isNotEmpty)
                              .take(2)
                              .map((e) => e[0])
                              .join(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: context.pal.onSecondaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(g.memberNumber,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.pal.slateMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _guarantors.remove(g)),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: context.pal.outline,
                      ),
                    ],
                  ),
                ),
              )),
          if (_guarantors.length < maxG)
            OutlinedButton.icon(
              onPressed: () => _searchGuarantor(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Search member'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.pal.primary,
                side: BorderSide(color: context.pal.primary),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final toReview = (_step == 0 && !widget.product.needsGuarantors) ||
        (_step == 1 && widget.product.needsGuarantors);
    return Material(
      elevation: 8,
      color: context.pal.surfaceContainerLowest,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  if (_step == 0) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _step = 0);
                  }
                },
                child: Text(
                  _step == 0 ? 'Cancel' : 'Back',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.pal.secondary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _validateAndContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.pal.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    shadowColor:
                        context.pal.primary.withValues(alpha: 0.35),
                  ),
                  child: Text(
                    toReview ? 'Continue to review' : 'Continue',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Guarantor search dialog ───────────────────────────────────────────────────

class _GuarantorSearchDialog extends StatefulWidget {
  const _GuarantorSearchDialog({required this.authToken});

  final String authToken;

  @override
  State<_GuarantorSearchDialog> createState() => _GuarantorSearchDialogState();
}

class _GuarantorSearchDialogState extends State<_GuarantorSearchDialog> {
  final _ctrl = TextEditingController();
  bool _searching = false;
  List<GuarantorSearchResult> _results = [];
  String? _error;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() { _results = []; _error = null; });
      return;
    }
    setState(() { _searching = true; _error = null; });
    try {
      final api = ProsaccoMemberAuthApi();
      final list =
          await api.searchGuarantors(token: widget.authToken, query: q.trim());
      if (!mounted) return;
      setState(() { _results = list; _searching = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _searching = false; });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search member',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Name or member number…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2)))
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              onChanged: _search,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: p.error, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          _ctrl.text.length < 2
                              ? 'Type at least 2 characters to search.'
                              : 'No members found.',
                          style: TextStyle(color: p.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: p.outline.withValues(alpha: 0.1)),
                      itemBuilder: (ctx, i) {
                        final r = _results[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.secondaryContainer,
                            child: Text(
                              r.fullName
                                  .split(' ')
                                  .where((e) => e.isNotEmpty)
                                  .take(2)
                                  .map((e) => e[0])
                                  .join(),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: p.onSecondaryContainer,
                                  fontSize: 12),
                            ),
                          ),
                          title: Text(r.fullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(r.memberNumber,
                              style: TextStyle(
                                  color: p.slateMuted, fontSize: 12)),
                          onTap: () => Navigator.pop(ctx, r),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success dialog ────────────────────────────────────────────────────────────

class LoanSubmitSuccessDialog extends StatefulWidget {
  const LoanSubmitSuccessDialog({super.key});

  @override
  State<LoanSubmitSuccessDialog> createState() =>
      _LoanSubmitSuccessDialogState();
}

class _LoanSubmitSuccessDialogState extends State<LoanSubmitSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.pal.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: context.pal.outline.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                  parent: _controller, curve: Curves.elasticOut),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.pal.tertiary,
                      context.pal.primary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.pal.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 56),
              ),
            ),
            const SizedBox(height: 22),
            Text('Application submitted',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.pal.onSurface,
                      letterSpacing: -0.3,
                    )),
            const SizedBox(height: 10),
            Text(
              "We'll notify you as your application moves through review.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.pal.onSurfaceVariant,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: context.pal.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text('Done',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
