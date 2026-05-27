import 'package:flutter/material.dart';

/// Deterministic gradient colors per account product type.
class AccountCardPalette {
  const AccountCardPalette({
    required this.start,
    required this.end,
    required this.accent,
  });

  final Color start;
  final Color end;
  final Color accent;

  static AccountCardPalette forAccountType(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'BOSA':
      case 'SAVINGS':
        return const AccountCardPalette(
          start: Color(0xFF005127),
          end: Color(0xFF1B7A4A),
          accent: Color(0xFF97F3B5),
        );
      case 'FOSA':
        return const AccountCardPalette(
          start: Color(0xFF1D4ED8),
          end: Color(0xFF3B82F6),
          accent: Color(0xFFDBEAFE),
        );
      case 'SHARES':
      case 'SHARE_CAPITAL':
        return const AccountCardPalette(
          start: Color(0xFF6D28D9),
          end: Color(0xFF8B5CF6),
          accent: Color(0xFFEDE9FE),
        );
      case 'FD':
      case 'FIXED_DEPOSIT':
        return const AccountCardPalette(
          start: Color(0xFFB45309),
          end: Color(0xFFF59E0B),
          accent: Color(0xFFFEF3C7),
        );
      case 'SS':
      case 'SPECIAL_SAVINGS':
        return const AccountCardPalette(
          start: Color(0xFF0F766E),
          end: Color(0xFF14B8A6),
          accent: Color(0xFFCCFBF1),
        );
      default:
        return const AccountCardPalette(
          start: Color(0xFF334155),
          end: Color(0xFF64748B),
          accent: Color(0xFFE2E8F0),
        );
    }
  }
}
