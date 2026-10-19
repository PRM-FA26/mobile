import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_client.dart';
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
import 'widgets/story_chapters_list.dart';
import 'widgets/story_comments_tab.dart';
import 'widgets/story_reviews_tab.dart';
import 'widgets/story_stat_pill.dart';

/// Provider to fetch story details by ID.
final _storyDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  return await api.get<Map<String, dynamic>>(ApiEndpoints.storyById(id));
});

/// Provider to fetch chapters of a story.
final _chaptersProvider = FutureProvider.family<List<Chapter>, String>((ref, storyId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<dynamic>(ApiEndpoints.storyChapters(storyId));
  final list = data is List
      ? data
      : (data is Map ? (data['data'] as List? ?? data['chapters'] as List? ?? []) : []);
  return list.map((e) => Chapter.fromJson(e as Map<String, dynamic>)).toList();
});

/// Provider to check bookmark status.
final _bookmarkProvider = FutureProvider.family<bool, String>((ref, storyId) async {
  final isLoggedIn = ref.read(authStateProvider);
  if (!isLoggedIn) return false;
  try {
    final api = ref.read(apiClientProvider);
    final result = await api.get<Map<String, dynamic>>(ApiEndpoints.checkBookmark(storyId));
    return result['isBookmarked'] as bool? ?? false;
  } catch (_) {
    return false;
  }
});

class StoryDetailScreen extends ConsumerStatefulWidget {
  final String storyId;
  const StoryDetailScreen({super.key, required this.storyId});

  @override
  ConsumerState<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends ConsumerState<StoryDetailScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isBookmarked = false;
  bool _bookmarkLoading = false;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    final isLoggedIn = ref.read(authStateProvider);
    if (!isLoggedIn) {
      context.push(AppRoutes.loginWithRedirect(AppRoutes.storyDetail(widget.storyId)));
      return;
    }
    setState(() => _bookmarkLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiEndpoints.toggleBookmark(widget.storyId));
      setState(() => _isBookmarked = !_isBookmarked);
    } catch (_) {
    } finally {
      setState(() => _bookmarkLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final storyAsync = ref.watch(_storyDetailProvider(widget.storyId));
    final chaptersAsync = ref.watch(_chaptersProvider(widget.storyId));
    final bookmarkAsync = ref.watch(_bookmarkProvider(widget.storyId));

    bookmarkAsync.whenData((v) {
      if (!_bookmarkLoading) _isBookmarked = v;
    });

    return storyAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text(AppStrings.storyLoadError(e)))),
      data: (data) {
        final story = Story.fromJson(data);
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (_, _) => [
              _buildSliverAppBar(story, isDark, ext),
              _buildInfoSection(story, isDark, ext),
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabCtrl,
                  tabs: const [
                    Tab(text: AppStrings.tabChapters),
                    Tab(text: AppStrings.tabComments),
                    Tab(text: AppStrings.tabReviews),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                StoryChaptersList(storyId: widget.storyId, chaptersAsync: chaptersAsync),
                StoryCommentsTab(storyId: widget.storyId, tabController: _tabCtrl),
                StoryReviewsTab(storyId: widget.storyId),
              ],
            ),
          ),
          // ── Read / Continue FAB ─────────────────────────────
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                // Bookmark
                _bookmarkLoading
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        onPressed: _toggleBookmark,
                        style: IconButton.styleFrom(
                          backgroundColor: ext.surfaceElevated,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(
                          _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: _isBookmarked ? AppColors.emerald500 : ext.textMuted,
                        ),
                      ),
                const SizedBox(width: 12),
                // Donate
                IconButton(
                  onPressed: () => _showDonateSheet(context, story),
                  style: IconButton.styleFrom(
                    backgroundColor: ext.surfaceElevated,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(Icons.favorite_border_rounded, color: AppColors.error.withValues(alpha: 0.8)),
                ),
                const SizedBox(width: 12),
                // Read button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.reader(widget.storyId, 1)),
                      icon: const Icon(Icons.menu_book_rounded, size: 20),
                      label: const Text(AppStrings.readStoryButton),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(Story story, bool isDark, AppThemeExtension ext) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(imageUrl: story.coverImage ?? AppConstants.defaultCoverImage, fit: BoxFit.cover),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    (isDark ? AppColors.darkBg : AppColors.lightBg).withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
            // Story info overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Cover thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: story.coverImage ?? AppConstants.defaultCoverImage,
                      width: 90,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading2(
                            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (story.author != null)
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.userProfile(story.author!.id)),
                            child: Text(
                              story.author!.name,
                              style: AppTypography.bodyMedium(AppColors.emerald500),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildInfoSection(Story story, bool isDark, AppThemeExtension ext) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                StoryStatPill(Icons.star_rounded, story.rating?.toStringAsFixed(1) ?? '-', AppColors.amber500),
                const SizedBox(width: 8),
                StoryStatPill(Icons.visibility_outlined, formatCompactNumber(story.viewCount ?? 0), ext.textMuted),
                const SizedBox(width: 8),
                StoryStatPill(
                  Icons.menu_book_rounded,
                  AppStrings.storyChapterCountSuffix(story.chapterCount ?? 0),
                  ext.textMuted,
                ),
                const SizedBox(width: 8),
                if (story.status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: story.status == 'COMPLETED'
                          ? AppColors.emerald500.withValues(alpha: 0.1)
                          : AppColors.amber500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      story.status == 'COMPLETED' ? AppStrings.storyStatusCompleted : AppStrings.storyStatusOngoing,
                      style: AppTypography.labelSmall(
                        story.status == 'COMPLETED' ? AppColors.emerald500 : AppColors.amber500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Genres
            if (story.genres != null && story.genres!.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: story.genres!
                    .map(
                      (g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ext.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(g.name, style: AppTypography.labelSmall(ext.textSecondary)),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 16),

            // Description
            if (story.description != null && story.description!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() => _descExpanded = !_descExpanded),
                child: AnimatedCrossFade(
                  firstChild: Text(
                    story.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(ext.textSecondary),
                  ),
                  secondChild: Text(story.description!, style: AppTypography.bodyMedium(ext.textSecondary)),
                  crossFadeState: _descExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _descExpanded = !_descExpanded),
                child: Text(_descExpanded ? AppStrings.collapseLabel : AppStrings.expandMoreLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDonateSheet(BuildContext context, Story story) {
    if (story.author == null) return;
    final isLoggedIn = ref.read(authStateProvider);
    if (!isLoggedIn) {
      context.push(AppRoutes.loginWithRedirect(AppRoutes.storyDetail(story.id)));
      return;
    }

    final amountCtrl = TextEditingController(text: '100');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.donateToAuthor(story.author!.name),
              style: AppTypography.heading3(
                Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Quick amounts
            Wrap(
              spacing: 8,
              children: [50, 100, 500, 1000]
                  .map(
                    (amt) => ActionChip(
                      label: Text(AppStrings.donateAmountSuffix(amt)),
                      onPressed: () => amountCtrl.text = amt.toString(),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: AppStrings.donateAmountLabel,
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = int.tryParse(amountCtrl.text) ?? 0;
                  if (amount <= 0) return;
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final api = ref.read(apiClientProvider);
                    await api.post(
                      ApiEndpoints.donate,
                      data: {'toUserId': story.author!.id, 'storyId': story.id, 'amount': amount},
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      messenger.showSnackBar(SnackBar(content: Text(AppStrings.donateSuccessMessage(amount))));
                    }
                  } on ApiException catch (e) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: const Text(AppStrings.donateSubmitButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
