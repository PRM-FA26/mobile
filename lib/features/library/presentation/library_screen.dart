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

/// Normalizes heterogeneous bookmark data formats from the backend.
/// Mirrors `normalizeStories()` from `fe-web-novel/src/app/library/page.tsx`.
Story _normalizeBookmark(Map<String, dynamic> raw) {
  // Backend may wrap story data in 'story' key
  final storyData = raw.containsKey('story')
      ? raw['story'] as Map<String, dynamic>
      : raw;
  return Story.fromJson(storyData);
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<Story> _bookmarks = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<dynamic>(ApiEndpoints.bookmarks);
      final list = data is List
          ? data
          : (data is Map ? (data['data'] as List? ?? []) : []);
      setState(() {
        _bookmarks = list.map((e) => _normalizeBookmark(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = AppStrings.libraryLoadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _removeBookmark(Story story) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiEndpoints.toggleBookmark(story.id));
      setState(() => _bookmarks.removeWhere((s) => s.id == story.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.libraryBookmarkRemoved(story.title))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.bookmarkRemoveFailed)),
        );
      }
      // The Dismissible already animated the row away; resync from the
      // server so the list reflects reality after a failed removal.
      _fetchBookmarks();
    }
  }

  List<Story> get _filtered {
    if (_searchQuery.isEmpty) return _bookmarks;
    final q = removeAccents(_searchQuery.toLowerCase());
    return _bookmarks.where((s) {
      return removeAccents(s.title.toLowerCase()).contains(q) ||
          (s.author?.name != null && removeAccents(s.author!.name.toLowerCase()).contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.libraryTitle, style: AppTypography.heading3(textColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchBookmarks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: AppStrings.librarySearchHint,
                prefixIcon: Icon(Icons.search_rounded, color: ext.textMuted, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(AppStrings.libraryStoryCount(filtered.length), style: AppTypography.labelLarge(ext.textMuted)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 64, color: ext.textMuted.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(_error!, style: AppTypography.bodyMedium(ext.textMuted)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _fetchBookmarks, child: const Text(AppStrings.retry)),
                          ],
                        ),
                      )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_border_rounded, size: 64, color: ext.textMuted.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? AppStrings.libraryEmptyTitle : AppStrings.libraryEmptySearchTitle,
                              style: AppTypography.bodyMedium(ext.textMuted),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go(AppRoutes.explore),
                                child: const Text(AppStrings.exploreStories),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchBookmarks,
                        color: AppColors.emerald500,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final story = filtered[i];
                            return Dismissible(
                              key: ValueKey(story.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) => _removeBookmark(story),
                              child: _BookmarkTile(story: story),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final Story story;
  const _BookmarkTile({required this.story});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.storyDetail(story.id)),
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
                imageUrl: story.coverImage ?? AppConstants.defaultCoverImage,
                width: 60,
                height: 85,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 60, height: 85, color: ext.surfaceElevated),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge(isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                  const SizedBox(height: 4),
                  if (story.author != null)
                    Text(story.author!.name, style: AppTypography.bodySmall(ext.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (story.rating != null) ...[
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.amber500),
                        const SizedBox(width: 2),
                        Text(story.rating!.toStringAsFixed(1), style: AppTypography.labelSmall(ext.textMuted)),
                        const SizedBox(width: 10),
                      ],
                      Icon(Icons.menu_book_rounded, size: 13, color: ext.textMuted),
                      const SizedBox(width: 3),
                      Text('${story.chapterCount ?? 0}', style: AppTypography.labelSmall(ext.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
