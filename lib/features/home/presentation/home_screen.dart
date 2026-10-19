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
import '../../../shared/models/models.dart';

// ── Providers ──────────────────────────────────────────────────
final _trendingProvider = FutureProvider<List<Story>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>(
    ApiEndpoints.stories,
    queryParameters: {'sortBy': 'viewCount', 'sortOrder': 'desc', 'limit': 6},
  );
  return (data['data'] as List? ?? []).map((e) => Story.fromJson(e as Map<String, dynamic>)).toList();
});

final _newReleasesProvider = FutureProvider<List<Story>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>(
    ApiEndpoints.stories,
    queryParameters: {'sortBy': 'createdAt', 'sortOrder': 'desc', 'limit': 6},
  );
  return (data['data'] as List? ?? []).map((e) => Story.fromJson(e as Map<String, dynamic>)).toList();
});

final _topRatedProvider = FutureProvider<List<Story>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>(
    ApiEndpoints.stories,
    queryParameters: {'sortBy': 'rating', 'sortOrder': 'desc', 'limit': 6},
  );
  return (data['data'] as List? ?? []).map((e) => Story.fromJson(e as Map<String, dynamic>)).toList();
});

final _historyProvider = FutureProvider<List<HistoryItem>>((ref) async {
  final isLoggedIn = ref.read(authStateProvider);
  if (!isLoggedIn) return [];
  try {
    final api = ref.read(apiClientProvider);
    final data = await api.get<dynamic>(ApiEndpoints.readingHistory);
    final list = data is List ? data : (data is Map ? (data['data'] as List? ?? []) : []);
    return list.take(5).map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final trending = ref.watch(_trendingProvider);
    final newReleases = ref.watch(_newReleasesProvider);
    final topRated = ref.watch(_topRatedProvider);
    final history = ref.watch(_historyProvider);
    final isLoggedIn = ref.watch(authStateProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_trendingProvider);
          ref.invalidate(_newReleasesProvider);
          ref.invalidate(_topRatedProvider);
          ref.invalidate(_historyProvider);
        },
        color: AppColors.emerald500,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.emerald500, AppColors.emerald600],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: AppColors.emerald500.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      AppStrings.appDisplayName,
                      style: AppTypography.heading3(textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push(AppRoutes.explore),
                  icon: Icon(Icons.search_rounded, color: mutedColor),
                ),
                if (isLoggedIn && user != null)
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.emerald500.withValues(alpha: 0.15),
                        backgroundImage: user.avatar != null ? CachedNetworkImageProvider(user.avatar!) : null,
                        child: user.avatar == null
                            ? Text((user.displayName ?? user.username)[0].toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.emerald500))
                            : null,
                      ),
                    ),
                  ),
              ],
            ),

            // ── Content ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // Welcome
                  Text.rich(
                    TextSpan(
                      text: isLoggedIn ? AppStrings.homeGreetingLoggedIn : AppStrings.homeGreetingGuest,
                      style: AppTypography.heading1(textColor).copyWith(fontSize: 26),
                      children: [
                        TextSpan(
                          text: isLoggedIn
                              ? (user?.displayName ?? user?.username ?? AppStrings.homeGreetingFallbackName)
                              : AppStrings.appDisplayName,
                          style: AppTypography.heading1(AppColors.emerald500).copyWith(fontSize: 26),
                        ),
                        TextSpan(text: isLoggedIn ? ' 👋' : ' 📖'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(AppStrings.homeSubtitle, style: AppTypography.bodyMedium(mutedColor)),
                  const SizedBox(height: 20),

                  // Quick Actions
                  _QuickActionGrid(isDark: isDark),
                  const SizedBox(height: 28),

                  // Continue Reading
                  if (isLoggedIn) ...[
                    history.when(
                      data: (items) {
                        if (items.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(AppStrings.continueReadingPrefix, AppStrings.continueReadingSuffix, textColor),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (_, i) => _ContinueReadingCard(item: items[i], isDark: isDark),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],

                  // Trending
                  _SectionHeader(AppStrings.trendingPrefix, AppStrings.trendingSuffix, textColor),
                  const SizedBox(height: 12),
                  _StorySection(asyncStories: trending, isDark: isDark),
                  const SizedBox(height: 28),

                  // New Releases
                  _SectionHeader(AppStrings.newReleasesPrefix, AppStrings.newReleasesSuffix, textColor),
                  const SizedBox(height: 12),
                  _StorySection(asyncStories: newReleases, isDark: isDark),
                  const SizedBox(height: 28),

                  // Top Rated
                  _SectionHeader(AppStrings.topRatedPrefix, AppStrings.topRatedSuffix, textColor),
                  const SizedBox(height: 12),
                  _StorySection(asyncStories: topRated, isDark: isDark),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String prefix;
  final String highlight;
  final Color textColor;
  const _SectionHeader(this.prefix, this.highlight, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(
      text: '$prefix ',
      style: AppTypography.heading2(textColor),
      children: [TextSpan(text: highlight, style: AppTypography.heading2(AppColors.emerald500))],
    ));
  }
}

class _QuickActionGrid extends StatelessWidget {
  final bool isDark;
  const _QuickActionGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (AppStrings.quickActionExplore, Icons.explore_rounded, AppRoutes.explore),
      (AppStrings.quickActionRankings, Icons.emoji_events_rounded, AppRoutes.rankings),
      (AppStrings.quickActionHistory, Icons.history_rounded, AppRoutes.history),
      (AppStrings.quickActionWallet, Icons.account_balance_wallet_rounded, AppRoutes.wallet),
    ];
    return Row(
      children: actions.map((a) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => context.push(a.$3),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Icon(a.$2, color: AppColors.emerald500, size: 26),
                  const SizedBox(height: 6),
                  Text(a.$1, style: AppTypography.labelSmall(isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ],
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class _StorySection extends StatelessWidget {
  final AsyncValue<List<Story>> asyncStories;
  final bool isDark;
  const _StorySection({required this.asyncStories, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return asyncStories.when(
      loading: () => SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => _ShimmerCard(isDark: isDark),
        ),
      ),
      error: (_, __) => const SizedBox(height: 50, child: Center(child: Text(AppStrings.loadErrorGeneric))),
      data: (stories) {
        if (stories.isEmpty) return const SizedBox(height: 50, child: Center(child: Text(AppStrings.noStoriesFound)));
        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _HorizontalStoryCard(story: stories[i], isDark: isDark),
          ),
        );
      },
    );
  }
}

class _HorizontalStoryCard extends StatelessWidget {
  final Story story;
  final bool isDark;
  const _HorizontalStoryCard({required this.story, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.storyDetail(story.id)),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: story.coverImage ?? AppConstants.defaultCoverImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(color: ext.surfaceElevated),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(story.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge(isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary).copyWith(fontSize: 12)),
                    Row(
                      children: [
                        if (story.rating != null) ...[
                          const Icon(Icons.star_rounded, size: 11, color: AppColors.amber500),
                          const SizedBox(width: 2),
                          Text(story.rating!.toStringAsFixed(1), style: AppTypography.labelSmall(ext.textMuted).copyWith(fontSize: 10)),
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

class _ContinueReadingCard extends StatelessWidget {
  final HistoryItem item;
  final bool isDark;
  const _ContinueReadingCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final progress = (item.progress * 100).toInt();
    return GestureDetector(
      onTap: () => context.push(AppRoutes.reader(item.story.id, item.chapter.chapterNumber)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.story.coverImage ?? AppConstants.defaultCoverImage,
                width: 55,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.story.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge(isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary).copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Ch. ${item.chapter.chapterNumber}', style: AppTypography.bodySmall(ext.textMuted)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: item.progress, backgroundColor: ext.surfaceElevated, color: AppColors.emerald500, minHeight: 4),
                  ),
                  const SizedBox(height: 4),
                  Text('$progress%', style: AppTypography.labelSmall(AppColors.emerald500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final bool isDark;
  const _ShimmerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
