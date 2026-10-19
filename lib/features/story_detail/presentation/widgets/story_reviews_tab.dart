import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// "Đánh giá" tab of the story detail screen: star-rating form + review list.
class StoryReviewsTab extends ConsumerStatefulWidget {
  final String storyId;
  const StoryReviewsTab({super.key, required this.storyId});

  @override
  ConsumerState<StoryReviewsTab> createState() => _StoryReviewsTabState();
}

class _StoryReviewsTabState extends ConsumerState<StoryReviewsTab> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  int _newRating = 5;
  final _reviewCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>(ApiEndpoints.reviews(widget.storyId));
      setState(() {
        _reviews = List<Map<String, dynamic>>.from(data['data'] ?? data['reviews'] ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    final isLoggedIn = ref.read(authStateProvider);
    if (!isLoggedIn) {
      context.push(AppRoutes.login);
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        ApiEndpoints.createReview,
        data: {
          'storyId': widget.storyId,
          'rating': _newRating,
          'content': _reviewCtrl.text.trim().isEmpty ? null : _reviewCtrl.text.trim(),
        },
      );
      _reviewCtrl.clear();
      setState(() {
        _newRating = 5;
        _submitting = false;
      });
      _fetchReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.reviewSubmitSuccess)));
      }
    } on ApiException catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      children: [
        // ── Review Form ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.writeReviewTitle, style: AppTypography.labelLarge(textColor)),
              const SizedBox(height: 8),
              // Star selector
              Row(
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _newRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        i < _newRating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 32,
                        color: AppColors.amber500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reviewCtrl,
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: AppStrings.reviewContentHint,
                        filled: true,
                        fillColor: ext.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitReview,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(AppStrings.send),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Reviews List ─────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _reviews.isEmpty
              ? Center(child: Text(AppStrings.noReviewsYet, style: AppTypography.bodyMedium(ext.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (_, i) {
                    final r = _reviews[i];
                    final user = r['user'] as Map<String, dynamic>?;
                    final rating = (r['rating'] as num?)?.toInt() ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ext.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.emerald500.withValues(alpha: 0.15),
                                child: Text(
                                  (user?['username'] as String? ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.emerald500,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  user?['displayName'] ?? user?['username'] ?? AppStrings.defaultUsernameFallback,
                                  style: AppTypography.labelLarge(textColor).copyWith(fontSize: 13),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (j) => Icon(
                                    j < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    size: 16,
                                    color: AppColors.amber500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (r['content'] != null) ...[
                            const SizedBox(height: 8),
                            Text(r['content'] as String, style: AppTypography.bodyMedium(ext.textSecondary)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
