import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// The main scaffold with bottom navigation bar.
///
/// Wraps the [ShellRoute] children and manages tab selection.
/// Maps to the web's Navbar — 5 primary destinations:
/// Home, Explore, Library, Notifications, Profile.
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(AppRoutes.home, AppStrings.navHome, Icons.home_rounded, Icons.home_outlined),
    _TabItem(AppRoutes.explore, AppStrings.navExplore, Icons.explore_rounded, Icons.explore_outlined),
    _TabItem(AppRoutes.library, AppStrings.navLibrary, Icons.bookmark_rounded, Icons.bookmark_border_rounded),
    _TabItem(AppRoutes.notifications, AppStrings.navNotifications, Icons.notifications_rounded, Icons.notifications_outlined),
    _TabItem(AppRoutes.profile, AppStrings.navProfile, Icons.person_rounded, Icons.person_outline_rounded),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            if (index != currentIndex) {
              context.go(_tabs[index].path);
            }
          },
          destinations: _tabs.map((tab) {
            final isSelected = _tabs.indexOf(tab) == currentIndex;
            return NavigationDestination(
              icon: Icon(
                tab.inactiveIcon,
                color: isSelected ? AppColors.emerald500 : null,
              ),
              selectedIcon: Icon(
                tab.activeIcon,
                color: AppColors.emerald500,
              ),
              label: tab.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final String path;
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _TabItem(this.path, this.label, this.activeIcon, this.inactiveIcon);
}
