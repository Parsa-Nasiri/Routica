import 'package:flutter/material.dart';

/// Centralized design tokens for consistent Material language.
///
/// Every screen and widget should reference these tokens instead of
/// hardcoding hex values.  This ensures a single source of truth for
/// the app's visual identity and makes dark/light theme swaps trivial.
abstract class RouticaTheme {
  // ── Core surfaces ──────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFF0C1421);
  static const Color surface = Color(0xFF1A2332);
  static const Color surfaceVariant = Color(0xFF0F1419);
  static const Color appBar = Color(0xFF0B1220);

  // ── Brand colours ─────────────────────────────────────────────
  static const Color primary = Color(0xFF2B2EEE);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF2DD4BF);

  // ── Text ──────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFE2E8F0);
  static const Color onSurfaceVariant = Color(0xFF9AA3B2);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9AA3B2);
  static const Color textDisabled = Color(0xFF6B7280);

  // ── Semantic colours ──────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);

  // ── Borders & dividers ────────────────────────────────────────
  static const Color border = Color(0x14FFFFFF);
  static const Color borderStrong = Color(0xFF273244);
  static const Color divider = Color(0xFF273244);

  // ── Radii ─────────────────────────────────────────────────────
  static const double radiusCard = 12;
  static const double radiusDialog = 16;
  static const double radiusPill = 999;
  static const double radiusButton = 12;
  static const double radiusLarge = 20;

  // ── Habit category accent colours (used in chips, filters) ──
  static const Map<String, Color> categoryColors = {
    'General': Color(0xFF8B5CF6),
    'Health': Color(0xFFEF4444),
    'Fitness': Color(0xFFF59E0B),
    'Productivity': Color(0xFF3B82F6),
    'Mindfulness': Color(0xFF10B981),
    'Learning': Color(0xFF8B5CF6),
    'Social': Color(0xFFEC4899),
    'Creativity': Color(0xFFC084FC),
  };

  /// Returns the accent colour for a habit category, falling back to
  /// [secondary] for unknown categories.
  static Color colorForCategory(String category) {
    return categoryColors[category] ?? secondary;
  }
}
