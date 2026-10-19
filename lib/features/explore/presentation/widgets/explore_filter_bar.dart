import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

class ExploreFilterBar extends StatelessWidget {
  final String genreLabel;
  final String typeLabel;
  final String statusLabel;
  final String sortLabel;
  final bool hasGenre;
  final bool hasType;
  final bool hasStatus;
  final bool hasCustomSort;
  final bool hasActiveFilters;
  final VoidCallback onGenreTap;
  final VoidCallback onTypeTap;
  final VoidCallback onStatusTap;
  final VoidCallback onSortTap;
  final VoidCallback onClearTap;

  const ExploreFilterBar({
    super.key,
    required this.genreLabel,
    required this.typeLabel,
    required this.statusLabel,
    required this.sortLabel,
    required this.hasGenre,
    required this.hasType,
    required this.hasStatus,
    required this.hasCustomSort,
    required this.hasActiveFilters,
    required this.onGenreTap,
    required this.onTypeTap,
    required this.onStatusTap,
    required this.onSortTap,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ExploreFilterButton(
            label: genreLabel,
            icon: Icons.category_rounded,
            hasValue: hasGenre,
            onTap: onGenreTap,
          ),
          const SizedBox(width: 8),
          _ExploreFilterButton(
            label: typeLabel,
            icon: Icons.auto_stories_rounded,
            hasValue: hasType,
            onTap: onTypeTap,
          ),
          const SizedBox(width: 8),
          _ExploreFilterButton(
            label: statusLabel,
            icon: Icons.flag_rounded,
            hasValue: hasStatus,
            onTap: onStatusTap,
          ),
          const SizedBox(width: 8),
          _ExploreFilterButton(
            label: sortLabel,
            icon: Icons.sort_rounded,
            hasValue: hasCustomSort,
            onTap: onSortTap,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            _ClearFilterButton(onTap: onClearTap),
          ],
        ],
      ),
    );
  }
}

class _ExploreFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasValue;
  final VoidCallback onTap;

  const _ExploreFilterButton({
    required this.label,
    required this.icon,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasValue ? AppColors.emerald500 : context.appTheme.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.emerald500.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? AppColors.emerald500
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall(
                  hasValue
                      ? AppColors.emerald500
                      : context.appTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearFilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearFilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
            const SizedBox(width: 4),
            Text(AppStrings.exploreClearFilter, style: AppTypography.labelSmall(AppColors.error)),
          ],
        ),
      ),
    );
  }
}
