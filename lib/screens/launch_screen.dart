import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/prosacco_palette.dart';

/// Industry-themed launch: SACCO institution, savings, lending growth, security, statements.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  static const List<IconData> _industryIcons = [
    Icons.account_balance_rounded,
    Icons.savings_outlined,
    Icons.trending_up_rounded,
    Icons.shield_outlined,
    Icons.receipt_long_outlined,
  ];

  late final AnimationController _entrance;
  late final AnimationController _orbit;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _entrance.forward();

    Future<void>.delayed(const Duration(seconds: 10), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _orbit.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pal.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SoftGradientBackdrop(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                _buildHeroMark(),
                const SizedBox(height: 28),
                _buildWordmark(),
                const SizedBox(height: 8),
                Text(
                  'Your digital SACCO branch',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.pal.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                ),
                const Spacer(flex: 2),
                _buildIconRow(),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMark() {
    return AnimatedBuilder(
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
                  size: const Size(132, 132),
                  painter: _OrbitRingPainter(
                    progress: _orbit.value,
                    color: context.pal.primary.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.pal.primary,
                      context.pal.primaryContainer,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.pal.primary.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordmark() {
    return Text(
      'ProSacco',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.pal.primary,
            letterSpacing: -0.5,
          ),
    );
  }

  Widget _buildIconRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: Listenable.merge([_entrance, _orbit]),
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_industryIcons.length, (i) {
              final start = i * 0.12;
              final end = math.min(0.55 + i * 0.1, 1.0);
              final curve = Interval(
                start,
                end,
                curve: Curves.easeOutCubic,
              );
              final v = curve.transform(_entrance.value);
              final opacity = v.clamp(0.0, 1.0);
              final scale = 0.35 + v * 0.65;
              final dy = (1 - v) * 18;
              final wobble =
                  math.sin(_orbit.value * 2 * math.pi + i * 0.9) * 3.0;
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, dy + wobble),
                  child: Transform.scale(
                    scale: scale,
                    child: _IconTile(icon: _industryIcons[i]),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _SoftGradientBackdrop extends StatelessWidget {
  const _SoftGradientBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.pal.primary.withValues(alpha: 0.08),
            context.pal.surfaceBright,
            context.pal.surfaceBright,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.pal.onSurface.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 26,
        color: context.pal.primary,
      ),
    );
  }
}

/// Subtle rotating dash ring (ledger / motion) behind the hero icon.
class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    const dashCount = 10;
    const sweep = 2 * math.pi / dashCount;
    for (var i = 0; i < dashCount; i++) {
      final a = (i / dashCount) * 2 * math.pi + progress * 2 * math.pi;
      final opacity = 0.25 + 0.55 * ((i + progress * dashCount) % 3) / 3;
      final p = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a,
        sweep * 0.55,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
