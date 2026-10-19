import 'package:flutter/material.dart';

/// ChapterOne brand color palette — derived from the web design system.
///
/// Primary: Emerald (`#10b981`)
/// Uses Material 3 color scheme with custom surfaces for
/// both light and dark modes.
class AppColors {
  AppColors._();

  // ── Brand Primary ──────────────────────────────────────────
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);

  // ── Accent ─────────────────────────────────────────────────
  static const Color amber500 = Color(0xFFF59E0B);

  // ── Semantic ───────────────────────────────────────────────
  static const Color error = Color(0xFFF43F5E); // rose-500
  static const Color errorLight = Color(0x1AF43F5E); // rose-500/10
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Light Mode ─────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF334155);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightBorder = Color(0x14000000); // rgba(0,0,0,0.08)

  // ── Dark Mode ──────────────────────────────────────────────
  static const Color darkBg = Color(0xFF020617);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // ── Reader Themes (independent from app theme) ─────────────
  // Light Reader
  static const Color readerLightBg = Color(0xFFF9F7F2);
  static const Color readerLightText = Color(0xFF1A1A1A);
  static const Color readerLightBar = Color(0xD9FFFFFF); // rgba(255,255,255,0.85)
  static const Color readerLightBorder = Color(0x14000000);
  static const Color readerLightAccent = Color(0xFF10B981);

  // Dark Reader
  static const Color readerDarkBg = Color(0xFF0F1117);
  static const Color readerDarkText = Color(0xFFE2E8F0);
  static const Color readerDarkBar = Color(0xD9171923); // rgba(23,25,35,0.85)
  static const Color readerDarkBorder = Color(0x1AFFFFFF);
  static const Color readerDarkAccent = Color(0xFF10B981);

  // Sepia Reader
  static const Color readerSepiaBg = Color(0xFFF1E7D0);
  static const Color readerSepiaText = Color(0xFF433422);
  static const Color readerSepiaBar = Color(0xD9EADDC0); // rgba(234,221,192,0.85)
  static const Color readerSepiaBorder = Color(0x26433422);
  static const Color readerSepiaAccent = Color(0xFF8B4513);

  // ── Notification Icon Colors ───────────────────────────────
  static const Color notifChapter = Color(0xFF3B82F6); // blue
  static const Color notifComment = Color(0xFF6366F1); // indigo
  static const Color notifFollower = Color(0xFF22C55E); // green
  static const Color notifDonation = Color(0xFFF97316); // orange
}
