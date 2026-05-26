import 'package:flutter/material.dart';

import 'prosacco_palette.dart';

/// Material 3 themes using [ProsaccoPalette] extensions (light + dark).
abstract final class AppTheme {
  static ThemeData light() {
    const p = ProsaccoPalette.light;
    return _base(p, Brightness.light);
  }

  static ThemeData dark() {
    const p = ProsaccoPalette.dark;
    return _base(p, Brightness.dark);
  }

  static ThemeData _base(ProsaccoPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF022C22),
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.secondary,
      onSecondary: Colors.white,
      secondaryContainer: p.secondaryContainer,
      onSecondaryContainer: p.onSecondaryContainer,
      tertiary: p.tertiary,
      onTertiary: Colors.white,
      error: p.error,
      onError: Colors.white,
      errorContainer: p.errorContainer,
      onErrorContainer: p.onErrorContainer,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceVariant,
      outline: p.outline,
      surfaceContainerLowest: p.surfaceContainerLowest,
      surfaceContainerLow: p.surfaceContainerLow,
      surfaceContainer: p.surfaceContainer,
      surfaceContainerHigh: p.surfaceContainerHigh,
      surfaceContainerHighest: p.surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.surface,
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.headlineGreen,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: p.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: p.outline.withValues(alpha: 0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceContainerLow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.primaryContainer,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
