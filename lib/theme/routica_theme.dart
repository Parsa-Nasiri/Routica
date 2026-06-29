import 'package:flutter/material.dart';

/// Centralized design tokens for consistent Material language.
///
/// The palette is intentionally limited to **3 accent colours** so the
/// app feels cohesive rather than a rainbow:
///
///   • [primary]   — electric blue   (brand identity, main CTAs)
///   • [secondary]  — purple          (secondary actions, gradients)
///   • [accent]     — teal             (highlights, active states)
///
/// Every screen and widget should reference these tokens instead of
/// hardcoding hex values.
abstract class RouticaTheme {
  // ── Core surfaces ──────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFF0C1421);
  static const Color surface = Color(0xFF1A2332);
  static const Color surfaceVariant = Color(0xFF0F1419);
  static const Color appBar = Color(0xFF0B1220);

  // ── Brand colours (the only 3 accents used across the app) ────
  static const Color primary = Color(0xFF2B2EEE);   // electric blue
  static const Color secondary = Color(0xFF8B5CF6);  // purple
  static const Color accent = Color(0xFF2DD4BF);    // teal

  // ── Text ──────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFE2E8F0);
  static const Color onSurfaceVariant = Color(0xFF9AA3B2);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9AA3B2);
  static const Color textDisabled = Color(0xFF6B7280);

  // ── Semantic colours (derived from the 3 accents) ─────────────
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
  static const double radiusCard = 16;
  static const double radiusDialog = 20;
  static const double radiusPill = 999;
  static const double radiusButton = 12;
  static const double radiusLarge = 24;

  // ── Animation durations ──────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
  static const Duration animStagger = Duration(milliseconds: 50);

  // ── Reusable gradients ────────────────────────────────────────

  /// Brand gradient used on hero sections and progress indicators.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, primary],
  );

  /// Subtle surface gradient for cards that need extra depth.
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A2332), Color(0xFF141C2B)],
  );

  /// Builds a tinted icon-container background for the given accent.
  static Color iconBg(Color accent) => accent.withValues(alpha: 0.15);

  // ── Habit category accent colours ─────────────────────────────
  // Mapped to the 3-brand palette to keep the app cohesive.
  static const Map<String, Color> categoryColors = {
    'General': secondary,
    'Health': danger,
    'Fitness': warning,
    'Productivity': primary,
    'Mindfulness': accent,
    'Learning': secondary,
    'Social': Color(0xFFEC4899),
    'Creativity': Color(0xFFC084FC),
  };

  /// Returns the accent colour for a habit category, falling back to
  /// [secondary] for unknown categories.
  static Color colorForCategory(String category) {
    return categoryColors[category] ?? secondary;
  }
}
