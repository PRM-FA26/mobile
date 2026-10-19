import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChapterOne text styles using Google Fonts.
///
/// Heading: Playfair Display (serif, editorial feel).
/// Body:    Inter (clean, readable sans-serif).
class AppTypography {
  AppTypography._();

  static String? _headingFamily;
  static String? _bodyFamily;

  /// Lazily init font families (avoids issues in tests).
  static String get headingFamily =>
      _headingFamily ??= GoogleFonts.playfairDisplay().fontFamily!;

  static String get bodyFamily =>
      _bodyFamily ??= GoogleFonts.inter().fontFamily!;

  // ── Heading Styles ─────────────────────────────────────────
  static TextStyle heading1(Color color) => TextStyle(
        fontFamily: headingFamily,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: color,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle heading2(Color color) => TextStyle(
        fontFamily: headingFamily,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle heading3(Color color) => TextStyle(
        fontFamily: headingFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      );

  // ── Body Styles ────────────────────────────────────────────
  static TextStyle bodyLarge(Color color) => TextStyle(
        fontFamily: bodyFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontFamily: bodyFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodySmall(Color color) => TextStyle(
        fontFamily: bodyFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  // ── Label / Button Styles ──────────────────────────────────
  static TextStyle labelLarge(Color color) => TextStyle(
        fontFamily: bodyFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.4,
        letterSpacing: 0.3,
      );

  static TextStyle labelSmall(Color color) => TextStyle(
        fontFamily: bodyFamily,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.3,
        letterSpacing: 0.6,
      );

  static TextStyle button(Color color) => TextStyle(
        fontFamily: bodyFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.4,
      );

  // ── Chapter Reader (uses bodyFamily) ───────────────────────
  static TextStyle readerBody(Color color, double fontSize) => TextStyle(
        fontFamily: bodyFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.8,
        letterSpacing: 0.2,
      );
}
