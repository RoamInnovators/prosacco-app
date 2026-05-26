import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gender-aware 3D cartoon avatar placeholder.
/// Shows a stylised cartoon face based on [gender].
/// Values: 'male', 'female', 'M', 'F', 'MALE', 'FEMALE' (case-insensitive).
/// Falls back to a neutral avatar for unknown/null gender.
class CartoonAvatar extends StatelessWidget {
  const CartoonAvatar({
    super.key,
    this.gender,
    this.size = 112,
  });

  final String? gender;
  final double size;

  bool get _isFemale {
    final g = (gender ?? '').toLowerCase().trim();
    return g == 'female' || g == 'f';
  }

  bool get _isMale {
    final g = (gender ?? '').toLowerCase().trim();
    return g == 'male' || g == 'm';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _isFemale
            ? _FemaleCartoonPainter()
            : _isMale
                ? _MaleCartoonPainter()
                : _NeutralCartoonPainter(),
      ),
    );
  }
}

// ── Shared drawing helpers ────────────────────────────────────────────────────

void _drawFace({
  required Canvas canvas,
  required Size size,
  required Color skinLight,
  required Color skinDark,
  required Color skinShadow,
}) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final r = size.width * 0.38;

  // Background circle (soft gradient feel via two circles)
  final bgPaint = Paint()..color = skinLight;
  canvas.drawCircle(Offset(cx, cy), r, bgPaint);

  // Subtle shadow on lower half for 3D depth
  final shadowPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(0, 0.4),
      radius: 0.7,
      colors: [skinShadow.withValues(alpha: 0.0), skinShadow.withValues(alpha: 0.35)],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
  canvas.drawCircle(Offset(cx, cy), r, shadowPaint);

  // Cheek blush
  final blushPaint = Paint()..color = const Color(0xFFFFB3B3).withValues(alpha: 0.45);
  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx - r * 0.52, cy + r * 0.18), width: r * 0.42, height: r * 0.22),
    blushPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx + r * 0.52, cy + r * 0.18), width: r * 0.42, height: r * 0.22),
    blushPaint,
  );
}

void _drawEyes({
  required Canvas canvas,
  required Size size,
  required Color eyeWhite,
  required Color iris,
  required Color pupil,
}) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final r = size.width * 0.38;

  for (final side in [-1.0, 1.0]) {
    final ex = cx + side * r * 0.38;
    final ey = cy - r * 0.08;

    // White
    canvas.drawOval(
      Rect.fromCenter(center: Offset(ex, ey), width: r * 0.32, height: r * 0.26),
      Paint()..color = eyeWhite,
    );
    // Iris
    canvas.drawCircle(Offset(ex, ey), r * 0.11, Paint()..color = iris);
    // Pupil
    canvas.drawCircle(Offset(ex, ey), r * 0.065, Paint()..color = pupil);
    // Highlight
    canvas.drawCircle(
      Offset(ex + r * 0.04, ey - r * 0.04),
      r * 0.03,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }
}

void _drawNose({
  required Canvas canvas,
  required Size size,
  required Color color,
}) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final r = size.width * 0.38;

  final path = Path()
    ..moveTo(cx, cy + r * 0.05)
    ..quadraticBezierTo(cx - r * 0.1, cy + r * 0.22, cx - r * 0.08, cy + r * 0.26)
    ..quadraticBezierTo(cx, cy + r * 0.24, cx + r * 0.08, cy + r * 0.26)
    ..quadraticBezierTo(cx + r * 0.1, cy + r * 0.22, cx, cy + r * 0.05);

  canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round);
}

void _drawSmile({
  required Canvas canvas,
  required Size size,
  required Color color,
  double width = 0.38,
}) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final r = size.width * 0.38;

  final path = Path()
    ..moveTo(cx - r * width / 2, cy + r * 0.32)
    ..quadraticBezierTo(cx, cy + r * 0.52, cx + r * width / 2, cy + r * 0.32);

  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round,
  );
}

// ── Male cartoon ──────────────────────────────────────────────────────────────

class _MaleCartoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy),
      size.width / 2,
      Paint()..color = const Color(0xFFDCEEFF),
    );

    // Neck
    final neckPaint = Paint()..color = const Color(0xFFF5C5A3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + r * 1.05), width: r * 0.55, height: r * 0.5),
        const Radius.circular(8),
      ),
      neckPaint,
    );

    // Shirt / body
    final shirtPaint = Paint()..color = const Color(0xFF3B82F6);
    final shirtPath = Path()
      ..moveTo(cx - r * 0.85, size.height)
      ..lineTo(cx - r * 0.85, cy + r * 1.1)
      ..quadraticBezierTo(cx - r * 0.4, cy + r * 0.85, cx, cy + r * 0.9)
      ..quadraticBezierTo(cx + r * 0.4, cy + r * 0.85, cx + r * 0.85, cy + r * 1.1)
      ..lineTo(cx + r * 0.85, size.height)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Face
    _drawFace(
      canvas: canvas,
      size: size,
      skinLight: const Color(0xFFF9D5B0),
      skinDark: const Color(0xFFF0B882),
      skinShadow: const Color(0xFFD4956A),
    );

    // Short hair (male)
    final hairPaint = Paint()..color = const Color(0xFF3D2B1F);
    final hairPath = Path()
      ..moveTo(cx - r * 0.95, cy - r * 0.1)
      ..quadraticBezierTo(cx - r * 0.9, cy - r * 1.05, cx, cy - r * 1.08)
      ..quadraticBezierTo(cx + r * 0.9, cy - r * 1.05, cx + r * 0.95, cy - r * 0.1)
      ..quadraticBezierTo(cx + r * 0.85, cy - r * 0.55, cx, cy - r * 0.6)
      ..quadraticBezierTo(cx - r * 0.85, cy - r * 0.55, cx - r * 0.95, cy - r * 0.1)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Eyebrows (thicker, straighter — male)
    final browPaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final side in [-1.0, 1.0]) {
      final bx = cx + side * r * 0.38;
      final by = cy - r * 0.28;
      canvas.drawLine(
        Offset(bx - r * 0.14, by),
        Offset(bx + r * 0.14, by),
        browPaint,
      );
    }

    _drawEyes(
      canvas: canvas,
      size: size,
      eyeWhite: Colors.white,
      iris: const Color(0xFF5B3A29),
      pupil: const Color(0xFF1A0A00),
    );
    _drawNose(canvas: canvas, size: size, color: const Color(0xFFD4956A));
    _drawSmile(canvas: canvas, size: size, color: const Color(0xFFB05A3A));

    // Ear left
    final earPaint = Paint()..color = const Color(0xFFF9D5B0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r * 0.97, cy + r * 0.05), width: r * 0.22, height: r * 0.32),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r * 0.97, cy + r * 0.05), width: r * 0.22, height: r * 0.32),
      earPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Female cartoon ────────────────────────────────────────────────────────────

class _FemaleCartoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy),
      size.width / 2,
      Paint()..color = const Color(0xFFFFE8F4),
    );

    // Neck
    final neckPaint = Paint()..color = const Color(0xFFF5C5A3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + r * 1.05), width: r * 0.5, height: r * 0.5),
        const Radius.circular(8),
      ),
      neckPaint,
    );

    // Top / blouse
    final topPaint = Paint()..color = const Color(0xFFEC4899);
    final topPath = Path()
      ..moveTo(cx - r * 0.85, size.height)
      ..lineTo(cx - r * 0.85, cy + r * 1.1)
      ..quadraticBezierTo(cx - r * 0.4, cy + r * 0.85, cx, cy + r * 0.9)
      ..quadraticBezierTo(cx + r * 0.4, cy + r * 0.85, cx + r * 0.85, cy + r * 1.1)
      ..lineTo(cx + r * 0.85, size.height)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // Long hair (behind face — drawn first)
    final hairPaint = Paint()..color = const Color(0xFF6B3A2A);
    // Left side hair
    final leftHair = Path()
      ..moveTo(cx - r * 0.95, cy - r * 0.1)
      ..quadraticBezierTo(cx - r * 1.15, cy + r * 0.5, cx - r * 0.9, cy + r * 1.1)
      ..lineTo(cx - r * 0.6, cy + r * 1.1)
      ..quadraticBezierTo(cx - r * 0.85, cy + r * 0.4, cx - r * 0.7, cy - r * 0.1)
      ..close();
    canvas.drawPath(leftHair, hairPaint);
    // Right side hair
    final rightHair = Path()
      ..moveTo(cx + r * 0.95, cy - r * 0.1)
      ..quadraticBezierTo(cx + r * 1.15, cy + r * 0.5, cx + r * 0.9, cy + r * 1.1)
      ..lineTo(cx + r * 0.6, cy + r * 1.1)
      ..quadraticBezierTo(cx + r * 0.85, cy + r * 0.4, cx + r * 0.7, cy - r * 0.1)
      ..close();
    canvas.drawPath(rightHair, hairPaint);

    // Face
    _drawFace(
      canvas: canvas,
      size: size,
      skinLight: const Color(0xFFFDE8D0),
      skinDark: const Color(0xFFF5C5A3),
      skinShadow: const Color(0xFFD4956A),
    );

    // Top hair (over face)
    final topHairPath = Path()
      ..moveTo(cx - r * 0.95, cy - r * 0.1)
      ..quadraticBezierTo(cx - r * 0.9, cy - r * 1.05, cx, cy - r * 1.1)
      ..quadraticBezierTo(cx + r * 0.9, cy - r * 1.05, cx + r * 0.95, cy - r * 0.1)
      ..quadraticBezierTo(cx + r * 0.75, cy - r * 0.65, cx, cy - r * 0.68)
      ..quadraticBezierTo(cx - r * 0.75, cy - r * 0.65, cx - r * 0.95, cy - r * 0.1)
      ..close();
    canvas.drawPath(topHairPath, hairPaint);

    // Ears
    final earPaint = Paint()..color = const Color(0xFFFDE8D0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r * 0.97, cy + r * 0.05), width: r * 0.2, height: r * 0.3),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r * 0.97, cy + r * 0.05), width: r * 0.2, height: r * 0.3),
      earPaint,
    );

    // Earrings
    final earringPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(cx - r * 0.97, cy + r * 0.22), r * 0.055, earringPaint);
    canvas.drawCircle(Offset(cx + r * 0.97, cy + r * 0.22), r * 0.055, earringPaint);

    // Eyebrows (arched — female)
    final browPaint = Paint()
      ..color = const Color(0xFF6B3A2A)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final side in [-1.0, 1.0]) {
      final bx = cx + side * r * 0.38;
      final by = cy - r * 0.3;
      final browPath = Path()
        ..moveTo(bx - r * 0.14, by + r * 0.04)
        ..quadraticBezierTo(bx, by - r * 0.06, bx + r * 0.14, by + r * 0.04);
      canvas.drawPath(browPath, browPaint);
    }

    _drawEyes(
      canvas: canvas,
      size: size,
      eyeWhite: Colors.white,
      iris: const Color(0xFF7B4F3A),
      pupil: const Color(0xFF1A0A00),
    );

    // Eyelashes (female)
    final lashPaint = Paint()
      ..color = const Color(0xFF1A0A00)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final side in [-1.0, 1.0]) {
      final ex = cx + side * r * 0.38;
      final ey = cy - r * 0.08;
      for (var i = -2; i <= 2; i++) {
        final angle = (i * 0.25) + (side > 0 ? math.pi * 0.05 : -math.pi * 0.05);
        canvas.drawLine(
          Offset(ex + math.cos(angle - math.pi / 2) * r * 0.13,
              ey + math.sin(angle - math.pi / 2) * r * 0.13),
          Offset(ex + math.cos(angle - math.pi / 2) * r * 0.19,
              ey + math.sin(angle - math.pi / 2) * r * 0.19),
          lashPaint,
        );
      }
    }

    _drawNose(canvas: canvas, size: size, color: const Color(0xFFD4956A));

    // Lips (female — fuller, pink)
    final lipPath = Path()
      ..moveTo(cx - r * 0.18, cy + r * 0.34)
      ..quadraticBezierTo(cx, cy + r * 0.28, cx + r * 0.18, cy + r * 0.34)
      ..quadraticBezierTo(cx, cy + r * 0.5, cx - r * 0.18, cy + r * 0.34);
    canvas.drawPath(
      lipPath,
      Paint()..color = const Color(0xFFE91E8C)..style = PaintingStyle.fill,
    );
    // Lip highlight
    canvas.drawLine(
      Offset(cx - r * 0.08, cy + r * 0.31),
      Offset(cx + r * 0.08, cy + r * 0.31),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Neutral cartoon ───────────────────────────────────────────────────────────

class _NeutralCartoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Background
    canvas.drawCircle(
      Offset(cx, cy),
      size.width / 2,
      Paint()..color = const Color(0xFFE8F5E9),
    );

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + r * 1.05), width: r * 0.52, height: r * 0.5),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFF5C5A3),
    );

    // Body
    final bodyPath = Path()
      ..moveTo(cx - r * 0.85, size.height)
      ..lineTo(cx - r * 0.85, cy + r * 1.1)
      ..quadraticBezierTo(cx - r * 0.4, cy + r * 0.85, cx, cy + r * 0.9)
      ..quadraticBezierTo(cx + r * 0.4, cy + r * 0.85, cx + r * 0.85, cy + r * 1.1)
      ..lineTo(cx + r * 0.85, size.height)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF10B981));

    _drawFace(
      canvas: canvas,
      size: size,
      skinLight: const Color(0xFFF9D5B0),
      skinDark: const Color(0xFFF0B882),
      skinShadow: const Color(0xFFD4956A),
    );

    // Simple hair
    final hairPath = Path()
      ..moveTo(cx - r * 0.95, cy - r * 0.05)
      ..quadraticBezierTo(cx - r * 0.9, cy - r * 1.05, cx, cy - r * 1.08)
      ..quadraticBezierTo(cx + r * 0.9, cy - r * 1.05, cx + r * 0.95, cy - r * 0.05)
      ..quadraticBezierTo(cx + r * 0.8, cy - r * 0.5, cx, cy - r * 0.55)
      ..quadraticBezierTo(cx - r * 0.8, cy - r * 0.5, cx - r * 0.95, cy - r * 0.05)
      ..close();
    canvas.drawPath(hairPath, Paint()..color = const Color(0xFF5C4033));

    // Ears
    final earPaint = Paint()..color = const Color(0xFFF9D5B0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r * 0.97, cy + r * 0.05), width: r * 0.21, height: r * 0.31),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r * 0.97, cy + r * 0.05), width: r * 0.21, height: r * 0.31),
      earPaint,
    );

    // Eyebrows
    final browPaint = Paint()
      ..color = const Color(0xFF5C4033)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final side in [-1.0, 1.0]) {
      final bx = cx + side * r * 0.38;
      final by = cy - r * 0.29;
      final browPath = Path()
        ..moveTo(bx - r * 0.13, by + r * 0.02)
        ..quadraticBezierTo(bx, by - r * 0.04, bx + r * 0.13, by + r * 0.02);
      canvas.drawPath(browPath, browPaint);
    }

    _drawEyes(
      canvas: canvas,
      size: size,
      eyeWhite: Colors.white,
      iris: const Color(0xFF5B3A29),
      pupil: const Color(0xFF1A0A00),
    );
    _drawNose(canvas: canvas, size: size, color: const Color(0xFFD4956A));
    _drawSmile(canvas: canvas, size: size, color: const Color(0xFFB05A3A), width: 0.34);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
