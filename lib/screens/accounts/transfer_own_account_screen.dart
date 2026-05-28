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
  List<MemberAccountOption> _accounts = const [];
  MemberAccountOption? _from;
  MemberAccountOption? _to;
  bool _loading = true;
  String? _loadError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final api = ProsaccoMemberAuthApi();
      final picked = await api.fetchMemberAccountOptionsForPickers(
        token: widget.authToken,
      );
      final accounts = picked
          .where((o) => o.id == 'fosa' || o.id == 'bosa')
          .map(
            (o) => MemberAccountOption(
              id: o.id,
              name: o.name,
              mask: o.mask,
              balance: o.balanceCents / 100.0,
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _from = accounts.isNotEmpty ? accounts.first : null;
        _to = accounts.length > 1 ? accounts[1] : null;
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
      _from != null &&
      _to != null &&
      _from!.id != _to!.id &&
      _amt != null &&
      _amt! > 0 &&
      !_submitting;

  List<MemberAccountOption> get _destinationOptions =>
      _accounts.where((a) => a.id != _from?.id).toList();

  void _setFrom(MemberAccountOption? account) {
    setState(() {
      _from = account;
      final destinations = _destinationOptions;
      if (_to == null || _to!.id == account?.id || !destinations.any((a) => a.id == _to!.id)) {
        _to = destinations.isNotEmpty ? destinations.first : null;
      }
    });
  }

  Future<void> _submit() async {
    if (!_ok || _amt == null) return;
    final from = _from!;
    final to = _to!;
    if (_amt! > from.balance) {
      showFlowErrorSnack(context, 'Insufficient ${from.name} balance.');
      return;
    }
    final supported = (from.id == 'fosa' && to.id == 'bosa') ||
        (from.id == 'bosa' && to.id == 'fosa');
    if (!supported) {
      showFlowErrorSnack(context, 'This account transfer route is not available yet.');
      return;
    }
    final amountCents = (_amt! * 100).round();
    final fee = from.id == 'fosa' && to.id == 'bosa'
        ? await previewFlowFee(
            context,
            authToken: widget.authToken,
            serviceType: 'FOSA_WITHDRAWAL',
            amountCents: amountCents,
            contextData: {'channel': 'TRANSFER'},
          )
        : MemberFeePreview(feeAmount: 0, totalAmount: amountCents);
    final confirmed = await showFlowConfirmationSheet(
      context,
      title: 'Confirm own account transfer',
      rows: [
        ('From', '${from.name} · ${from.mask}'),
        ('To', '${to.name} · ${to.mask}'),
        ('Amount', 'KES ${formatKes(_amt!)}'),
        ('Transfer fee', 'KES ${formatKes(fee.feeAmount / 100)}'),
        ('Total debit', 'KES ${formatKes(fee.totalAmount / 100)}'),
      ],
      confirmLabel: 'Transfer Funds',
    );
    if (!confirmed) return;

    setState(() => _submitting = true);
    try {
      final api = ProsaccoMemberAuthApi();
      late MemberTransactionResult result;
      try {
        if (from.id == 'fosa' && to.id == 'bosa') {
          result = await api.transferFosaToBosa(
            token: widget.authToken,
            amountCents: amountCents,
          );
        } else {
          result = await api.transferBosaToFosa(
            token: widget.authToken,
            amountCents: amountCents,
          );
        }
      } on MemberSecurityOtpRequiredException catch (e) {
        final challenge = await api.requestTransactionOtp(
          token: widget.authToken,
          purpose: e.purpose,
          amountCents: e.amountCents,
        );
        if (!mounted) return;
        final code = await promptMemberSecurityOtp(context, sentTo: challenge.sentTo);
        if (code == null || code.isEmpty) throw 'OTP verification was cancelled.';
        if (from.id == 'fosa' && to.id == 'bosa') {
          result = await api.transferFosaToBosa(
            token: widget.authToken,
            amountCents: amountCents,
            securityOtpChallengeId: challenge.challengeId,
            securityOtpCode: code,
          );
        } else {
          result = await api.transferBosaToFosa(
            token: widget.authToken,
            amountCents: amountCents,
            securityOtpChallengeId: challenge.challengeId,
            securityOtpCode: code,
          );
        }
      }
      if (!mounted) return;
      await showTransactionReceiptSheet(
        context,
        authToken: widget.authToken,
        transactionRef: result.transactionRef,
        fallbackTitle: 'Transfer successful',
        fallbackMessage:
            'KES ${formatKes(_amt!)} moved from ${from.name} to ${to.name}.',
      );
      // Refresh balances after success
      _amount.clear();
      _loadAccounts();
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
        appBar: AppBar(title: const Text('Own account transfer')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Own account transfer')),
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
          if (_accounts.length < 2)
            FlowSectionCard(
              title: 'Account transfer unavailable',
              child: Text(
                'You need at least two eligible accounts to move funds between your own accounts.',
                style: TextStyle(color: p.onSurfaceVariant, height: 1.4),
              ),
            ),
          if (_accounts.length >= 2) ...[
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
                    label: _from?.name ?? 'From account',
                    balance: _from?.balance,
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
                    label: _to?.name ?? 'To account',
                    balance: _to?.balance,
                    palette: p,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FlowSectionCard(
            title: 'From account',
            child: DropdownButtonFormField<MemberAccountOption>(
              value: _from,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: _accounts
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text('${a.name} · KES ${formatKes(a.balance)}'),
                    ),
                  )
                  .toList(),
              onChanged: _setFrom,
            ),
          ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'To account',
            child: DropdownButtonFormField<MemberAccountOption>(
              value: _to,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: _destinationOptions
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text('${a.name} · ${a.mask}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _to = v),
            ),
          ),
          const SizedBox(height: 14),
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
                    'Move funds',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
          ],
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
