import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/member_security_otp_dialog.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

class TransferOwnAccountScreen extends StatefulWidget {
  const TransferOwnAccountScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<TransferOwnAccountScreen> createState() =>
      _TransferOwnAccountScreenState();
}

class _TransferOwnAccountScreenState extends State<TransferOwnAccountScreen> {
  final _amount = TextEditingController();
  double? _fosaBalance;
  double? _bosaBalance;
  bool _loading = true;
  String? _loadError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadBalances() async {
    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final api = ProsaccoMemberAuthApi();
      final overview = await api.fetchMemberAccountsOverview(
        token: widget.authToken,
      );
      if (!mounted) return;
      setState(() {
        _fosaBalance =
            (overview.fosa.account?.balanceCents ?? 0) / 100.0;
        _bosaBalance =
            (overview.bosa.account?.balanceCents ?? 0) / 100.0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load balances.';
        _loading = false;
      });
    }
  }

  double? get _amt =>
      double.tryParse(_amount.text.replaceAll(',', ''))?.clamp(0, 1e15);

  bool get _ok =>
      _fosaBalance != null &&
      _amt != null &&
      _amt! > 0 &&
      !_submitting;

  Future<void> _submit() async {
    if (!_ok || _amt == null) return;
    if (_fosaBalance != null && _amt! > _fosaBalance!) {
      showFlowErrorSnack(context, 'Insufficient FOSA balance.');
      return;
    }
    final amountCents = (_amt! * 100).round();

    setState(() => _submitting = true);
    try {
      final api = ProsaccoMemberAuthApi();
      try {
        await api.transferFosaToBosa(
          token: widget.authToken,
          amountCents: amountCents,
        );
      } on MemberSecurityOtpRequiredException catch (e) {
        final challenge = await api.requestTransactionOtp(
          token: widget.authToken,
          purpose: e.purpose,
          amountCents: e.amountCents,
        );
        if (!mounted) return;
        final code = await promptMemberSecurityOtp(context, sentTo: challenge.sentTo);
        if (code == null || code.isEmpty) throw 'OTP verification was cancelled.';
        await api.transferFosaToBosa(
          token: widget.authToken,
          amountCents: amountCents,
          securityOtpChallengeId: challenge.challengeId,
          securityOtpCode: code,
        );
      }
      if (!mounted) return;
      await showFlowSuccessSheet(
        context,
        title: 'Transfer successful',
        message:
            'KES ${formatKes(_amt!)} moved from your FOSA to your BOSA savings.',
      );
      // Refresh balances after success
      _amount.clear();
      _loadBalances();
    } catch (e) {
      if (!mounted) return;
      showFlowErrorSnack(context, e?.toString() ?? 'Transfer failed.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (_loading) {
      return Scaffold(
        backgroundColor: p.surface,
        appBar: AppBar(title: const Text('Move to savings')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Move to savings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _loadError!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          // Balance summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _BalancePill(
                    label: 'FOSA',
                    balance: _fosaBalance,
                    palette: p,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: p.primary,
                  size: 22,
                ),
                Expanded(
                  child: _BalancePill(
                    label: 'BOSA',
                    balance: _bosaBalance,
                    palette: p,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FlowSectionCard(
            title: 'Amount to move',
            child: TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: 'KES ',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _ok ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Move to BOSA savings',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({
    required this.label,
    required this.balance,
    required this.palette,
  });

  final String label;
  final double? balance;
  final ProsaccoPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          balance != null ? 'KES ${formatKes(balance!)}' : '—',
          style: TextStyle(
            color: palette.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
