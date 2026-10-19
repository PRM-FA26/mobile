import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/models.dart';

class ExploreStoryCard extends StatelessWidget {
  final Story story;

  const ExploreStoryCard({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.storyDetail(story.id)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          story.coverImage ?? AppConstants.defaultCoverImage,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: ext.surfaceElevated),
                      errorWidget: (_, _, _) => Container(
                        color: ext.surfaceElevated,
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 40,
                          color: ext.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    if (story.status != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _ExploreStatusBadge(status: story.status!),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge(
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ).copyWith(fontSize: 13),
                    ),
                    Row(
                      children: [
                        if (story.rating != null) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.amber500,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            story.rating!.toStringAsFixed(1),
                            style: AppTypography.labelSmall(ext.textMuted),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (story.viewCount != null) ...[
                          Icon(
                            Icons.visibility_outlined,
                            size: 12,
                            color: ext.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            formatCompactNumber(story.viewCount!),
                            style: AppTypography.labelSmall(ext.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreStatusBadge extends StatelessWidget {
  final String status;

  const _ExploreStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'COMPLETED' => AppStrings.storyStatusCompleted,
      'HIATUS' => AppStrings.storyStatusHiatus,
      'DROPPED' => AppStrings.storyStatusDropped,
      _ => AppStrings.storyStatusOngoing,
    };
    final color = switch (status) {
      'COMPLETED' => AppColors.emerald500,
      'HIATUS' => AppColors.info,
      'DROPPED' => AppColors.error,
      _ => AppColors.amber500,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall(Colors.white).copyWith(fontSize: 9),
      ),
    );
  }
}
