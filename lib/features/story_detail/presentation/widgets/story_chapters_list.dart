import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/models.dart';

/// "Chương" tab of the story detail screen: lists all chapters, showing
/// premium/purchased state, and navigates into the reader on tap.
class StoryChaptersList extends StatelessWidget {
  final String storyId;
  final AsyncValue<List<Chapter>> chaptersAsync;
  const StoryChaptersList({super.key, required this.storyId, required this.chaptersAsync});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return chaptersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (chapters) {
        if (chapters.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book_outlined, size: 48, color: ext.textMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(AppStrings.noChaptersYet, style: AppTypography.bodyMedium(ext.textMuted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: chapters.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final ch = chapters[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: ext.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text('${ch.chapterNumber}', style: AppTypography.labelLarge(ext.textSecondary)),
                ),
              ),
              title: Text(
                ch.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium(
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              subtitle: Row(
                children: [
                  if (ch.wordCount != null)
                    Text(
                      AppStrings.wordCountSuffix(formatCompactNumber(ch.wordCount!)),
                      style: AppTypography.bodySmall(ext.textMuted),
                    ),
                  if (ch.createdAt != null) ...[
                    const SizedBox(width: 8),
                    Text(formatRelativeTime(ch.createdAt!), style: AppTypography.bodySmall(ext.textMuted)),
                  ],
                ],
              ),
              trailing: ch.isPremium
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (ch.isPurchased == true ? AppColors.emerald500 : AppColors.amber500).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ch.isPurchased == true ? Icons.lock_open_rounded : Icons.monetization_on,
                            size: 14,
                            color: ch.isPurchased == true ? AppColors.emerald500 : AppColors.amber500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ch.isPurchased == true ? AppStrings.chapterPurchased : '${ch.price ?? 0}',
                            style: AppTypography.labelSmall(
                              ch.isPurchased == true ? AppColors.emerald500 : AppColors.amber500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () => context.push(AppRoutes.reader(storyId, ch.chapterNumber)),
            );
          },
        );
      },
    );
  }
}
