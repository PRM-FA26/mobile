import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

class ExploreSearchAppBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ExploreSearchAppBar({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;

    return SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: 70,
      title: Container(
        height: 48,
        decoration: BoxDecoration(
          color: ext.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTypography.bodyMedium(
            Theme.of(context).colorScheme.onSurface,
          ),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: AppStrings.exploreSearchHint,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: ext.textMuted,
              size: 20,
            ),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: ext.textMuted,
                      size: 20,
                    ),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
