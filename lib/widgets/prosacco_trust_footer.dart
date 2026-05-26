import 'package:flutter/material.dart';

import '../theme/prosacco_palette.dart';

const List<double> prosaccoGreyscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

/// Trust badges row from `prosacco design/login/code.html`.
class ProsaccoTrustFooter extends StatelessWidget {
  const ProsaccoTrustFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(prosaccoGreyscaleMatrix),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _trustChip(context, Icons.verified_user_outlined, 'Bank-Level Security'),
            const SizedBox(width: 24),
            _trustChip(context, Icons.enhanced_encryption_outlined, 'AES-256 Encrypted'),
          ],
        ),
      ),
    );
  }
}

Widget _trustChip(BuildContext context, IconData icon, String label) {
  final c = context.pal.onSurface;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: c),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: c,
        ),
      ),
    ],
  );
}
