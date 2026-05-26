import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/prosacco_palette.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  MemberAccountOption? _from;
  final _phone = TextEditingController();
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _from = kMemberAccountOptions.firstWhere((a) => a.id == 'fosa',
        orElse: () => kMemberAccountOptions.first);
  }

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  bool get _valid {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final amt = double.tryParse(_amount.text.replaceAll(',', ''));
    return digits.length >= 9 && amt != null && amt > 0 && _from != null;
  }

  Future<void> _confirmAndPay() async {
    if (!_valid) return;
    final amt = double.parse(_amount.text.replaceAll(',', ''));
    if (amt > _from!.balance) {
      showFlowErrorSnack(
        context,
        'Insufficient balance in ${_from!.name}. '
        'Available: KES ${formatKes(_from!.balance)}.',
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final p = ctx.pal;
        return AlertDialog(
          title: Text('Buy airtime?', style: TextStyle(color: p.headlineGreen)),
          content: Text(
            'KES ${formatKes(amt)} to ${_phone.text.trim()} from ${_from!.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) {
      await showFlowSuccessSheet(
        context,
        title: 'Airtime sent',
        message:
            'KES ${formatKes(amt)} airtime purchased for ${_phone.text.trim()}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Buy airtime')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          FlowSectionCard(
            title: 'Pay from',
            child: DropdownButtonFormField<MemberAccountOption>(
              value: _from,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: kMemberAccountOptions
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _from = v),
            ),
          ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Destination number',
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '07XX XXX XXX',
                prefixIcon: Icon(Icons.phone_rounded, color: p.primary),
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _valid ? _confirmAndPay : null,
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Confirm purchase',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
