import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// A small pill showing an icon + value (rating, view count, chapter count...)
/// in the story info section.
class StoryStatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const StoryStatPill(this.icon, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.appTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(value, style: AppTypography.labelSmall(context.appTheme.textSecondary)),
        ],
      ),
    );
  }
}
