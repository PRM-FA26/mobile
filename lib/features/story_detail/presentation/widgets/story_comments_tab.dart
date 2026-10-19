import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/comment_realtime_service.dart';
import '../../data/comment_repository.dart';
import '../../models/story_comment.dart';

/// "Bình luận" tab of the story detail screen: REST-loaded comment list kept
/// live via [CommentRealtimeService] (see that class for the Socket.IO
/// protocol), plus a typing indicator and the comment input box.
class StoryCommentsTab extends ConsumerStatefulWidget {
  final String storyId;
  final TabController tabController;

  const StoryCommentsTab({super.key, required this.storyId, required this.tabController});

  @override
  ConsumerState<StoryCommentsTab> createState() => _StoryCommentsTabState();
}

class _StoryCommentsTabState extends ConsumerState<StoryCommentsTab> {
  final _commentCtrl = TextEditingController();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  late final CommentRepository _commentRepository;
  late final CommentRealtimeService _realtimeService;
  List<StoryComment> _comments = [];
  List<CommentTypingUser> _typingUsers = const [];
  Timer? _typingStopTimer;
  bool _loading = true;
  bool _submitting = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _commentRepository = CommentRepository(ref.read(apiClientProvider));
    _realtimeService = CommentRealtimeService(storage: ref.read(secureStorageProvider));
    widget.tabController.addListener(_handleTabChanged);
    _commentCtrl.addListener(_handleTypingChanged);
    _fetchComments();
    _connectRealtime();
  }

  @override
  void didUpdateWidget(covariant StoryCommentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController == widget.tabController) return;

    oldWidget.tabController.removeListener(_handleTabChanged);
    widget.tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    _realtimeService.stopTyping();
    widget.tabController.removeListener(_handleTabChanged);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _realtimeService.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectRealtime() async {
    _subscriptions
      ..add(_realtimeService.created.listen(_upsertComment))
      ..add(_realtimeService.updated.listen(_updateComment))
      ..add(_realtimeService.deleted.listen(_removeComment))
      ..add(_realtimeService.liked.listen(_applyLikeEvent))
      ..add(_realtimeService.typing.listen(_applyTypingUsers))
      ..add(_realtimeService.syncRequested.listen((_) => _fetchComments()));

    await _realtimeService.connect(widget.storyId);
  }

  void _handleTabChanged() {
    if (widget.tabController.index == 1) return;

    _stopTypingNow();
    if (_typingUsers.isNotEmpty && mounted) {
      setState(() => _typingUsers = const []);
    }
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await _commentRepository.fetchByStory(widget.storyId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    final isLoggedIn = ref.read(authStateProvider);
    if (!isLoggedIn) {
      context.push(AppRoutes.login);
      return;
    }
    _stopTypingNow();
    setState(() => _submitting = true);
    try {
      final comment = await _commentRepository.create(widget.storyId, text);
      _commentCtrl.clear();
      _upsertComment(comment);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _toggleLike(StoryComment comment) async {
    final isLoggedIn = ref.read(authStateProvider);
    if (!isLoggedIn) {
      context.push(AppRoutes.login);
      return;
    }

    _applyLocalLike(comment);
    try {
      if (comment.isLiked) {
        await _commentRepository.unlike(comment.id);
      } else {
        await _commentRepository.like(comment.id);
      }
    } catch (_) {
      _restoreComment(comment);
    }
  }

  void _handleTypingChanged() {
    final isLoggedIn = ref.read(authStateProvider);
    final hasText = _commentCtrl.text.trim().isNotEmpty;
    if (!isLoggedIn || !hasText) {
      _stopTypingNow();
      return;
    }

    _isTyping = true;
    _realtimeService.startTyping();
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 2), _stopTypingNow);
  }

  void _stopTypingNow() {
    _typingStopTimer?.cancel();
    if (!_isTyping) return;
    _isTyping = false;
    _realtimeService.stopTyping();
  }

  void _upsertComment(StoryComment comment) {
    if (!mounted || comment.storyId != widget.storyId) return;
    setState(() {
      _comments = [comment, ..._comments.where((item) => item.id != comment.id)];
    });
  }

  void _updateComment(StoryComment comment) {
    if (!mounted || comment.storyId != widget.storyId) return;
    setState(() {
      var replaced = false;
      _comments = _comments.map((item) {
        if (item.id != comment.id) return item;
        replaced = true;
        return comment.copyWith(isLiked: item.isLiked);
      }).toList();
      if (!replaced) _comments = [comment, ..._comments];
    });
  }

  void _removeComment(String commentId) {
    if (!mounted) return;
    setState(() {
      _comments = _comments.where((item) => item.id != commentId).toList();
    });
  }

  void _applyLikeEvent(CommentLikeEvent event) {
    if (!mounted) return;
    final currentUserId = ref.read(currentUserProvider)?.id;
    setState(() {
      _comments = _comments.map((comment) {
        if (comment.id != event.commentId) return comment;
        return comment.copyWith(
          likesCount: event.likesCount,
          isLiked: event.userId == currentUserId ? event.isLiked : null,
        );
      }).toList();
    });
  }

  void _applyLocalLike(StoryComment comment) {
    if (!mounted) return;
    setState(() {
      _comments = _comments.map((item) {
        if (item.id != comment.id) return item;
        final nextLiked = !comment.isLiked;
        final rawCount = comment.likesCount + (nextLiked ? 1 : -1);
        final nextCount = rawCount < 0 ? 0 : rawCount;
        return comment.copyWith(isLiked: nextLiked, likesCount: nextCount);
      }).toList();
    });
  }

  void _restoreComment(StoryComment comment) {
    if (!mounted) return;
    setState(() {
      _comments = _comments.map((item) {
        return item.id == comment.id ? comment : item;
      }).toList();
    });
  }

  void _applyTypingUsers(List<CommentTypingUser> users) {
    if (!mounted) return;
    final currentUserId = ref.read(currentUserProvider)?.id;
    setState(() {
      _typingUsers = users.where((user) => user.id.isNotEmpty && user.id != currentUserId).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
              ? Center(
                  child: Text(AppStrings.noCommentsYet, style: AppTypography.bodyMedium(ext.textMuted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (_, i) =>
                      _CommentTile(comment: _comments[i], onToggleLike: () => _toggleLike(_comments[i])),
                ),
        ),
        _TypingIndicator(users: _typingUsers),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  maxLines: 1,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    hintText: AppStrings.writeCommentHint,
                    filled: true,
                    fillColor: ext.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(
                onPressed: _submitting ? null : _submitComment,
                icon: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: AppColors.emerald500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final List<CommentTypingUser> users;

  const _TypingIndicator({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(_typingLabel(users), style: AppTypography.bodySmall(context.appTheme.textMuted)),
      ),
    );
  }
}

String _typingLabel(List<CommentTypingUser> users) {
  if (users.length == 1) {
    return AppStrings.typingLabelOne(users.first.displayNameOrUsername);
  }
  if (users.length == 2) {
    return AppStrings.typingLabelTwo(users[0].displayNameOrUsername, users[1].displayNameOrUsername);
  }
  return AppStrings.typingLabelMany(users.length);
}

class _CommentTile extends StatelessWidget {
  final StoryComment comment;
  final VoidCallback onToggleLike;

  const _CommentTile({required this.comment, required this.onToggleLike});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = comment.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.emerald500.withValues(alpha: 0.15),
            child: Text(
              user?.initial ?? '?',
              style: const TextStyle(color: AppColors.emerald500, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user?.displayNameOrUsername ?? AppStrings.defaultUsernameFallback,
                      style: AppTypography.labelLarge(
                        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ).copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(formatRelativeTime(comment.createdAt), style: AppTypography.bodySmall(ext.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: AppTypography.bodyMedium(ext.textSecondary)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onToggleLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: comment.isLiked ? AppColors.error : ext.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likesCount}',
                        style: AppTypography.labelSmall(comment.isLiked ? AppColors.error : ext.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
