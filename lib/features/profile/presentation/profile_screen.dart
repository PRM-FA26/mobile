import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ProfileDetails? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>(ApiEndpoints.me);
      setState(() { _profile = ProfileDetails.fromJson(data); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logoutTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.logoutTitle),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = ref.read(secureStorageProvider);
      await storage.removeTokens();
      ref.read(authStateProvider.notifier).setLoggedIn(false);
      ref.read(currentUserProvider.notifier).clear();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.appTheme;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final themeMode = ref.watch(themeModeProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.profileTitle, style: AppTypography.heading3(textColor))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final username = _profile?.username ?? AppStrings.defaultUsernameFallback;
    final displayName = _profile?.resolvedDisplayName ?? username;
    final avatar = _profile?.avatar;
    final bio = _profile?.bio;
    final role = _profile?.role ?? 'READER';
    final followersCount = _profile?.followersCount ?? 0;
    final followingCount = _profile?.followingCount ?? 0;
    final storiesCount = _profile?.storiesCount ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: true,
            title: Text(AppStrings.profileTitle, style: AppTypography.heading3(textColor)),
            actions: [
              IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () => _showSettingsSheet(context, themeMode)),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.emerald500.withValues(alpha: 0.15),
                        backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar) : null,
                        child: avatar == null
                            ? Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.emerald500))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showEditProfileSheet(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.emerald500,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppColors.darkBg : AppColors.lightBg, width: 3),
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(displayName, style: AppTypography.heading2(textColor)),
                  Text('@$username', style: AppTypography.bodyMedium(ext.textMuted)),
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(bio, style: AppTypography.bodyMedium(ext.textSecondary), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 4),
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

                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatBox(AppStrings.followersLabel, '$followersCount', ext),
                      Container(width: 1, height: 30, color: Theme.of(context).dividerColor, margin: const EdgeInsets.symmetric(horizontal: 20)),
                      _StatBox(AppStrings.followingLabel, '$followingCount', ext),
                      if (role == 'WRITER') ...[
                        Container(width: 1, height: 30, color: Theme.of(context).dividerColor, margin: const EdgeInsets.symmetric(horizontal: 20)),
                        _StatBox(AppStrings.userStoriesLabel, '$storiesCount', ext),
                      ],
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Menu items
                  _MenuSection(
                    items: [
                      _MenuItem(Icons.history_rounded, AppStrings.historyTitle, () => context.push(AppRoutes.history)),
                      _MenuItem(Icons.account_balance_wallet_rounded, AppStrings.walletTitle, () => context.push(AppRoutes.wallet)),
                      _MenuItem(Icons.emoji_events_rounded, AppStrings.rankingsTitle, () => context.push(AppRoutes.rankings)),
                      if (role == 'WRITER')
                        _MenuItem(Icons.edit_note_rounded, AppStrings.studioTitle, () => context.push(AppRoutes.studio)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _MenuSection(
                    items: [
                      _MenuItem(Icons.lock_outline_rounded, AppStrings.changePasswordTitle, () => _showChangePasswordSheet(context)),
                      _MenuItem(Icons.logout_rounded, AppStrings.logoutTitle, _logout, color: AppColors.error),
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(AppStrings.themeSectionTitle, style: AppTypography.heading3(Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 16),
            ...[
              (AppStrings.themeModeSystem, ThemeMode.system, Icons.brightness_auto_rounded),
              (AppStrings.themeModeLight, ThemeMode.light, Icons.light_mode_rounded),
              (AppStrings.themeModeDark, ThemeMode.dark, Icons.dark_mode_rounded),
            ].map((e) {
              final (label, mode, icon) = e;
              return RadioListTile<ThemeMode>(
                value: mode,
                groupValue: current,
                onChanged: (v) {
                  if (v != null) {
                    ref.read(themeModeProvider.notifier).setMode(v);
                    ref.read(secureStorageProvider).setThemeMode(v.name);
                  }
                  Navigator.pop(ctx);
                },
                title: Text(label),
                secondary: Icon(icon),
                activeColor: AppColors.emerald500,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _profile?.displayName ?? '');
    final bioCtrl = TextEditingController(text: _profile?.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(AppStrings.editProfileTitle, style: AppTypography.heading3(Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: AppStrings.displayNameLabel, prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 16),
            TextField(controller: bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: AppStrings.bioLabel, prefixIcon: Icon(Icons.info_outline))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final api = ref.read(apiClientProvider);
                    await api.patch(ApiEndpoints.updateProfile, data: {
                      'displayName': nameCtrl.text.trim(),
                      'bio': bioCtrl.text.trim(),
                    });
                    ref.read(currentUserProvider.notifier).updateProfile(displayName: nameCtrl.text.trim());
                    _fetchProfile();
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on ApiException catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                },
                child: const Text(AppStrings.saveChangesButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(AppStrings.changePasswordTitle, style: AppTypography.heading3(Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 20),
            TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: AppStrings.currentPasswordLabel, prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 12),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: AppStrings.newPasswordLabel, prefixIcon: Icon(Icons.lock_rounded))),
            const SizedBox(height: 12),
            TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: AppStrings.confirmPasswordShortLabel, prefixIcon: Icon(Icons.lock_rounded))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (newCtrl.text != confirmCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.confirmPasswordMismatch)));
                    return;
                  }
                  try {
                    final api = ref.read(apiClientProvider);
                    await api.patch(ApiEndpoints.changePassword, data: {
                      'oldPassword': currentCtrl.text,
                      'newPassword': newCtrl.text,
                      'confirmPassword': confirmCtrl.text,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.changePasswordSuccess)));
                  } on ApiException catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
                  }
                },
                child: const Text(AppStrings.updateButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeExtension ext;
  const _StatBox(this.label, this.value, this.ext);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.heading3(Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall(ext.textMuted)),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: item.color ?? context.appTheme.textMuted),
                title: Text(item.label, style: AppTypography.bodyMedium(
                  item.color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                )),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: item.onTap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              if (i < items.length - 1) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem(this.icon, this.label, this.onTap, {this.color});
}
