import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';

class ProfileMfaScreen extends StatelessWidget {
  const ProfileMfaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Two-factor authentication')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.secondaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, color: p.primary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MFA is enabled',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: p.headlineGreen,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign-ins require your authenticator app or SMS code.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: p.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _tile(context, 'Backup codes', 'View or regenerate'),
          _tile(context, 'Trusted devices', 'Manage where MFA is skipped'),
          _tile(context, 'Authenticator app', 'Set up Google / Microsoft Authenticator'),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String sub) {
    final p = context.pal;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: p.onSurface)),
        subtitle: Text(sub, style: TextStyle(color: p.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right_rounded, color: p.outline),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title — connect security API')),
          );
        },
      ),
    );
  }
}
