import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/models.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<AppNotification> _notifs = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<dynamic>(ApiEndpoints.notifications);
      final list = data is List
          ? data
          : (data is Map ? (data['data'] as List? ?? []) : []);
      setState(() {
        _notifs = list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
        _unreadCount = _notifs.where((n) => !n.isRead).length;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = AppStrings.notificationsLoadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification notif) async {
    if (notif.isRead) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.put(ApiEndpoints.markRead(notif.id));
      setState(() {
        final i = _notifs.indexWhere((n) => n.id == notif.id);
        if (i >= 0) {
          _notifs[i] = notif.copyWith(isRead: true);
          _unreadCount = _notifs.where((n) => !n.isRead).length;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.actionFailedRetry)));
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put(ApiEndpoints.markAllRead);
      setState(() {
        _notifs = _notifs.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.actionFailedRetry)));
      }
    }
  }

  void _handleTap(AppNotification notif) {
    _markAsRead(notif);
    if (notif.link != null && notif.link!.isNotEmpty) {
      context.push(notif.link!);
    }
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'new_chapter':
        return Icons.menu_book_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'new_follower':
      case 'follower':
        return Icons.person_add_rounded;
      case 'donation':
      case 'donate':
        return Icons.favorite_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'new_chapter':
        return AppColors.notifChapter;
      case 'comment':
        return AppColors.notifComment;
      case 'new_follower':
      case 'follower':
        return AppColors.notifFollower;
      case 'donation':
      case 'donate':
        return AppColors.notifDonation;
      default:
        return AppColors.emerald500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.notificationsTitle, style: AppTypography.heading3(textColor)),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(AppStrings.notificationsMarkAllRead),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _loading
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
                      ElevatedButton(onPressed: _fetchNotifications, child: const Text(AppStrings.retry)),
                    ],
                  ),
                )
              : _notifs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: ext.textMuted.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(AppStrings.notificationsEmptyTitle, style: AppTypography.bodyMedium(ext.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: AppColors.emerald500,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifs.length,
                    itemBuilder: (_, i) {
                      final n = _notifs[i];
                      final color = _colorForType(n.type);
                      return _NotifTile(
                        notification: n,
                        icon: _iconForType(n.type),
                        color: color,
                        onTap: () => _handleTap(n),
                      );
                    },
                  ),
                ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NotifTile({required this.notification, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : (isDark
                  ? AppColors.emerald500.withValues(alpha: 0.04)
                  : AppColors.emerald500.withValues(alpha: 0.03)),
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTypography.labelLarge(isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        .copyWith(fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(ext.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRelativeTime(notification.createdAt),
                    style: AppTypography.bodySmall(ext.textMuted).copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.emerald500,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
