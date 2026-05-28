import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import 'transfer_bank_screen.dart';
import 'transfer_member_screen.dart';
import 'transfer_mobile_screen.dart';
import 'transfer_own_account_screen.dart';

class TransferHubScreen extends StatelessWidget {
  const TransferHubScreen({super.key, required this.authToken});

  final String authToken;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Transfer')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Choose how you want to send money.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: p.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 24),
          _HubTile(
            icon: Icons.smartphone_rounded,
            title: 'Send to mobile',
            subtitle: 'M-Pesa or Airtel — self or another number',
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TransferMobileScreen(authToken: authToken),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HubTile(
            icon: Icons.account_balance_rounded,
            title: 'Send to bank',
            subtitle: 'PesaLink to any Kenyan bank',
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TransferBankScreen(authToken: authToken),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HubTile(
            icon: Icons.group_rounded,
            title: 'Send to member',
            subtitle: 'Transfer to another member by account number',
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TransferMemberScreen(authToken: authToken),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HubTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Between my accounts',
            subtitle: 'Move funds between eligible accounts you own',
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TransferOwnAccountScreen(authToken: authToken),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
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
