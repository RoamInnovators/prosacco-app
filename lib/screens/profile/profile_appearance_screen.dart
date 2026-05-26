import 'package:flutter/material.dart';

import '../../theme/app_theme_scope.dart';
import '../../theme/prosacco_palette.dart';

class ProfileAppearanceScreen extends StatelessWidget {
  const ProfileAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final controller = AppThemeScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: p.surface,
          appBar: AppBar(title: const Text('Appearance')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Theme follows docs/member.md (green & white in light mode) and '
                'profile_security dark accents (#97F3B5 on slate) in dark mode.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: p.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 28),
              Text(
                'APP THEME',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: p.secondary,
                    ),
              ),
              const SizedBox(height: 12),
              _ThemeOptionCard(
                selected: controller.mode == ThemeMode.light,
                title: 'Light',
                subtitle: 'Green and white — default',
                icon: Icons.light_mode_rounded,
                onTap: () => controller.setMode(ThemeMode.light),
              ),
              const SizedBox(height: 10),
              _ThemeOptionCard(
                selected: controller.mode == ThemeMode.dark,
                title: 'Dark mode',
                subtitle: 'Easier on eyes in low light',
                icon: Icons.dark_mode_rounded,
                onTap: () => controller.setMode(ThemeMode.dark),
              ),
              const SizedBox(height: 10),
              _ThemeOptionCard(
                selected: controller.mode == ThemeMode.system,
                title: 'System',
                subtitle: 'Match device setting',
                icon: Icons.brightness_auto_rounded,
                onTap: () => controller.setMode(ThemeMode.system),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: p.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? p.primary
                  : p.outline.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: p.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: p.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: p.primary, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
