import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import 'loan_data.dart';

/// `prosacco design/loan_application_review_redesign/code.html`
class LoanApplicationReviewScreen extends StatefulWidget {
  const LoanApplicationReviewScreen({
    super.key,
    required this.product,
    required this.amount,
    required this.termMonths,
    required this.monthlyInstallment,
    required this.guarantorNames,
    required this.guarantorIds,
    required this.onSubmitSuccess,
    required this.authToken,
  });

  final PersonalLoanProduct product;
  final double amount;
  final int termMonths;
  final double monthlyInstallment;
  final List<String> guarantorNames;
  final List<String> guarantorIds;
  final VoidCallback onSubmitSuccess;
  final String authToken;

  @override
  State<LoanApplicationReviewScreen> createState() =>
      _LoanApplicationReviewScreenState();
}

class _LoanApplicationReviewScreenState
    extends State<LoanApplicationReviewScreen> {
  bool _consented = false;
  bool _submitting = false;
  String _disbursementMethod = 'FOSA';
  final _mpesaPhone = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccount = TextEditingController();

  @override
  void dispose() {
    _mpesaPhone.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    super.dispose();
  }

  Future<void> _doSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final api = ProsaccoMemberAuthApi();
      final amountCents = (widget.amount * 100).round();
      if (_disbursementMethod == 'MPESA' && _mpesaPhone.text.trim().isEmpty) {
        throw 'Enter the M-Pesa phone number.';
      }
      if (_disbursementMethod == 'BANK_TRANSFER' &&
          (_bankName.text.trim().isEmpty || _bankAccount.text.trim().isEmpty)) {
        throw 'Enter the bank name and account number.';
      }

      // Build guarantor list — split coverage equally
      List<LoanGuarantorInput>? guarantors;
      if (widget.product.needsGuarantors && widget.guarantorIds.isNotEmpty) {
        final perGuarantor = (amountCents / widget.guarantorIds.length).round();
        guarantors = widget.guarantorIds.map((id) => LoanGuarantorInput(
          guarantorMemberId: id,
          coverageCents: perGuarantor,
          requiredLockCents: perGuarantor,
        )).toList();
        // Adjust last guarantor to cover rounding difference
        final total = guarantors.fold(0, (s, g) => s + g.coverageCents);
        if (total != amountCents) {
          final diff = amountCents - total;
          guarantors = [
            ...guarantors.sublist(0, guarantors.length - 1),
            LoanGuarantorInput(
              guarantorMemberId: guarantors.last.guarantorMemberId,
              coverageCents: guarantors.last.coverageCents + diff,
              requiredLockCents: guarantors.last.requiredLockCents + diff,
            ),
          ];
        }
      }

      await api.submitLoanApplication(
        token: widget.authToken,
        loanProductId: widget.product.id,
        requestedAmountCents: amountCents,
        repaymentMonths: widget.termMonths,
        disbursementMethod: _disbursementMethod,
        disbursementDestination: _disbursementMethod == 'MPESA'
            ? {'phone': _mpesaPhone.text.trim()}
            : _disbursementMethod == 'BANK_TRANSFER'
                ? {'bankName': _bankName.text.trim(), 'accountNumber': _bankAccount.text.trim()}
                : null,
        guarantors: guarantors,
      );
      if (!mounted) return;
      widget.onSubmitSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _money(double v) {
    final s = v.toStringAsFixed(2).split('.');
    final w = s[0];
    final buf = StringBuffer();
    for (var i = 0; i < w.length; i++) {
      if (i > 0 && (w.length - i) % 3 == 0) buf.write(',');
      buf.write(w[i]);
    }
    return '$buf.${s[1]}';
  }

  void _confirmSubmit() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.pal.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: context.pal.outline.withValues(alpha: 0.15),
            ),
          ),
          title: Text(
            'Submit application?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.pal.headlineGreen,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to send your ${widget.product.name} application for:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.pal.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.pal.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'KES ${_money(widget.amount)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.pal.primary,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can cancel to go back and edit. Submit only when everything is correct.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.pal.slateMuted,
                      height: 1.35,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.pal.secondary,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _doSubmit();
              },
              style: FilledButton.styleFrom(
                backgroundColor: context.pal.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Yes, submit',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = widget.termMonths ~/ 12;
    final rem = widget.termMonths % 12;
    final termLabel = rem == 0
        ? '$years ${years == 1 ? 'Year' : 'Years'} (${widget.termMonths} months)'
        : '${widget.termMonths} Months';

    return Scaffold(
      backgroundColor: context.pal.surface,
      appBar: AppBar(
        backgroundColor: context.pal.surface.withValues(alpha: 0.9),
        foregroundColor: context.pal.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Verification'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'ProSacco',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: context.pal.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Text(
            'APPLICATION SUMMARY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: context.pal.outline,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Review your loan details before submission',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.pal.onSurface,
                ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.pal.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -24,
                  right: -24,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL LOAN AMOUNT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'KES',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _money(widget.amount),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MONTHLY INSTALLMENT',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'KES ${_money(widget.monthlyInstallment)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOAN TYPE',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      widget.product.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
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
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.pal.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.pal.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.pal.secondaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_repeat_rounded,
                    color: context.pal.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REPAYMENT TERM',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: context.pal.outline,
                            ),
                      ),
                      Text(
                        termLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'INTEREST',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: context.pal.outline,
                          ),
                    ),
                    Text(
                      widget.product.rateLabel.split(' ').take(2).join(' '),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Disbursement method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _disbursementMethod,
            decoration: const InputDecoration(
              labelText: 'Receive funds via',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'FOSA', child: Text('Credit to FOSA')),
              DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
              DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank transfer')),
              DropdownMenuItem(value: 'CASH', child: Text('Cash / branch clearing')),
            ],
            onChanged: (value) => setState(() => _disbursementMethod = value ?? 'FOSA'),
          ),
          if (_disbursementMethod == 'MPESA') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _mpesaPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa phone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_disbursementMethod == 'BANK_TRANSFER') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _bankName,
              decoration: const InputDecoration(
                labelText: 'Bank name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bankAccount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bank account number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (widget.guarantorNames.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Guarantors (${widget.guarantorNames.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.pal.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'VERIFIED',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.pal.primary,
                          letterSpacing: 0.8,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.guarantorNames.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _guarantorTile(context, n),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.pal.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _consented,
                    onChanged: (v) =>
                        setState(() => _consented = v ?? false),
                    activeColor: context.pal.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.pal.onSurfaceVariant,
                            height: 1.4,
                          ),
                      children: const [
                        TextSpan(
                          text:
                              'I have read and agree to the Terms and Conditions and the Loan Disclosure Agreement. I authorize ProSacco to deduct the monthly installment from my registered account.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _consented && !_submitting ? _doSubmit : null,
            icon: _submitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.lock_rounded, size: 22),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Submit Application',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context.pal.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  context.pal.outline.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.pal.tertiary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: context.pal.tertiary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: context.pal.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SECURE & ENCRYPTED',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.pal.tertiary,
                          letterSpacing: 0.6,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your data is protected with industry-standard encryption.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.pal.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _guarantorTile(BuildContext context, String name) {
    final initials = name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.pal.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.pal.primaryFixed,
            foregroundColor: context.pal.onPrimaryFixed,
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Membership on file',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.pal.outline,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: context.pal.primary),
        ],
      ),
    );
  }
}
