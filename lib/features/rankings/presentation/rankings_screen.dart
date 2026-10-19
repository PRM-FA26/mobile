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

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  final _periods = ['day', 'week', 'month'];
  final _periodLabels = [
    AppStrings.rankingsPeriodDay,
    AppStrings.rankingsPeriodWeek,
    AppStrings.rankingsPeriodMonth,
  ];
  final Map<String, List<Story>> _cache = {};
  String _currentPeriod = 'day';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _currentPeriod = _periods[_tabCtrl.index];
        if (!_cache.containsKey(_currentPeriod)) {
          _fetchRankings(_currentPeriod);
        } else {
          setState(() {});
        }
      }
    });
    _fetchRankings('day');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRankings(String period) async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>(
        ApiEndpoints.stories,
        queryParameters: {
          'sortBy': 'viewCount',
          'sortOrder': 'desc',
          'limit': AppConstants.rankingPageSize,
        },
      );
      final items = (data['data'] as List? ?? [])
          .map((e) => Story.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _cache[period] = items;
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
    final stories = _cache[_currentPeriod] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.amber500, size: 24),
            const SizedBox(width: 8),
            Text(AppStrings.rankingsTitle, style: AppTypography.heading3(textColor)),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _periodLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : stories.isEmpty
              ? Center(child: Text(AppStrings.rankingsNoData, style: AppTypography.bodyMedium(ext.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stories.length,
                  itemBuilder: (_, i) => _RankTile(rank: i + 1, story: stories[i]),
                ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final int rank;
  final Story story;
  const _RankTile({required this.rank, required this.story});

  Color? get _medalColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final isTop3 = rank <= 3;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.storyDetail(story.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTop3 ? (_medalColor ?? Colors.transparent).withValues(alpha: 0.3) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isTop3
              ? [BoxShadow(color: _medalColor!.withValues(alpha: 0.08), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            // Rank number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isTop3 ? _medalColor!.withValues(alpha: 0.15) : ext.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isTop3
                    ? Icon(Icons.emoji_events_rounded, color: _medalColor, size: 22)
                    : Text('$rank', style: AppTypography.labelLarge(ext.textMuted)),
              ),
            ),
            const SizedBox(width: 12),
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: story.coverImage ?? AppConstants.defaultCoverImage,
                width: 45,
                height: 62,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 45, height: 62, color: ext.surfaceElevated),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge(isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                  const SizedBox(height: 2),
                  if (story.author != null)
                    Text(story.author!.name, style: AppTypography.bodySmall(ext.textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 13, color: AppColors.emerald500),
                      const SizedBox(width: 3),
                      Text(formatCompactNumber(story.viewCount ?? 0), style: AppTypography.labelSmall(AppColors.emerald500)),
                      const SizedBox(width: 12),
                      if (story.rating != null) ...[
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.amber500),
                        const SizedBox(width: 2),
                        Text(story.rating!.toStringAsFixed(1), style: AppTypography.labelSmall(ext.textMuted)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
