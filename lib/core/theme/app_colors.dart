import 'package:flutter/material.dart';

/// Color palette for Vatix — modern, professional B2B design based on Material 3
class AppColors {
  // Prevent instantiation
  const AppColors._();

  // ── Brand Colors (Deep Slate Navy B2B Identity) ──────────────────────────
  /// Primary color — Deep Slate Navy
  static const Color primary = Color(0xFF0F2942);

  /// Lighter shade of primary
  static const Color primaryLight = Color(0xFF1E4976);

  /// Darker shade of primary
  static const Color primaryDark = Color(0xFF0A1B2C);

  /// Text and icon color on primary
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Secondary color — Business Teal
  static const Color secondary = Color(0xFF0D9488);
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// Accent highlight color (Accent Sky)
  static const Color accent = Color(0xFF0284C7);

  // ── Backgrounds & Surfaces ────────────────────────────────────────────────
  /// General app background — Slate 50
  static const Color background = Color(0xFFF8FAFC);

  /// Card and dialog surfaces — Pure White
  static const Color surface = Color(0xFFFFFFFF);

  /// Secondary surface (input fields, containers) — Slate 100
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  /// Divider line color
  static const Color divider = Color(0xFFE2E8F0);

  /// Outer border color
  static const Color border = Color(0xFFCBD5E1);

  /// Subtle border color
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // ── Status Colors ─────────────────────────────────────────────────────────
  /// Active / Approved status
  static const Color statusActive = Color(0xFF16A34A);
  static const Color statusActiveBg = Color(0xFFDCFCE7);

  /// Pending review status
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  /// Blocked / Rejected status
  static const Color statusBlocked = Color(0xFFDC2626);
  static const Color statusBlockedBg = Color(0xFFFEE2E2);

  // ── Feedback ──────────────────────────────────────────────────────────────
  /// Error
  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);

  /// Success
  static const Color success = Color(0xFF16A34A);

  /// Warning
  static const Color warning = Color(0xFFD97706);

  // ── Typography ────────────────────────────────────────────────────────────
  /// Primary bold text — Slate 900
  static const Color textPrimary = Color(0xFF0F172A);

  /// Secondary / explanatory text — Slate 500
  static const Color textSecondary = Color(0xFF64748B);

  /// Hint / placeholder text — Slate 400
  static const Color textHint = Color(0xFF94A3B8);

  // ── Shimmer & Shadows ─────────────────────────────────────────────────────
  /// Base shimmer color
  static const Color shimmerBase = Color(0xFFE2E8F0);

  /// Shimmer highlight color
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  /// Subtle ambient card shadow
  static const Color shadowColor = Color(0x0F0F172A);
}
