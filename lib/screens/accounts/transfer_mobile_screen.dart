import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/member_security_otp_dialog.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

enum _MobileSendKind { choose, selfNumber, otherNumber }

class TransferMobileScreen extends StatefulWidget {
  const TransferMobileScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<TransferMobileScreen> createState() => _TransferMobileScreenState();
}

class _TransferMobileScreenState extends State<TransferMobileScreen> {
  _MobileSendKind _step = _MobileSendKind.choose;
  List<MemberAccountOption> _options = const [];
  MemberAccountOption? _source;
  final _phone = TextEditingController(text: '0712 000 000');
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

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  double? get _amt =>
      double.tryParse(_amount.text.replaceAll(',', ''))?.clamp(0, 1e15);

  bool get _formOk {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    return _source != null &&
        _amt != null &&
        _amt! > 0 &&
        !_submitting &&
        digits.length >= 9;
  }

  Future<void> _submit() async {
    if (!_formOk || _source == null || _amt == null) return;
    if (_amt! > _source!.balance) {
      showFlowErrorSnack(
        context,
        'Insufficient balance in ${_source!.name}.',
      );
      return;
    }
    final amountCents = (_amt! * 100).round();
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');

    setState(() => _submitting = true);
    try {
      final api = ProsaccoMemberAuthApi();
      try {
        await api.withdrawFosa(
          token: widget.authToken,
          amountCents: amountCents,
          channel: 'MPESA',
          phoneNumber: digits,
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
        await api.withdrawFosa(
          token: widget.authToken,
          amountCents: amountCents,
          channel: 'MPESA',
          phoneNumber: digits,
          securityOtpChallengeId: challenge.challengeId,
          securityOtpCode: code,
        );
      }

      if (!mounted) return;
      await showFlowSuccessSheet(
        context,
        title: 'Transfer successful',
        message:
            'KES ${formatKes(_amt!)} sent to ${_phone.text.trim()} from ${_source!.name}.',
      );
    } catch (e) {
      if (!mounted) return;
      showFlowErrorSnack(
        context,
        e?.toString() ?? 'Transfer failed.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (_step == _MobileSendKind.choose) {
      return Scaffold(
        backgroundColor: p.surface,
        appBar: AppBar(title: const Text('Send to mobile')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Who are you sending to?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: p.headlineGreen,
                    ),
              ),
              const SizedBox(height: 20),
              _ChoiceCard(
                title: 'Send to self',
                subtitle: 'Use your registered mobile wallet',
                icon: Icons.person_rounded,
                onTap: () {
                  setState(() {
                    _step = _MobileSendKind.selfNumber;
                    _phone.text = '0712 000 000';
                  });
                },
              ),
              const SizedBox(height: 12),
              _ChoiceCard(
                title: 'Send to someone else',
                subtitle: 'Another M-Pesa or Airtel number',
                icon: Icons.person_add_alt_1_rounded,
                onTap: () {
                  setState(() {
                    _step = _MobileSendKind.otherNumber;
                    _phone.clear();
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        title: Text(
          _step == _MobileSendKind.selfNumber
              ? 'Send to self'
              : 'Send to other',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() {
            _step = _MobileSendKind.choose;
          }),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (_loading)
            const SizedBox(
              height: 180,
              child: Center(child: ProsaccoAnimatedLoader(size: 90)),
            )
          else ...[
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_loadError!, style: Theme.of(context).textTheme.bodyMedium),
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
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(
                        '${a.name} · KES ${formatKes(a.balance)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _source = v),
            ),
          ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Mobile number',
            child: TextField(
              controller: _phone,
              readOnly: _step == _MobileSendKind.selfNumber,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '07XX XXX XXX',
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
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'e.g. Family support',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _formOk ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Send money',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: p.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 36, color: p.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: p.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: p.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
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
}
