import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum ReaderTheme { light, dark, sepia }

/// Resolved color set for a given [ReaderTheme].
class ReaderColors {
  final Color bg;
  final Color text;
  final Color bar;
  final Color border;
  final Color accent;

  const ReaderColors({
    required this.bg,
    required this.text,
    required this.bar,
    required this.border,
    required this.accent,
  });

  static ReaderColors of(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.dark:
        return const ReaderColors(
          bg: AppColors.readerDarkBg,
          text: AppColors.readerDarkText,
          bar: AppColors.readerDarkBar,
          border: AppColors.readerDarkBorder,
          accent: AppColors.readerDarkAccent,
        );
      case ReaderTheme.sepia:
        return const ReaderColors(
          bg: AppColors.readerSepiaBg,
          text: AppColors.readerSepiaText,
          bar: AppColors.readerSepiaBar,
          border: AppColors.readerSepiaBorder,
          accent: AppColors.readerSepiaAccent,
        );
      case ReaderTheme.light:
        return const ReaderColors(
          bg: AppColors.readerLightBg,
          text: AppColors.readerLightText,
          bar: AppColors.readerLightBar,
          border: AppColors.readerLightBorder,
          accent: AppColors.readerLightAccent,
        );
    }
  }
}
