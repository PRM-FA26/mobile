import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/models.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<HistoryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<dynamic>(ApiEndpoints.readingHistory);
      final list = data is List
          ? data
          : (data is Map ? (data['data'] as List? ?? []) : []);
      setState(() {
        _items = list.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.historyTitle, style: AppTypography.heading3(textColor)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: ext.textMuted.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(AppStrings.historyEmptyTitle, style: AppTypography.bodyMedium(ext.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go(AppRoutes.explore),
                        child: const Text(AppStrings.exploreStories),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  color: AppColors.emerald500,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _HistoryTile(item: _items[i]),
                  ),
                ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final progressPercent = (item.progress * 100).clamp(0, 100).toInt();

    return GestureDetector(
      onTap: () => context.push(AppRoutes.reader(item.story.id, item.chapter.chapterNumber)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.story.coverImage ?? AppConstants.defaultCoverImage,
                width: 55,
                height: 75,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 55, height: 75, color: ext.surfaceElevated),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge(isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chương ${item.chapter.chapterNumber}: ${item.chapter.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(ext.textMuted),
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: item.progress,
                            backgroundColor: ext.surfaceElevated,
                            color: AppColors.emerald500,
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$progressPercent%', style: AppTypography.labelSmall(AppColors.emerald500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(formatRelativeTime(item.readAt), style: AppTypography.bodySmall(ext.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.play_circle_outline_rounded, color: AppColors.emerald500.withValues(alpha: 0.7), size: 28),
          ],
        ),
      ),
    );
  }
}
