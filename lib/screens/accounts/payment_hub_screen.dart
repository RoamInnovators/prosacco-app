import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'airtime_screen.dart';
import 'bill_payment_screen.dart';

class PaymentHubScreen extends StatefulWidget {
  const PaymentHubScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<PaymentHubScreen> createState() => _PaymentHubScreenState();
}

class _PaymentHubScreenState extends State<PaymentHubScreen> {
  MemberUtilityCatalog? _catalog;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await ProsaccoMemberAuthApi().fetchUtilityPaymentCatalog(token: widget.authToken);
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e?.toString() ?? 'Could not load payment availability.';
        _loading = false;
      });
    }
  }

  ({bool enabled, String label}) get _billStatus {
    final catalog = _catalog;
    if (catalog == null) return (enabled: true, label: _loading ? 'Checking...' : 'Demo available');
    if (!catalog.enabled) return (enabled: true, label: 'Demo available');
    if (catalog.billers.isEmpty) return (enabled: true, label: 'Demo available');
    return (enabled: true, label: 'Enabled');
  }

  ({bool enabled, String label}) get _airtimeStatus {
    final catalog = _catalog;
    if (catalog == null) return (enabled: true, label: _loading ? 'Checking...' : 'Demo available');
    if (!catalog.enabled) return (enabled: true, label: 'Demo available');
    if (catalog.networks.isEmpty) return (enabled: true, label: 'Demo available');
    return (enabled: true, label: 'Enabled');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final billStatus = _billStatus;
    final airtimeStatus = _airtimeStatus;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Pay')),
      body: RefreshIndicator(
        onRefresh: _loadStatus,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Choose what you want to pay for.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: ProsaccoAnimatedLoader(size: 72))
            else if (_error != null)
              _StatusMessage(message: 'Live payment status could not be loaded. Demo mode is available.', isError: false)
            else if (_catalog != null)
              _StatusMessage(
                message: _catalog!.enabled
                    ? 'Bill payments, airtime and data are enabled by your SACCO. Empty services still show demo samples.'
                    : 'Live payments are disabled by your SACCO. Demo mode is available.',
                isError: false,
              ),
            const SizedBox(height: 24),
            _PaymentTile(
              icon: Icons.receipt_long_rounded,
              title: 'Pay Bills',
              subtitle: 'KPLC, water, TV, internet and other configured billers',
              statusLabel: billStatus.label,
              enabled: billStatus.enabled,
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BillPaymentScreen(authToken: widget.authToken),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PaymentTile(
              icon: Icons.phone_android_rounded,
              title: 'Airtime & Data',
              subtitle: 'Buy airtime or data bundles for yourself or another number',
              statusLabel: airtimeStatus.label,
              enabled: airtimeStatus.enabled,
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AirtimeScreen(authToken: widget.authToken),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final bool enabled;
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: p.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: p.headlineGreen,
                                ),
                          ),
                        ),
                        _StatusPill(label: statusLabel, enabled: enabled),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: p.onSurfaceVariant,
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

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? p.error : p.success).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isError ? p.error : p.success).withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isError ? p.error : p.success,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = enabled ? p.success : p.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
