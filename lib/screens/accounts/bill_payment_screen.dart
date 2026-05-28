import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

final _demoBillCategories = <MemberUtilityCategory>[
  MemberUtilityCategory(code: 'ELECTRICITY', label: 'Electricity', icon: 'bolt', providerHint: 'KPLC', billerCount: 1),
  MemberUtilityCategory(code: 'WATER', label: 'Water', icon: 'water_drop', providerHint: 'Water utility', billerCount: 1),
  MemberUtilityCategory(code: 'TV', label: 'TV/Cable', icon: 'tv', providerHint: 'Pay TV', billerCount: 1),
  MemberUtilityCategory(code: 'INTERNET', label: 'Internet', icon: 'public', providerHint: 'Home internet', billerCount: 1),
];

final _demoBillers = <MemberUtilityBiller>[
  MemberUtilityBiller(code: 'DEMO-KPLC', name: 'KPLC Prepaid Token', category: 'ELECTRICITY', minAmountCents: 1000),
  MemberUtilityBiller(code: 'DEMO-WATER', name: 'County Water Bill', category: 'WATER', minAmountCents: 5000),
  MemberUtilityBiller(code: 'DEMO-TV', name: 'Pay TV Subscription', category: 'TV', minAmountCents: 10000),
  MemberUtilityBiller(code: 'DEMO-INTERNET', name: 'Home Internet Bill', category: 'INTERNET', minAmountCents: 10000),
];

class BillPaymentScreen extends StatefulWidget {
  const BillPaymentScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  MemberUtilityCatalog? _catalog;
  List<MemberAccountOption> _accounts = const [];
  MemberUtilityCategory? _category;
  MemberUtilityBiller? _biller;
  MemberAccountOption? _fosa;
  String _source = 'FOSA';
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _validationMessage;

  final _reference = TextEditingController();
  final _amount = TextEditingController();
  final _mpesaPhone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reference.dispose();
    _amount.dispose();
    _mpesaPhone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ProsaccoMemberAuthApi();
      final catalog = await api.fetchUtilityPaymentCatalog(token: widget.authToken);
      final profile = await api.fetchMemberProfile(token: widget.authToken);
      final picked = await api.fetchMemberAccountOptionsForPickers(token: widget.authToken);
      final accounts = picked
          .where((o) => o.id == 'fosa')
          .map((o) => MemberAccountOption(
                id: o.id,
                name: o.name,
                mask: o.mask,
                balance: o.balanceCents / 100.0,
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _accounts = accounts;
        _fosa = accounts.isNotEmpty ? accounts.first : null;
        _mpesaPhone.text = profile.phone;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e?.toString() ?? 'Failed to load bill payment options.';
        _loading = false;
      });
    }
  }

  List<MemberUtilityBiller> get _billersForCategory {
    final category = _category;
    if (category == null) return const [];
    return _displayBillers
        .where((b) => b.category.toUpperCase() == category.code.toUpperCase())
        .toList();
  }

  bool get _demoMode {
    final catalog = _catalog;
    return catalog == null || !catalog.enabled || catalog.billers.isEmpty;
  }

  List<MemberUtilityCategory> get _displayCategories => _demoMode ? _demoBillCategories : (_catalog?.categories ?? const []);

  List<MemberUtilityBiller> get _displayBillers => _demoMode ? _demoBillers : (_catalog?.billers ?? const []);

  int? get _amountCents {
    final amt = double.tryParse(_amount.text.replaceAll(',', ''));
    return amt == null || amt <= 0 ? null : (amt * 100).round();
  }

  Future<void> _validate() async {
    if (_biller == null || _reference.text.trim().isEmpty) return;
    if (_demoMode) {
      setState(() => _validationMessage = 'Demo validation only. No provider lookup was made.');
      return;
    }
    try {
      final res = await ProsaccoMemberAuthApi().validateUtilityPayment(
        token: widget.authToken,
        paymentType: 'BILL',
        category: _category?.code,
        providerCode: _biller!.code,
        customerReference: _reference.text.trim(),
      );
      if (!mounted) return;
      setState(() => _validationMessage = res.message);
    } catch (e) {
      if (!mounted) return;
      showFlowErrorSnack(context, e?.toString() ?? 'Could not validate account.');
    }
  }

  Future<void> _submit() async {
    final amountCents = _amountCents;
    if (_biller == null || amountCents == null) return;
    if (!_demoMode && _source == 'FOSA' && _fosa != null && amountCents > (_fosa!.balance * 100).round()) {
      showFlowErrorSnack(context, 'Insufficient FOSA balance.');
      return;
    }
    final confirmed = await showFlowConfirmationSheet(
      context,
      title: 'Confirm bill payment',
      rows: [
        ('Biller', _biller!.name),
        ('Reference', _reference.text.trim()),
        ('Amount', 'KES ${formatKes(amountCents / 100)}'),
        ('Pay from', _source == 'FOSA' ? (_fosa?.name ?? 'FOSA') : 'M-Pesa'),
      ],
      confirmLabel: 'Submit Payment',
      icon: Icons.receipt_long_rounded,
    );
    if (!confirmed) return;
    if (_demoMode) {
      showFlowErrorSnack(context, 'Demo only: no bill payment request was sent.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ProsaccoMemberAuthApi().submitUtilityPayment(
        token: widget.authToken,
        paymentType: 'BILL',
        category: _category?.code,
        providerCode: _biller!.code,
        providerName: _biller!.name,
        customerReference: _reference.text.trim(),
        amountCents: amountCents,
        paymentSource: _source,
        sourcePhone: _mpesaPhone.text.trim(),
      );
      if (!mounted) return;
      await showTransactionReceiptSheet(
        context,
        authToken: widget.authToken,
        transactionRef: res.transactionRef,
        fallbackTitle: 'Payment request recorded',
        fallbackMessage: '${_biller!.name} request ref ${res.transactionRef} is ${res.status}. ${res.message}',
        icon: Icons.receipt_long_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      showFlowErrorSnack(context, e?.toString() ?? 'Payment request failed.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay Bills')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }
    final catalog = _catalog;
    final demoMode = _demoMode;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Pay Bills')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: p.error)),
            ),
          _BackendStatusCard(
              title: 'Backend status',
            message: demoMode
                ? 'Demo mode: sample billers are shown for walkthrough only. No payment request will be sent.'
                : 'Bill payments are enabled by your SACCO. Provider: ${catalog?.displayName ?? 'SACCO payment provider'} (${catalog?.providerMode ?? 'FRAMEWORK_ONLY'}).',
            mpesaEnabled: !demoMode && (catalog?.mpesaEnabled ?? false),
            ),
          const SizedBox(height: 14),
          FlowSectionCard(
              title: 'Bill category',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
              children: _displayCategories.map((c) {
                  final selected = _category?.code == c.code;
                  return ChoiceChip(
                    selected: selected,
                    label: Text('${c.label} (${c.billerCount})'),
                    onSelected: (_) => setState(() {
                      _category = c;
                      _biller = null;
                      _validationMessage = null;
                    }),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            if (_category != null)
              FlowSectionCard(
                title: 'Biller',
                child: _billersForCategory.isEmpty
                    ? Text('No ${_category!.label} billers configured yet.')
                    : Column(
                        children: _billersForCategory.map((b) {
                          return RadioListTile<MemberUtilityBiller>(
                            value: b,
                            groupValue: _biller,
                            onChanged: (v) => setState(() {
                              _biller = v;
                              _validationMessage = null;
                            }),
                            title: Text(b.name),
                            subtitle: Text(b.code),
                            secondary: _ProviderLogo(name: b.name, logoUrl: b.logoUrl),
                          );
                        }).toList(),
                      ),
              ),
            if (_biller != null) ...[
              const SizedBox(height: 14),
              FlowSectionCard(
                title: 'Account details',
                child: Column(
                  children: [
                    TextField(
                      controller: _reference,
                      decoration: const InputDecoration(
                        labelText: 'Account / meter / smartcard number',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() => _validationMessage = null),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _validate,
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Validate details'),
                    ),
                    if (_validationMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_validationMessage!, style: TextStyle(color: p.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FlowSectionCard(
                title: 'Amount and source',
                child: Column(
                  children: [
                    TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'KES ', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    _SourcePicker(
                      source: _source,
                      fosa: _fosa,
                    mpesaEnabled: !demoMode && (catalog?.mpesaEnabled ?? false),
                      mpesaPhone: _mpesaPhone,
                      onChanged: (v) => setState(() => _source = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Submitting…' : (demoMode ? 'Preview demo request' : 'Submit payment request')),
              ),
            ],
        ],
      ),
    );
  }
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({
    required this.source,
    required this.fosa,
    required this.mpesaEnabled,
    required this.mpesaPhone,
    required this.onChanged,
  });

  final String source;
  final MemberAccountOption? fosa;
  final bool mpesaEnabled;
  final TextEditingController mpesaPhone;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile<String>(
          value: 'FOSA',
          groupValue: source,
          onChanged: (_) => onChanged('FOSA'),
          title: const Text('FOSA account'),
          subtitle: Text(fosa == null ? 'No active FOSA' : 'Bal: KES ${formatKes(fosa!.balance)}'),
        ),
        RadioListTile<String>(
          value: 'MPESA',
          groupValue: source,
          onChanged: mpesaEnabled ? (_) => onChanged('MPESA') : null,
          title: const Text('M-Pesa STK Push'),
          subtitle: Text(mpesaEnabled ? 'Use registered phone' : 'Not enabled by SACCO'),
        ),
        if (source == 'MPESA')
          TextField(
            controller: mpesaPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'M-Pesa phone', border: OutlineInputBorder()),
          ),
      ],
    );
  }
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo({required this.name, this.logoUrl});
  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(url));
    }
    return CircleAvatar(child: Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase()));
  }
}

class _BackendStatusCard extends StatelessWidget {
  const _BackendStatusCard({
    required this.title,
    required this.message,
    required this.mpesaEnabled,
  });

  final String title;
  final String message;
  final bool mpesaEnabled;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return FlowSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 8),
          Text(
            mpesaEnabled ? 'M-Pesa payment source is enabled.' : 'M-Pesa payment source is disabled by your SACCO.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mpesaEnabled ? p.success : p.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
