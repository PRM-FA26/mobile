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

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  ProfileDetails? _profile;
  List<Story> _stories = [];
  bool _loading = true;
  String? _error;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);

      final profile = await api.get<Map<String, dynamic>>(ApiEndpoints.userProfile(widget.userId));

      // Fetch stories
      final storiesData = await api.get<Map<String, dynamic>>(
        ApiEndpoints.stories,
        queryParameters: {'authorId': widget.userId},
      );
      final storyList = (storiesData['data'] as List? ?? [])
          .map((e) => Story.fromJson(e as Map<String, dynamic>))
          .toList();

      // Check follow status
      bool following = false;
      final isLoggedIn = ref.read(authStateProvider);
      if (isLoggedIn) {
        try {
          final check = await api.get<Map<String, dynamic>>(ApiEndpoints.checkFollow(widget.userId));
          following = check['isFollowing'] as bool? ?? false;
        } catch (_) {}
      }

      setState(() {
        _profile = ProfileDetails.fromJson(profile);
        _stories = storyList;
        _isFollowing = following;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = AppStrings.userProfileLoadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final isLoggedIn = ref.read(authStateProvider);
    if (!isLoggedIn) {
      context.push(AppRoutes.loginWithRedirect(AppRoutes.userProfile(widget.userId)));
      return;
    }
    setState(() => _followLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiEndpoints.follow(widget.userId));
      setState(() => _isFollowing = !_isFollowing);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.followActionFailed)),
        );
      }
    }
    finally { setState(() => _followLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: ext.textMuted.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(_error!, style: AppTypography.bodyMedium(ext.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchAll, child: const Text(AppStrings.retry)),
            ],
          ),
        ),
      );
    }

    final displayName = _profile?.resolvedDisplayName ?? AppStrings.defaultUsernameFallback;
    final username = _profile?.username ?? '';
    final avatar = _profile?.avatar;
    final bio = _profile?.bio;
    final role = _profile?.role ?? 'READER';
    final followersCount = _profile?.followersCount ?? 0;
    final followingCount = _profile?.followingCount ?? 0;

    // Check if viewing own profile
    final currentUser = ref.read(currentUserProvider);
    final isOwnProfile = currentUser?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.emerald500.withValues(alpha: 0.15),
              backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar) : null,
              child: avatar == null
                  ? Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.emerald500))
                  : null,
            ),
            const SizedBox(height: 12),
            Text(displayName, style: AppTypography.heading2(textColor)),
            Text('@$username', style: AppTypography.bodyMedium(ext.textMuted)),
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(bio, style: AppTypography.bodyMedium(ext.textSecondary), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 12),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: role == 'WRITER' ? AppColors.emerald500.withValues(alpha: 0.1) : ext.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role == 'WRITER' ? AppStrings.writerRoleLabel : AppStrings.readerRoleLabel,
                style: AppTypography.labelSmall(role == 'WRITER' ? AppColors.emerald500 : ext.textMuted),
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatCol(AppStrings.followersLabel, '$followersCount', textColor, ext),
                Container(width: 1, height: 28, color: Theme.of(context).dividerColor, margin: const EdgeInsets.symmetric(horizontal: 24)),
                _StatCol(AppStrings.followingLabel, '$followingCount', textColor, ext),
                Container(width: 1, height: 28, color: Theme.of(context).dividerColor, margin: const EdgeInsets.symmetric(horizontal: 24)),
                _StatCol(AppStrings.userStoriesLabel, '${_stories.length}', textColor, ext),
              ],
            ),

            const SizedBox(height: 20),

            // Follow / Donate buttons
            if (!isOwnProfile)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: _followLoading
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : _isFollowing
                              ? OutlinedButton(
                                  onPressed: _toggleFollow,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text(AppStrings.followingButtonLabel),
                                )
                              : ElevatedButton.icon(
                                  onPressed: _toggleFollow,
                                  icon: const Icon(Icons.person_add_rounded, size: 18),
                                  label: const Text(AppStrings.followButtonLabel),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Donate
                      },
                      icon: Icon(Icons.favorite_rounded, size: 18, color: AppColors.error.withValues(alpha: 0.8)),
                      label: const Text(AppStrings.donateButtonLabel),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 28),

            // Stories section
            if (_stories.isNotEmpty) ...[
              Row(
                children: [
                  Text(AppStrings.userStoriesSectionTitle(displayName), style: AppTypography.heading3(textColor)),
                ],
              ),
              const SizedBox(height: 12),
              ..._stories.map((story) => GestureDetector(
                onTap: () => context.push(AppRoutes.storyDetail(story.id)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 13, color: AppColors.amber500),
                                const SizedBox(width: 2),
                                Text(story.rating?.toStringAsFixed(1) ?? '-', style: AppTypography.labelSmall(ext.textMuted)),
                                const SizedBox(width: 10),
                                const Icon(Icons.visibility_outlined, size: 13),
                                const SizedBox(width: 2),
                                Text(formatCompactNumber(story.viewCount ?? 0), style: AppTypography.labelSmall(ext.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
              )),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final AppThemeExtension ext;
  const _StatCol(this.label, this.value, this.textColor, this.ext);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.heading3(textColor)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall(ext.textMuted)),
      ],
    );
  }
}
