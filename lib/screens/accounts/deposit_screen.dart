import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amount = TextEditingController();
  List<MemberAccountOption> _options = const [];
  MemberAccountOption? _target;
  bool _submitting = false;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _amount.dispose();
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
      final depositOptions = picked
          .map(
            (o) => MemberAccountOption(
              id: o.id,
              name: o.name,
              mask: o.mask,
              balance: o.balanceCents / 100.0,
            ),
          )
          .where((o) => o.id == 'fosa' || o.id == 'bosa')
          .toList();
      if (!mounted) return;
      setState(() {
        _options = depositOptions;
        // Default: FOSA when available.
        _target = depositOptions.where((o) => o.id == 'fosa').isNotEmpty
            ? depositOptions.firstWhere((o) => o.id == 'fosa')
            : (depositOptions.isNotEmpty ? depositOptions.first : null);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load accounts.';
        _options = const [];
        _target = null;
        _loading = false;
      });
    }
  }

  bool get _valid {
    final amt = double.tryParse(_amount.text.replaceAll(',', ''));
    return _target != null && amt != null && amt > 0 && !_submitting;
  }

  Future<void> _submit() async {
    if (!_valid) return;
    final target = _target;
    if (target == null) return;

    final amtKes = double.parse(_amount.text.replaceAll(',', ''));
    final amountCents = (amtKes * 100).round();
    if (amountCents < 100) return;

    setState(() => _submitting = true);
    try {
      final api = ProsaccoMemberAuthApi();
      final url = target.id == 'fosa'
          ? await api.initiateFosaDepositPaystack(
              token: widget.authToken,
              amountCents: amountCents,
            )
          : await api.initiateBosaDepositPaystack(
              token: widget.authToken,
              amountCents: amountCents,
            );

      if (!mounted) return;
      final ok = await Navigator.of(context).push<_PaystackWebViewResult>(
        MaterialPageRoute<_PaystackWebViewResult>(
          builder: (_) => _PaystackWebViewScreen(
            url: url,
            token: widget.authToken,
            accountType: target.id == 'fosa' ? 'fosa' : 'bosa',
          ),
        ),
      );
      if (!mounted) return;
      if (ok?.ok == true) {
        // Close the deposit page so the user returns to Accounts.
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      showFlowErrorSnack(context, e?.toString() ?? 'Failed to start deposit.');
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
          title: const Text('Deposit'),
        ),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        title: const Text('Deposit'),
      ),
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
          const SizedBox(height: 14),
          FlowSectionCard(
            title: 'Deposit funds to',
            child: DropdownButtonFormField<MemberAccountOption>(
              value: _target,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              items: _options
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(
                        '${a.name} · ${a.mask}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _target = v),
            ),
          ),
          const SizedBox(height: 14),
          if (_target != null) _buildAccountPreview(context, _target!),
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
                prefixStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: p.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _valid ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: ThemeData.estimateBrightnessForColor(p.primary) ==
                      Brightness.dark
                  ? Colors.white
                  : const Color(0xFF022C22),
              disabledBackgroundColor: p.outline.withValues(alpha: 0.25),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Deposit',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
}

class _PaystackWebViewScreen extends StatefulWidget {
  const _PaystackWebViewScreen({
    required this.url,
    required this.token,
    required this.accountType,
  });

  final String url;
  final String token;
  final String accountType; // 'fosa' or 'bosa'

  @override
  State<_PaystackWebViewScreen> createState() => _PaystackWebViewScreenState();
}

class _PaystackWebViewResult {
  const _PaystackWebViewResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}

class _PaystackWebViewScreenState extends State<_PaystackWebViewScreen> {
  late final WebViewController _controller;
  bool _handledResult = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            if (_handledResult) return;
            if (!url.contains('/deposit/result')) return;

            final uri = Uri.tryParse(url);
            if (uri == null) return;

            final ref =
                uri.queryParameters['reference'] ?? uri.queryParameters['trxref'];
            if (ref == null || ref.isEmpty) return;

            _handledResult = true;
            setState(() => _verifying = true);

            try {
              final api = ProsaccoMemberAuthApi();
              final res = widget.accountType == 'fosa'
                  ? await api.verifyFosaDepositPaystack(
                      token: widget.token,
                      reference: ref,
                    )
                  : await api.verifyBosaDepositPaystack(
                      token: widget.token,
                      reference: ref,
                    );

              if (!mounted) return;

              if (res.ok) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green.withValues(alpha: 0.95),
                    duration: const Duration(seconds: 4),
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    content: Text(res.message),
                  ),
                );
              } else {
                showFlowErrorSnack(context, res.message);
              }

              if (mounted) {
                Navigator.of(context).pop(
                  _PaystackWebViewResult(ok: res.ok, message: res.message),
                );
              }
            } catch (e) {
              if (!mounted) return;
              showFlowErrorSnack(context, e?.toString() ?? 'Deposit verification failed.');
              Navigator.of(context).pop(
                const _PaystackWebViewResult(
                  ok: false,
                  message: 'Deposit verification failed.',
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paystack'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_verifying)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: ProsaccoAnimatedLoader(size: 88),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
