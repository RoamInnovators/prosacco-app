import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import 'airtime_screen.dart';
import 'bill_payment_screen.dart';

class PaymentHubScreen extends StatelessWidget {
  const PaymentHubScreen({super.key, required this.authToken});

  final String authToken;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Pay')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Choose what you want to pay for.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: p.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 24),
          _PaymentTile(
            icon: Icons.receipt_long_rounded,
            title: 'Pay Bills',
            subtitle: 'KPLC, water, TV, internet and other configured billers',
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BillPaymentScreen(authToken: authToken),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PaymentTile(
            icon: Icons.phone_android_rounded,
            title: 'Airtime & Data',
            subtitle: 'Buy airtime or data bundles for yourself or another number',
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AirtimeScreen(authToken: authToken),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: p.headlineGreen,
                          ),
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
