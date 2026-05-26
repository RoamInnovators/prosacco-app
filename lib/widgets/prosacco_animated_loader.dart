import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/prosacco_palette.dart';

/// Animated loader reused across pages (orbit ring + pulsing icon).
///
/// It is intentionally similar to the app launch `LaunchScreen` preloader.
class ProsaccoAnimatedLoader extends StatefulWidget {
  const ProsaccoAnimatedLoader({
    super.key,
    this.size = 110,
  });

  /// Overall size of the loader square.
  final double size;

  @override
  State<ProsaccoAnimatedLoader> createState() =>
      _ProsaccoAnimatedLoaderState();
}

class _ProsaccoAnimatedLoaderState extends State<ProsaccoAnimatedLoader>
    with TickerProviderStateMixin {
  late final AnimationController _orbit;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbit.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_orbit, _pulse]),
        builder: (context, child) {
          final t = _orbit.value * 2 * math.pi;
          final breathe = 1.0 + (_pulse.value * 0.06);

          return Transform.scale(
            scale: breathe,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: t * 0.08,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _OrbitRingPainter(
                      progress: _orbit.value,
                      color: p.primary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Container(
                  width: widget.size * 0.62,
                  height: widget.size * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        p.primary,
                        p.primaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.primary.withValues(alpha: 0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.groups_2_rounded,
                    size: widget.size * 0.22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Subtle rotating dash ring (ledger / motion) behind the icon.
class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    const dashCount = 10;
    final sweep = 2 * math.pi / dashCount;

    for (var i = 0; i < dashCount; i++) {
      final a = (i / dashCount) * 2 * math.pi + progress * 2 * math.pi;
      final opacity = 0.25 + 0.55 * ((i + progress * dashCount) % 3) / 3;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a,
        sweep * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

