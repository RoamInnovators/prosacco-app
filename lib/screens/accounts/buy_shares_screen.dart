import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'account_flow_widgets.dart';
import 'account_models.dart';

enum _PaySource { fosa, bosa, paystack }

class BuySharesScreen extends StatefulWidget {
  const BuySharesScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<BuySharesScreen> createState() => _BuySharesScreenState();
}

class _BuySharesScreenState extends State<BuySharesScreen> {
  final _amount = TextEditingController();
  SharePurchaseContext? _ctx;
  _PaySource _source = _PaySource.fosa;
  bool _loading = true;
  String? _loadError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final api = ProsaccoMemberAuthApi();
      final ctx = await api.fetchSharePurchaseContext(token: widget.authToken);
      if (!mounted) return;
      // Default to FOSA if available, else BOSA, else Paystack
      _PaySource defaultSource = _PaySource.paystack;
      if ((ctx.fosaBalanceCents ?? 0) > 0) {
        defaultSource = _PaySource.fosa;
      } else if ((ctx.bosa?.availableForPurchaseCents ?? 0) > 0) {
        defaultSource = _PaySource.bosa;
      }
      setState(() {
        _ctx = ctx;
        _source = defaultSource;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load share details.';
        _loading = false;
      });
    }
  }

  double? get _amt =>
      double.tryParse(_amount.text.replaceAll(',', ''))?.clamp(0, 1e15);

  int get _sharesPreview {
    final ctx = _ctx;
    if (ctx == null || _amt == null || ctx.pricePerShareCents == 0) return 0;
    return (_amt! * 100 / ctx.pricePerShareCents).floor();
  }

  bool get _ok {
    if (_ctx == null || _amt == null || _amt! <= 0 || _submitting) return false;
    if (_source == _PaySource.fosa) {
      final fosa = (_ctx!.fosaBalanceCents ?? 0) / 100.0;
      return _amt! <= fosa;
    }
    if (_source == _PaySource.bosa) {
      final bosa = (_ctx!.bosa?.availableForPurchaseCents ?? 0) / 100.0;
      return _amt! <= bosa;
    }
    return true; // Paystack — no local balance check
  }

  Future<void> _submit() async {
    if (!_ok || _ctx == null || _amt == null) return;
    final amountCents = (_amt! * 100).round();
    final sourceLabel = switch (_source) {
      _PaySource.fosa => 'FOSA Account',
      _PaySource.bosa => 'BOSA Savings',
      _PaySource.paystack => 'Paystack',
    };
    final fee = await previewFlowFee(
      context,
      authToken: widget.authToken,
      serviceType: 'SHARE_PURCHASE',
      amountCents: amountCents,
      contextData: {
        'sharesCount': _sharesPreview,
        'pricePerShare': _ctx!.pricePerShareCents,
      },
    );
    final confirmed = await showFlowConfirmationSheet(
      context,
      title: 'Confirm share purchase',
      rows: [
        ('Pay from', sourceLabel),
        ('Amount', 'KES ${formatKes(_amt!)}'),
        ('Transfer fee', 'KES ${formatKes(fee.feeAmount / 100)}'),
        ('Total debit', 'KES ${formatKes(fee.totalAmount / 100)}'),
        ('Shares', '$_sharesPreview unit(s)'),
      ],
      confirmLabel: 'Buy Shares',
    );
    if (!confirmed) return;
    setState(() => _submitting = true);
    try {
      final api = ProsaccoMemberAuthApi();
      if (_source == _PaySource.fosa) {
        final result = await api.buySharesFromFosa(
          token: widget.authToken,
          amountCents: amountCents,
        );
        if (!mounted) return;
        await showTransactionReceiptSheet(
          context,
          authToken: widget.authToken,
          transactionRef: result.transactionRef,
          fallbackTitle: 'Shares purchased',
          fallbackMessage:
              'KES ${formatKes(_amt!)} debited from FOSA. You received $_sharesPreview unit(s).',
        );
      } else if (_source == _PaySource.bosa) {
        final result = await api.buySharesFromBosa(
          token: widget.authToken,
          amountCents: amountCents,
        );
        if (!mounted) return;
        await showTransactionReceiptSheet(
          context,
          authToken: widget.authToken,
          transactionRef: result.transactionRef,
          fallbackTitle: 'Shares purchased',
          fallbackMessage:
              'KES ${formatKes(_amt!)} debited from BOSA. You received $_sharesPreview unit(s).',
        );
      } else {
        // Paystack
        final url = await api.initiateSharePurchasePaystack(
          token: widget.authToken,
          amountCents: amountCents,
        );
        if (!mounted) return;
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => _SharePaystackWebView(
              url: url,
              token: widget.authToken,
            ),
          ),
        );
        if (!mounted) return;
        if (ok == true) Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      showFlowErrorSnack(context, e?.toString() ?? 'Share purchase failed.');
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
        appBar: AppBar(title: const Text('Buy Shares')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }

    if (_loadError != null || _ctx == null) {
      return Scaffold(
        backgroundColor: p.surface,
        appBar: AppBar(title: const Text('Buy Shares')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError ?? 'Could not load share details.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final ctx = _ctx!;
    final pricePerShare = ctx.pricePerShareCents / 100.0;
    final fosaBalance = (ctx.fosaBalanceCents ?? 0) / 100.0;
    final bosaAvailable = (ctx.bosa?.availableForPurchaseCents ?? 0) / 100.0;

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Buy Shares')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Current holdings summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatPill(
                  label: 'You own',
                  value: '${ctx.totalShares} units',
                  palette: p,
                ),
                _StatPill(
                  label: 'Price / share',
                  value: 'KES ${formatKes(pricePerShare)}',
                  palette: p,
                ),
                if (ctx.maxSharesAllowed != null)
                  _StatPill(
                    label: 'Max allowed',
                    value: '${ctx.maxSharesAllowed} units',
                    palette: p,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment source
          FlowSectionCard(
            title: 'Pay from',
            child: Column(
              children: [
                if (ctx.fosaBalanceCents != null)
                  _SourceTile(
                    label: 'FOSA Account',
                    subtitle: 'Balance: KES ${formatKes(fosaBalance)}',
                    value: _PaySource.fosa,
                    groupValue: _source,
                    onChanged: (v) => setState(() => _source = v!),
                    palette: p,
                  ),
                if (ctx.bosa != null)
                  _SourceTile(
                    label: 'BOSA Savings',
                    subtitle: 'Available: KES ${formatKes(bosaAvailable)}',
                    value: _PaySource.bosa,
                    groupValue: _source,
                    onChanged: (v) => setState(() => _source = v!),
                    palette: p,
                  ),
                if (ctx.paystackConfigured)
                  _SourceTile(
                    label: 'Card / M-Pesa (Paystack)',
                    subtitle: 'Pay online via Paystack',
                    value: _PaySource.paystack,
                    groupValue: _source,
                    onChanged: (v) => setState(() => _source = v!),
                    palette: p,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Amount
          FlowSectionCard(
            title: 'Amount (KES)',
            child: TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

          // Live share preview
          if (_amt != null && _amt! > 0 && ctx.pricePerShareCents > 0) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'You will receive approximately $_sharesPreview share unit(s).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: p.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],

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
                    'Buy Shares',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final ProsaccoPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: palette.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.palette,
  });

  final String label;
  final String subtitle;
  final _PaySource value;
  final _PaySource groupValue;
  final ValueChanged<_PaySource?> onChanged;
  final ProsaccoPalette palette;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<_PaySource>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: palette.primary,
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: palette.onSurface,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: palette.onSurfaceVariant, fontSize: 12),
      ),
    );
  }
}

// ── Paystack WebView for share purchase ───────────────────────────────────────

class _SharePaystackWebView extends StatefulWidget {
  const _SharePaystackWebView({required this.url, required this.token});

  final String url;
  final String token;

  @override
  State<_SharePaystackWebView> createState() => _SharePaystackWebViewState();
}

class _SharePaystackWebViewState extends State<_SharePaystackWebView> {
  late final WebViewController _controller;
  bool _handled = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            if (_handled) return;
            if (!url.contains('/shares/purchase/result')) return;

            final uri = Uri.tryParse(url);
            if (uri == null) return;
            final ref = uri.queryParameters['reference'] ??
                uri.queryParameters['trxref'];
            if (ref == null || ref.isEmpty) return;

            _handled = true;
            setState(() => _verifying = true);

            try {
              final api = ProsaccoMemberAuthApi();
              final ok = await api.verifySharePurchasePaystack(
                token: widget.token,
                reference: ref,
              );
              if (mounted) Navigator.of(context).pop(ok);
            } catch (_) {
              if (mounted) Navigator.of(context).pop(false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paystack')),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_verifying)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black38,
                  child: Center(child: ProsaccoAnimatedLoader(size: 88)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
