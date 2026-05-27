import 'package:flutter/material.dart';
import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/member_security_otp_dialog.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

class TransferMemberScreen extends StatefulWidget {
  const TransferMemberScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<TransferMemberScreen> createState() => _TransferMemberScreenState();
}

class _TransferMemberScreenState extends State<TransferMemberScreen> {
  List<MemberAccountOption> _options = const [];
  MemberAccountOption? _source;
  final _memberAcc = TextEditingController();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _loading = true;
  String? _loadError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _memberAcc.dispose();
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final api = ProsaccoMemberAuthApi();
      final picked = await api.fetchMemberAccountOptionsForPickers(
        token: widget.authToken,
      );
      final options = picked
          .map(
            (o) => MemberAccountOption(
              id: o.id,
              name: o.name,
              mask: o.mask,
              balance: o.balanceCents / 100.0,
            ),
          )
          .where((o) => o.id == 'fosa')
          .toList();

      if (!mounted) return;
      setState(() {
        _options = options;
        _source = options.isNotEmpty ? options.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load accounts.';
        _options = const [];
        _source = null;
        _loading = false;
      });
    }
  }

  double? get _amt =>
      double.tryParse(_amount.text.replaceAll(',', ''))?.clamp(0, 1e15);

  bool get _ok =>
      _source != null &&
      _memberAcc.text.trim().length >= 4 &&
      _amt != null &&
      _amt! > 0 &&
      !_submitting;

  Future<void> _submit() async {
    if (!_ok || _source == null || _amt == null) return;
    if (_amt! > _source!.balance) {
      showFlowErrorSnack(context, 'Insufficient balance.');
      return;
    }
    final amountCents = (_amt! * 100).round();
    final recipientMemberId = _memberAcc.text.trim();

    setState(() => _submitting = true);
    try {
      final api = ProsaccoMemberAuthApi();
      try {
        await api.sendToMemberFosa(
          token: widget.authToken,
          recipientMemberId: recipientMemberId,
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
        await api.sendToMemberFosa(
          token: widget.authToken,
          recipientMemberId: recipientMemberId,
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
            'KES ${formatKes(_amt!)} sent to member $recipientMemberId from ${_source!.name}.',
      );
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
        appBar: AppBar(title: const Text('Send to member')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Send to member')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Could not load your accounts.\n$_loadError',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          FlowSectionCard(
            title: 'Source of funds',
            child: DropdownButtonFormField<MemberAccountOption>(
              value: _source,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: _options
                  .map(
                    (a) => DropdownMenuItem(value: a, child: Text(a.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _source = v),
            ),
          ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Member account number',
            child: TextField(
              controller: _memberAcc,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'e.g. MS-88291 or internal A/C',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Amount',
            child: TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: 'KES ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Reason (optional)',
            child: TextField(
              controller: _reason,
              decoration: InputDecoration(
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
            child: const Text(
              'Send to member',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
