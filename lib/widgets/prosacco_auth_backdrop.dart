import 'package:flutter/material.dart';

import '../theme/prosacco_palette.dart';

/// Editorial background blobs — matches `prosacco design/login` and related auth screens.
class ProsaccoAuthBackdrop extends StatelessWidget {
  const ProsaccoAuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.4,
              height: MediaQuery.sizeOf(context).width * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.pal.primary.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: context.pal.primary.withValues(alpha: 0.04),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.3,
              height: MediaQuery.sizeOf(context).width * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.pal.secondary.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: context.pal.secondary.withValues(alpha: 0.04),
                    blurRadius: 100,
                    spreadRadius: 32,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
