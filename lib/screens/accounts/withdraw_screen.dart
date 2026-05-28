import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/member_security_otp_dialog.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

const _channels = [
  'M-Pesa',
  'Airtel Money',
  'Via Agent',
  'Bank transfer',
];

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  List<MemberAccountOption> _options = const [];
  MemberAccountOption? _from;
  String _channel = _channels.first;
  final _amount = TextEditingController();
  final _phone = TextEditingController();
  final _bankAccountNo = TextEditingController();

  List<String> _banks = const [];
  bool _banksLoading = false;
  String? _selectedBank;

  bool _withdrawing = false;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _loadBanks();
  }

  @override
  void dispose() {
    _amount.dispose();
    _phone.dispose();
    _bankAccountNo.dispose();
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
          .toList()
          .where((o) => o.id == 'fosa')
          .toList();
      if (!mounted) throw 'Withdrawal verification was cancelled.';
      setState(() {
        _options = options;
        _from = options.isNotEmpty ? options.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) throw 'Withdrawal verification was cancelled.';
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load accounts.';
        _options = const [];
        _from = null;
        _loading = false;
      });
    }
  }

  double? get _amountVal {
    final v = double.tryParse(_amount.text.replaceAll(',', ''));
    return v != null && v > 0 ? v : null;
  }

  String? get _phoneDigits {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return null;
    return digits;
  }

  int? get _amountCentsVal {
    final amt = _amountVal;
    if (amt == null) return null;
    final cents = (amt * 100).round();
    return cents > 0 ? cents : null;
  }

  bool get _channelNeedsComingSoon => _channel == 'Via Agent';

  bool get _isFormOk {
    if (_from == null) return false;
    final cents = _amountCentsVal;
    if (cents == null) return false;
    if (_channelNeedsComingSoon) return false;

    if (_channel == 'M-Pesa' || _channel == 'Airtel Money') {
      return _phoneDigits != null;
    }

    if (_channel == 'Bank transfer') {
      final bankOk = _selectedBank != null && _selectedBank!.isNotEmpty;
      final acct = _bankAccountNo.text.trim();
      return bankOk && acct.length >= 5;
    }

    return false;
  }

  Future<void> _loadBanks() async {
    try {
      setState(() => _banksLoading = true);
      final api = ProsaccoMemberAuthApi();
      final banks = await api.fetchPublicBanks();
      if (!mounted) return;
      setState(() {
        _banks = banks;
        _selectedBank = banks.isNotEmpty ? banks.first : null;
        _banksLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _banksLoading = false;
        _banks = const [];
        _selectedBank = null;
      });
    }
  }

  Future<MemberTransactionResult> _withdrawWithOtp({
    required int amountCents,
    required String channel,
    String? phoneNumber,
    String? bankName,
    String? bankAccountNumber,
  }) async {
    final api = ProsaccoMemberAuthApi();
    try {
      return await api.withdrawFosa(
        token: widget.authToken,
        amountCents: amountCents,
        channel: channel,
        phoneNumber: phoneNumber,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
      );
    } on MemberSecurityOtpRequiredException catch (e) {
      final challenge = await api.requestTransactionOtp(
        token: widget.authToken,
        purpose: e.purpose,
        amountCents: e.amountCents,
      );
      if (!mounted) throw 'Withdrawal verification was cancelled.';
      final code = await promptMemberSecurityOtp(context, sentTo: challenge.sentTo);
      if (code == null || code.isEmpty) throw 'OTP verification was cancelled.';
      return await api.withdrawFosa(
        token: widget.authToken,
        amountCents: amountCents,
        channel: channel,
        phoneNumber: phoneNumber,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        securityOtpChallengeId: challenge.challengeId,
        securityOtpCode: code,
      );
    }
  }

  Future<void> _maybeConfirm() async {
    final amt = _amountVal;
    final amountCents = _amountCentsVal;
    if (amt == null || amountCents == null || _from == null) return;

    if (amt > _from!.balance) {
      showFlowErrorSnack(
        context,
        'Insufficient balance. Only KES ${formatKes(_from!.balance)} is available.',
      );
      return;
    }

    final p = context.pal;
    final backendChannel =
        _channel == 'Bank transfer' ? 'BANK_TRANSFER' : 'MPESA';
    final fee = await previewFlowFee(
      context,
      authToken: widget.authToken,
      serviceType: 'FOSA_WITHDRAWAL',
      amountCents: amountCents,
      contextData: {'channel': backendChannel},
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: p.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirm withdrawal',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: p.headlineGreen,
                      ),
                ),
                const SizedBox(height: 16),
                _row(ctx, 'From account', _from!.name),
                _row(ctx, 'Channel', _channel),
                _row(ctx, 'Amount', 'KES ${formatKes(amt)}'),
                _row(ctx, 'Transfer fee', 'KES ${formatKes(fee.feeAmount / 100)}'),
                _row(ctx, 'Total debit', 'KES ${formatKes(fee.totalAmount / 100)}'),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _isFormOk
                      ? () async {
                          setState(() => _withdrawing = true);
                          try {
                            final result = await _withdrawWithOtp(
                              amountCents: amountCents,
                              channel: backendChannel,
                              phoneNumber: backendChannel == 'MPESA'
                                  ? _phoneDigits
                                  : null,
                              bankName: backendChannel == 'BANK_TRANSFER'
                                  ? _selectedBank
                                  : null,
                              bankAccountNumber:
                                  backendChannel == 'BANK_TRANSFER'
                                      ? _bankAccountNo.text.trim()
                                      : null,
                            );

                            Navigator.pop(ctx);
                            await showTransactionReceiptSheet(
                              context,
                              authToken: widget.authToken,
                              transactionRef: result.transactionRef,
                              fallbackTitle: 'Withdrawal successful',
                              fallbackMessage:
                                  'KES ${formatKes(amt)} was processed via $_channel.',
                            );
                          } catch (e) {
                            showFlowErrorSnack(
                              context,
                              e?.toString() ?? 'Withdrawal failed.',
                            );
                          } finally {
                            if (mounted) setState(() => _withdrawing = false);
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: p.primary)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _row(
    BuildContext ctx,
    String k,
    String v, {
    bool emphasize = false,
  }) {
    final p = ctx.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: TextStyle(
              color: p.onSurfaceVariant,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
                color: emphasize ? p.primary : p.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPreview(BuildContext context, MemberAccountOption acc) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: p.headlineGreen,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  acc.mask,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: p.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Text(
            'KES ${formatKes(acc.balance)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: p.primary,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (_loading) {
      return Scaffold(
        backgroundColor: p.surface,
        appBar: AppBar(title: const Text('Withdraw')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Withdraw')),
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
            title: 'From account',
            child: DropdownButtonFormField<MemberAccountOption>(
              value: _from,
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
              onChanged: (v) => setState(() => _from = v),
            ),
          ),
          const SizedBox(height: 14),
          if (_from != null) _buildAccountPreview(context, _from!),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Withdraw via',
            child: DropdownButtonFormField<String>(
              value: _channel,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: _channels
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _channel = v ?? _channels.first),
            ),
          ),
          const SizedBox(height: 14),

          if (_channel == 'M-Pesa' || _channel == 'Airtel Money')
            FlowSectionCard(
              title: _channel == 'M-Pesa'
                  ? 'M-Pesa phone number'
                  : 'Airtel Money phone number',
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'e.g. 07XX XXX XXX',
                ),
              ),
            ),

          if (_channel == 'Bank transfer')
            FlowSectionCard(
              title: 'Bank withdrawal',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_banksLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(child: ProsaccoAnimatedLoader(size: 44)),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: _banks
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child:
                                  Text(b, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBank = v),
                    ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _bankAccountNo,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Bank account number',
                    ),
                  ),
                ],
              ),
            ),

          if (_channel == 'Via Agent')
            FlowSectionCard(
              title: 'Agent withdrawals',
              child: Text(
                'Coming soon.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.pal.onSurfaceVariant,
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
                hintText: '0.00',
                prefixText: 'KES ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isFormOk ? _maybeConfirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Review & withdraw',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
