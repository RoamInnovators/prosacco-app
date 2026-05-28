import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

final _demoNetworks = <MemberUtilityNetwork>[
  MemberUtilityNetwork(
    code: 'DEMO-SAFARICOM',
    name: 'Safaricom Demo',
    bundles: [
      MemberDataBundle(code: 'DEMO-SAF-1GB', name: '1GB Daily Demo', amountCents: 9900, validity: '24 hours'),
      MemberDataBundle(code: 'DEMO-SAF-5GB', name: '5GB Weekly Demo', amountCents: 50000, validity: '7 days'),
    ],
  ),
  MemberUtilityNetwork(
    code: 'DEMO-AIRTEL',
    name: 'Airtel Demo',
    bundles: [
      MemberDataBundle(code: 'DEMO-AIR-500MB', name: '500MB Daily Demo', amountCents: 5000, validity: '24 hours'),
      MemberDataBundle(code: 'DEMO-AIR-2GB', name: '2GB Weekly Demo', amountCents: 25000, validity: '7 days'),
    ],
  ),
  MemberUtilityNetwork(code: 'DEMO-TELKOM', name: 'Telkom Demo'),
];

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  MemberAccountOption? _from;
  MemberUtilityCatalog? _catalog;
  MemberUtilityNetwork? _network;
  MemberDataBundle? _bundle;
  List<MemberTransferBeneficiaryData> _frequent = const [];
  String _purchaseType = 'AIRTIME';
  String _source = 'FOSA';
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _mpesaPhone = TextEditingController();
  List<MemberAccountOption> _options = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final api = ProsaccoMemberAuthApi();
      final catalog = await api.fetchUtilityPaymentCatalog(token: widget.authToken);
      final profile = await api.fetchMemberProfile(token: widget.authToken);
      final picked = await api.fetchMemberAccountOptionsForPickers(
        token: widget.authToken,
      );
      final frequent = await api.fetchTransferBeneficiaries(token: widget.authToken);
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _options = picked
            .where((o) => o.id == 'fosa')
            .map(
              (o) => MemberAccountOption(
                id: o.id,
                name: o.name,
                mask: o.mask,
                balance: o.balanceCents / 100.0,
              ),
            )
            .toList();
        _frequent = frequent.where((b) => (b.phone ?? '').isNotEmpty).toList();
        _from = _options.isNotEmpty
            ? _options.firstWhere(
                (a) => a.id == 'fosa',
                orElse: () => _options.first,
              )
            : null;
        _network = catalog.enabled && catalog.networks.isNotEmpty ? catalog.networks.first : _demoNetworks.first;
        _phone.text = profile.phone;
        _mpesaPhone.text = profile.phone;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load accounts.';
        _network = _demoNetworks.first;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    _mpesaPhone.dispose();
    super.dispose();
  }

  int? get _amountCents {
    if (_purchaseType == 'DATA') return _bundle?.amountCents;
    final amt = double.tryParse(_amount.text.replaceAll(',', ''));
    return amt == null || amt <= 0 ? null : (amt * 100).round();
  }

  bool get _valid {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final amount = _amountCents;
    return digits.length >= 9 && amount != null && amount > 0 && _network != null;
  }

  bool get _demoMode {
    final catalog = _catalog;
    return catalog == null || !catalog.enabled || catalog.networks.isEmpty;
  }

  List<MemberUtilityNetwork> get _displayNetworks => _demoMode ? _demoNetworks : (_catalog?.networks ?? const []);

  Future<void> _submit() async {
    final amountCents = _amountCents;
    final network = _network;
    if (!_valid || amountCents == null || network == null) return;
    if (!_demoMode && _source == 'FOSA' && _from != null && amountCents > (_from!.balance * 100).round()) {
      showFlowErrorSnack(context, 'Insufficient FOSA balance.');
      return;
    }
    final confirmed = await showFlowConfirmationSheet(
      context,
      title: 'Confirm ${_purchaseType == 'DATA' ? 'data' : 'airtime'} purchase',
      rows: [
        ('Provider', network.name),
        ('Recipient', _phone.text.trim()),
        ('Amount', 'KES ${formatKes(amountCents / 100)}'),
        ('Pay from', _source == 'FOSA' ? (_from?.name ?? 'FOSA') : 'M-Pesa'),
      ],
      confirmLabel: 'Submit Request',
      icon: Icons.phone_android_rounded,
    );
    if (!confirmed) return;
    if (_demoMode) {
      showFlowErrorSnack(context, 'Demo only: no airtime or data request was sent.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ProsaccoMemberAuthApi().submitUtilityPayment(
        token: widget.authToken,
        paymentType: _purchaseType,
        amountCents: amountCents,
        paymentSource: _source,
        network: network.code,
        providerName: network.name,
        recipientPhone: _phone.text.trim(),
        productCode: _bundle?.code,
        productName: _bundle?.name,
        sourcePhone: _mpesaPhone.text.trim(),
        saveRecipient: false,
      );
      if (!mounted) return;
      await showTransactionReceiptSheet(
        context,
        authToken: widget.authToken,
        transactionRef: result.transactionRef,
        fallbackTitle: 'Request recorded',
        fallbackMessage: '${network.name} ${_purchaseType == 'DATA' ? 'data' : 'airtime'} request ref ${result.transactionRef} is ${result.status}. ${result.message}',
        icon: Icons.phone_android_rounded,
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
        appBar: AppBar(title: const Text('Buy airtime')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }

    final catalog = _catalog;
    final demoMode = _demoMode;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Airtime & Data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_loadError!, style: TextStyle(color: p.error)),
            ),
          _BackendStatusCard(
            message: demoMode
                ? 'Demo mode: sample networks and bundles are shown for walkthrough only. No request will be sent.'
                : 'Airtime and data are enabled by your SACCO. Provider: ${catalog?.displayName ?? 'SACCO payment provider'} (${catalog?.providerMode ?? 'FRAMEWORK_ONLY'}).',
            mpesaEnabled: !demoMode && (catalog?.mpesaEnabled ?? false),
          ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Network',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _displayNetworks.map((n) {
                final selected = _network?.code == n.code;
                return ChoiceChip(
                  selected: selected,
                  avatar: _NetworkLogo(network: n),
                  label: Text(n.name),
                  onSelected: (_) => setState(() {
                    _network = n;
                    _bundle = null;
                  }),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Airtime or data',
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'AIRTIME', label: Text('Airtime')),
                ButtonSegment(value: 'DATA', label: Text('Data Bundles')),
              ],
              selected: {_purchaseType},
              onSelectionChanged: (v) => setState(() {
                _purchaseType = v.first;
                _bundle = null;
              }),
            ),
          ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Destination number',
            child: Column(
              children: [
                if (_frequent.isNotEmpty)
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _frequent.length.clamp(0, 6),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final b = _frequent[i];
                        return ActionChip(
                          label: Text(b.nickname),
                          onPressed: () => setState(() => _phone.text = b.phone ?? ''),
                        );
                      },
                    ),
                  ),
                if (_frequent.isNotEmpty) const SizedBox(height: 10),
                TextField(
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
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_purchaseType == 'AIRTIME')
            FlowSectionCard(
              title: 'Amount',
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [10, 20, 50, 100, 200, 500].map((v) {
                      return ActionChip(
                        label: Text('KES $v'),
                        onPressed: () => setState(() => _amount.text = '$v'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
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
                ],
              ),
            )
          else
            FlowSectionCard(
              title: 'Bundle',
              child: (_network?.bundles.isEmpty ?? true)
                  ? const Text('No data bundles configured for this network yet.')
                  : Column(
                      children: _network!.bundles.map((bundle) {
                        return RadioListTile<MemberDataBundle>(
                          value: bundle,
                          groupValue: _bundle,
                          onChanged: (v) => setState(() => _bundle = v),
                          title: Text(bundle.name),
                          subtitle: Text(bundle.validity ?? 'Data bundle'),
                          secondary: Text('KES ${formatKes(bundle.amountCents / 100)}'),
                        );
                      }).toList(),
                    ),
            ),
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Payment source',
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'FOSA',
                  groupValue: _source,
                  onChanged: (_) => setState(() => _source = 'FOSA'),
                  title: const Text('FOSA account'),
                  subtitle: Text(_from == null ? 'No active FOSA' : 'Bal: KES ${formatKes(_from!.balance)}'),
                ),
                RadioListTile<String>(
                  value: 'MPESA',
                  groupValue: _source,
                  onChanged: !demoMode && (catalog?.mpesaEnabled ?? false) ? (_) => setState(() => _source = 'MPESA') : null,
                  title: const Text('M-Pesa STK Push'),
                  subtitle: Text(!demoMode && (catalog?.mpesaEnabled ?? false) ? 'Use phone prompt' : 'Not enabled in demo mode'),
                ),
                if (_source == 'MPESA')
                  TextField(
                    controller: _mpesaPhone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'M-Pesa phone', border: OutlineInputBorder()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _valid && !_submitting ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              demoMode ? 'Preview demo request' : 'Submit request',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkLogo extends StatelessWidget {
  const _NetworkLogo({required this.network});
  final MemberUtilityNetwork network;

  @override
  Widget build(BuildContext context) {
    final url = network.logoUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(url));
    }
    return CircleAvatar(child: Text(network.name.isEmpty ? '?' : network.name.substring(0, 1).toUpperCase()));
  }
}

class _BackendStatusCard extends StatelessWidget {
  const _BackendStatusCard({
    required this.message,
    required this.mpesaEnabled,
  });

  final String message;
  final bool mpesaEnabled;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return FlowSectionCard(
      title: 'Backend status',
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
