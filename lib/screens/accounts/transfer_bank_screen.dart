import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

class TransferBankScreen extends StatefulWidget {
  const TransferBankScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<TransferBankScreen> createState() => _TransferBankScreenState();
}

class _TransferBankScreenState extends State<TransferBankScreen> {
  MemberAccountOption? _source;
  String? _bank;
  final _accountNo = TextEditingController();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _favorite = false;
  List<MemberAccountOption> _options = const [];
  bool _loading = true;
  String? _loadError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _bank = kKenyanBanks.first;
    _loadOptions();
  }

  @override
  void dispose() {
    _accountNo.dispose();
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
      _bank != null &&
      _accountNo.text.trim().length >= 5 &&
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

    setState(() => _submitting = true);
    try {
      final api = ProsaccoMemberAuthApi();
      await api.withdrawFosa(
        token: widget.authToken,
        amountCents: amountCents,
        channel: 'BANK_TRANSFER',
        bankName: _bank,
        bankAccountNumber: _accountNo.text.trim(),
      );

      if (!mounted) return;
      await showFlowSuccessSheet(
        context,
        title: 'PesaLink transfer sent',
        message:
            'KES ${formatKes(_amt!)} to $_bank · A/C ${_accountNo.text.trim()}. '
            '${_favorite ? "Recipient saved as favorite." : ""}',
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
        appBar: AppBar(
          title: const Text('Send to bank'),
        ),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        title: const Text('Send to bank'),
      ),
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, color: p.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PesaLink — funds move securely to the selected bank account.',
                    style: TextStyle(
                      color: p.onSurfaceVariant,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FlowSectionCard(
            title: 'Kenyan bank',
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _bank,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: kKenyanBanks
                  .map(
                    (b) => DropdownMenuItem(
                      value: b,
                      child: Text(b, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _bank = v),
            ),
          ),
          const SizedBox(height: 14),
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
                        a.name,
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
            title: 'Account number',
            child: TextField(
              controller: _accountNo,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Beneficiary account number',
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
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _favorite,
            onChanged: (v) => setState(() => _favorite = v ?? false),
            title: Text(
              'Mark recipient as favorite',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: p.onSurface,
              ),
            ),
            activeColor: p.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
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
              'Send to bank',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
