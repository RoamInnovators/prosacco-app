import 'package:flutter/material.dart';

/// Tokens aligned with `prosacco design/` (login, home_dashboard) and docs/member.md.
abstract final class ProsaccoColors {
  static const Color primary = Color(0xFF005127);
  static const Color primaryContainer = Color(0xFF1B6B3A);
  static const Color secondary = Color(0xFF006D3D);
  static const Color tertiary = Color(0xFF005213);
  static const Color tertiaryFixed = Color(0xFF94F990);
  static const Color secondaryContainer = Color(0xFF97F3B5);
  static const Color onSecondaryContainer = Color(0xFF047240);
  static const Color surface = Color(0xFFF8F9FB);
  static const Color surfaceBright = Color(0xFFF8F9FB);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF404940);
  static const Color onPrimaryContainer = Color(0xFF9AE9AB);
  static const Color primaryFixed = Color(0xFFA5F4B6);
  static const Color onPrimaryFixed = Color(0xFF00210C);
  static const Color outline = Color(0xFF707A6F);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  /// Headline green (tailwind emerald-900) — dashboard card titles in `home_dashboard` mock.
  static const Color headlineGreen = Color(0xFF064E3B);
  static const Color slateMuted = Color(0xFF64748B);
  /// Credits / positive movement (statement viewer design).
  static const Color success = Color(0xFF15803D);
}
