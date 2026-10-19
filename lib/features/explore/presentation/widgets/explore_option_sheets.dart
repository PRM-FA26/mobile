import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/explore_filter_options.dart';

class ExploreOptionSheet extends StatelessWidget {
  final String title;
  final List<ExploreSelectionOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  const ExploreOptionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExploreSheetHandle(),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.heading3(
                Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final option = options[index];
                  final selected = option.value == selectedValue;

                  return ListTile(
                    leading: Icon(
                      option.icon,
                      color: context.appTheme.textMuted,
                    ),
                    title: Text(option.label),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.emerald500,
                          )
                        : null,
                    selected: selected,
                    onTap: () => onSelected(option.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExploreSortSheet extends StatelessWidget {
  final ExploreSortOption selectedSort;
  final ValueChanged<ExploreSortOption> onSelected;

  const ExploreSortSheet({
    super.key,
    required this.selectedSort,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExploreSheetHandle(),
            const SizedBox(height: 16),
            Text(
              'Sắp xếp theo',
              style: AppTypography.heading3(
                Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...exploreSortOptions.map((option) {
              final selected = option == selectedSort;

              return ListTile(
                leading: Icon(option.icon, color: context.appTheme.textMuted),
                title: Text(option.label),
                subtitle: Text(
                  option.description,
                  style: AppTypography.bodySmall(context.appTheme.textMuted),
                ),
                trailing: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.emerald500,
                      )
                    : null,
                selected: selected,
                onTap: () => onSelected(option),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ExploreGenreTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ExploreGenreTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.emerald500)
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}

class ExploreSheetHandle extends StatelessWidget {
  const ExploreSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
