import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';

/// Guarantor request detail — wired to MFA challenge + consent/decline APIs.
class GuarantorRequestDetailScreen extends StatefulWidget {
  const GuarantorRequestDetailScreen({
    super.key,
    required this.item,
    required this.authToken,
  });

  final GuarantorInboxItem item;
  final String authToken;

  @override
  State<GuarantorRequestDetailScreen> createState() =>
      _GuarantorRequestDetailScreenState();
}

class _GuarantorRequestDetailScreenState
    extends State<GuarantorRequestDetailScreen> {
  bool _busy = false;

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

  Future<void> _handleConsent() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = ProsaccoMemberAuthApi();
      // Step 1: request MFA challenge
      final challenge = await api.requestGuarantorMfaChallenge(
        token: widget.authToken,
        requestId: widget.item.id,
      );

      if (!mounted) return;

      // Step 2: prompt for OTP
      final code = await _promptOtp(context, method: challenge.method);
      if (code == null || code.isEmpty) {
        setState(() => _busy = false);
        return;
      }

      // Step 3: submit consent
      await api.submitGuarantorConsent(
        token: widget.authToken,
        requestId: widget.item.id,
        code: code,
        challengeId: challenge.challengeId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consent submitted successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleDecline() async {
    if (_busy) return;
    final reason = await _promptDeclineReason(context);
    if (reason == null || reason.trim().length < 5) return;

    setState(() => _busy = true);
    try {
      final api = ProsaccoMemberAuthApi();
      await api.declineGuarantorRequest(
        token: widget.authToken,
        requestId: widget.item.id,
        reason: reason.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptOtp(BuildContext context, {required String method}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter verification code',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              method == 'APP'
                  ? 'Enter the code from your authenticator app.'
                  : 'Enter the OTP sent to your registered phone.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: ctx.pal.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptDeclineReason(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline request',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason (required).',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: ctx.pal.onSurfaceVariant)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g. I cannot commit to this guarantee at this time.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().length < 5) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            style: FilledButton.styleFrom(backgroundColor: ctx.pal.error),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
        title: const Text('Request Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
        children: [
          if (item.isUrgent)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xFFFBBF24), width: 4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded, color: Color(0xFFD97706)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expiring soon',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E))),
                        Text('This request requires your action within 24 hours.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFB45309))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (item.isUrgent) const SizedBox(height: 16),

          // Borrower header
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: context.pal.surfaceContainerHigh,
                child: Text(
                  item.borrowerMemberNumber.length >= 2
                      ? item.borrowerMemberNumber.substring(0, 2).toUpperCase()
                      : item.borrowerMemberNumber.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: context.pal.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.borrowerMemberNumber,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800)),
                    Text('BORROWER MEMBER',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: context.pal.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _detailCell(context, 'Loan product', item.productName),
          const SizedBox(height: 10),
          _detailCell(context, 'Loan amount', 'KES ${_money(item.requestedAmountCents)}'),
          const SizedBox(height: 10),
          _detailCell(context, 'Your coverage', 'KES ${_money(item.coverageCents)}'),
          const SizedBox(height: 10),
          _detailCell(context, 'BOSA lock required', 'KES ${_money(item.requiredLockCents)}',
              fullWidth: true),
          const SizedBox(height: 16),

          // Expiry
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.pal.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 20, color: context.pal.outline),
                const SizedBox(width: 10),
                Text(item.expiryLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.pal.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security_rounded, size: 20,
                  color: context.pal.outline.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.pal.onSurfaceVariant, height: 1.45),
                    children: const [
                      TextSpan(text: 'By tapping '),
                      TextSpan(text: 'Consent',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: ', you will complete MFA verification. Your consent is binding under SACCO rules.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          decoration: BoxDecoration(
            color: context.pal.surface.withValues(alpha: 0.94),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _handleConsent,
                icon: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_rounded, size: 20),
                label: const Text('Consent to Guarantee',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                  backgroundColor: context.pal.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : _handleDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.pal.onSurface,
                    backgroundColor: context.pal.surfaceContainerHighest,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline Request',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailCell(BuildContext context, String label, String value,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800, letterSpacing: 1,
                  color: context.pal.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
