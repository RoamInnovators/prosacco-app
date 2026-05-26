import 'package:flutter/material.dart';

import 'prosacco_colors.dart';

/// Themed tokens for light/dark. Light matches [ProsaccoColors] and docs/member.md;
/// dark aligns with `prosacco design/profile_security` (slate base + #97F3B5 accents).
@immutable
class ProsaccoPalette extends ThemeExtension<ProsaccoPalette> {
  const ProsaccoPalette({
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.tertiary,
    required this.tertiaryFixed,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.surface,
    required this.surfaceBright,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceContainerLowest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onPrimaryContainer,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.outline,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.headlineGreen,
    required this.slateMuted,
    required this.success,
  });

  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color tertiary;
  final Color tertiaryFixed;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color surface;
  final Color surfaceBright;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceContainerLowest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onPrimaryContainer;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color outline;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color headlineGreen;
  final Color slateMuted;
  final Color success;

  static const ProsaccoPalette light = ProsaccoPalette(
    primary: ProsaccoColors.primary,
    primaryContainer: ProsaccoColors.primaryContainer,
    secondary: ProsaccoColors.secondary,
    tertiary: ProsaccoColors.tertiary,
    tertiaryFixed: ProsaccoColors.tertiaryFixed,
    secondaryContainer: ProsaccoColors.secondaryContainer,
    onSecondaryContainer: ProsaccoColors.onSecondaryContainer,
    surface: ProsaccoColors.surface,
    surfaceBright: ProsaccoColors.surfaceBright,
    surfaceContainerLow: ProsaccoColors.surfaceContainerLow,
    surfaceContainer: ProsaccoColors.surfaceContainer,
    surfaceContainerHigh: ProsaccoColors.surfaceContainerHigh,
    surfaceContainerHighest: ProsaccoColors.surfaceContainerHighest,
    surfaceContainerLowest: ProsaccoColors.surfaceContainerLowest,
    onSurface: ProsaccoColors.onSurface,
    onSurfaceVariant: ProsaccoColors.onSurfaceVariant,
    onPrimaryContainer: ProsaccoColors.onPrimaryContainer,
    primaryFixed: ProsaccoColors.primaryFixed,
    onPrimaryFixed: ProsaccoColors.onPrimaryFixed,
    outline: ProsaccoColors.outline,
    error: ProsaccoColors.error,
    errorContainer: ProsaccoColors.errorContainer,
    onErrorContainer: ProsaccoColors.onErrorContainer,
    headlineGreen: ProsaccoColors.headlineGreen,
    slateMuted: ProsaccoColors.slateMuted,
    success: ProsaccoColors.success,
  );

  /// Dark surfaces: slate-950/900 scale; accents match profile_security `dark:` tokens.
  static const ProsaccoPalette dark = ProsaccoPalette(
    primary: Color(0xFF86EFAC),
    primaryContainer: Color(0xFF166534),
    secondary: Color(0xFF4ADE80),
    tertiary: Color(0xFF94F990),
    tertiaryFixed: Color(0xFF94F990),
    secondaryContainer: Color(0xFF14532D),
    onSecondaryContainer: Color(0xFFBBF7D0),
    surface: Color(0xFF0F172A),
    surfaceBright: Color(0xFF1E293B),
    surfaceContainerLow: Color(0xFF1E293B),
    surfaceContainer: Color(0xFF334155),
    surfaceContainerHigh: Color(0xFF475569),
    surfaceContainerHighest: Color(0xFF64748B),
    surfaceContainerLowest: Color(0xFF1E293B),
    onSurface: Color(0xFFF8FAFC),
    onSurfaceVariant: Color(0xFFCBD5E1),
    onPrimaryContainer: Color(0xFF052E16),
    primaryFixed: Color(0xFFA5F4B6),
    onPrimaryFixed: Color(0xFF00210C),
    outline: Color(0xFF94A3B8),
    error: Color(0xFFF87171),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFECACA),
    headlineGreen: Color(0xFF97F3B5),
    slateMuted: Color(0xFF94A3B8),
    success: Color(0xFF4ADE80),
  );

  @override
  ProsaccoPalette copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? secondary,
    Color? tertiary,
    Color? tertiaryFixed,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? surface,
    Color? surfaceBright,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? surfaceContainerLowest,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? onPrimaryContainer,
    Color? primaryFixed,
    Color? onPrimaryFixed,
    Color? outline,
    Color? error,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? headlineGreen,
    Color? slateMuted,
    Color? success,
  }) {
    return ProsaccoPalette(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      tertiaryFixed: tertiaryFixed ?? this.tertiaryFixed,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      surface: surface ?? this.surface,
      surfaceBright: surfaceBright ?? this.surfaceBright,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      surfaceContainerLowest: surfaceContainerLowest ?? this.surfaceContainerLowest,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
      outline: outline ?? this.outline,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      headlineGreen: headlineGreen ?? this.headlineGreen,
      slateMuted: slateMuted ?? this.slateMuted,
      success: success ?? this.success,
    );
  }

  @override
  ProsaccoPalette lerp(ThemeExtension<ProsaccoPalette>? other, double t) {
    if (other is! ProsaccoPalette) return this;
    return ProsaccoPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryFixed: Color.lerp(tertiaryFixed, other.tertiaryFixed, t)!,
      secondaryContainer:
          Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondaryContainer:
          Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceBright: Color.lerp(surfaceBright, other.surfaceBright, t)!,
      surfaceContainerLow:
          Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest:
          Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      surfaceContainerLowest:
          Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      onPrimaryFixed: Color.lerp(onPrimaryFixed, other.onPrimaryFixed, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      headlineGreen: Color.lerp(headlineGreen, other.headlineGreen, t)!,
      slateMuted: Color.lerp(slateMuted, other.slateMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension ProsaccoPaletteContext on BuildContext {
  ProsaccoPalette get pal {
    final ext = Theme.of(this).extension<ProsaccoPalette>();
    return ext ?? ProsaccoPalette.light;
  }
}
