import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A single theme-swatch circle in the reader's bottom control bar.
class ReaderThemeCircle extends StatelessWidget {
  final Color color;
  final bool selected;
  final Color borderColor;
  final VoidCallback onTap;

  const ReaderThemeCircle({
    super.key,
    required this.color,
    required this.selected,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.emerald500 : borderColor,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.emerald500.withValues(alpha: 0.3), blurRadius: 8)]
              : null,
        ),
      ),
    );
  }
}
