import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/models.dart';

class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({super.key});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  List<Story> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyStories();
  }

  Future<void> _fetchMyStories() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<dynamic>(ApiEndpoints.myStories);
      final list = data is List
          ? data
          : (data is Map ? (data['data'] as List? ?? []) : []);
      setState(() {
        _stories = list.map((e) => Story.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteStory(Story story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.studioDeleteStoryTitle),
        content: Text(AppStrings.studioDeleteStoryConfirm(story.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.delete(ApiEndpoints.deleteStory(story.id));
      setState(() => _stories.removeWhere((s) => s.id == story.id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.studioDeleteStorySuccess(story.title))));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    }
  }

  void _showCreateStorySheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'NOVEL';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(AppStrings.studioCreateStoryTitle, style: AppTypography.heading3(Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              const SizedBox(height: 20),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: AppStrings.storyNameLabel, prefixIcon: Icon(Icons.title_rounded))),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: AppStrings.descriptionLabel, prefixIcon: Icon(Icons.description_outlined))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(AppStrings.storyTypeLabel, style: AppTypography.labelLarge(context.appTheme.textSecondary)),
                  const SizedBox(width: 12),
                  ChoiceChip(label: const Text(AppStrings.storyTypeNovel), selected: type == 'NOVEL', onSelected: (_) => setSheetState(() => type = 'NOVEL')),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text(AppStrings.storyTypeManga), selected: type == 'MANGA', onSelected: (_) => setSheetState(() => type = 'MANGA')),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    try {
                      final api = ref.read(apiClientProvider);
                      await api.post(ApiEndpoints.createStory, data: {
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'type': type,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchMyStories();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.studioCreateStorySuccess)));
                    } on ApiException catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.studioCreateStoryButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddChapterSheet(Story story) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    bool isPremium = false;
    final priceCtrl = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(AppStrings.studioAddChapterTitle, style: AppTypography.heading3(Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              Text(story.title, style: AppTypography.bodyMedium(context.appTheme.textMuted)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: AppStrings.chapterTitleLabel)),
              const SizedBox(height: 12),
              TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: AppStrings.chapterContentLabel, alignLabelWithHint: true)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text(AppStrings.chapterPremiumLabel),
                value: isPremium,
                onChanged: (v) => setSheetState(() => isPremium = v),
                activeThumbColor: AppColors.emerald500,
                contentPadding: EdgeInsets.zero,
              ),
              if (isPremium)
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: AppStrings.chapterPriceLabel)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                    try {
                      final api = ref.read(apiClientProvider);
                      await api.post(ApiEndpoints.createChapter(story.id), data: {
                        'title': titleCtrl.text.trim(),
                        'content': contentCtrl.text,
                        'isPremium': isPremium,
                        if (isPremium) 'price': int.tryParse(priceCtrl.text) ?? 0,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchMyStories();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.studioAddChapterSuccess)));
                    } on ApiException catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  child: const Text(AppStrings.studioPublishChapterButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStorySheet(Story story) {
    final titleCtrl = TextEditingController(text: story.title);
    final descCtrl = TextEditingController(text: story.description ?? '');
    String status = story.status ?? 'ONGOING';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(AppStrings.studioEditStoryTitle, style: AppTypography.heading3(Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              const SizedBox(height: 20),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: AppStrings.storyNameLabel, prefixIcon: Icon(Icons.title_rounded))),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: AppStrings.descriptionLabel, prefixIcon: Icon(Icons.description_outlined))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(AppStrings.storyStatusLabel, style: AppTypography.labelLarge(context.appTheme.textSecondary)),
                  const SizedBox(width: 12),
                  ChoiceChip(label: const Text(AppStrings.storyStatusOngoing), selected: status == 'ONGOING', onSelected: (_) => setSheetState(() => status = 'ONGOING')),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text(AppStrings.storyStatusCompleted), selected: status == 'COMPLETED', onSelected: (_) => setSheetState(() => status = 'COMPLETED')),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    try {
                      final api = ref.read(apiClientProvider);
                      await api.put(ApiEndpoints.updateStory(story.id), data: {
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'status': status,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchMyStories();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.studioUpdateStorySuccess)));
                    } on ApiException catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(AppStrings.saveChangesButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.emerald500, size: 24),
            const SizedBox(width: 8),
            Text(AppStrings.studioTitle, style: AppTypography.heading3(textColor)),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateStorySheet,
        backgroundColor: AppColors.emerald500,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.studioCreateStoryButton),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 64, color: ext.textMuted.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(AppStrings.studioEmptyMessage, style: AppTypography.bodyMedium(ext.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchMyStories,
                  color: AppColors.emerald500,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _stories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final story = _stories[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
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
                                imageUrl: story.coverImage ?? AppConstants.defaultCoverImage,
                                width: 55,
                                height: 75,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(story.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge(textColor)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(AppStrings.studioChapterCount(story.chapterCount ?? 0), style: AppTypography.bodySmall(ext.textMuted)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: story.status == 'COMPLETED'
                                              ? AppColors.emerald500.withValues(alpha: 0.1)
                                              : AppColors.amber500.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          story.status == 'COMPLETED' ? AppStrings.storyStatusCompletedShort : AppStrings.storyStatusOngoing,
                                          style: AppTypography.labelSmall(
                                            story.status == 'COMPLETED' ? AppColors.emerald500 : AppColors.amber500,
                                          ).copyWith(fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.visibility_outlined, size: 12, color: AppColors.emerald500),
                                      const SizedBox(width: 3),
                                      Text(formatCompactNumber(story.viewCount ?? 0), style: AppTypography.bodySmall(ext.textMuted)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Action buttons
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.info),
                                  tooltip: AppStrings.studioEditStoryTooltip,
                                  onPressed: () => _showEditStorySheet(story),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppColors.emerald500),
                                  tooltip: AppStrings.studioAddChapterTooltip,
                                  onPressed: () => _showAddChapterSheet(story),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error.withValues(alpha: 0.6)),
                                  tooltip: AppStrings.studioDeleteStoryTooltip,
                                  onPressed: () => _deleteStory(story),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
