import 'package:flutter/material.dart';

class ExploreSelectionOption {
  final String label;
  final String? value;
  final IconData icon;

  const ExploreSelectionOption({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class ExploreSortOption {
  final String label;
  final String description;
  final String sortBy;
  final String sortOrder;
  final IconData icon;

  const ExploreSortOption({
    required this.label,
    required this.description,
    required this.sortBy,
    required this.sortOrder,
    required this.icon,
  });
}

const exploreTypeOptions = [
  ExploreSelectionOption(
    label: 'Tất cả loại',
    value: null,
    icon: Icons.auto_stories_rounded,
  ),
  ExploreSelectionOption(
    label: 'Truyện chữ',
    value: 'NOVEL',
    icon: Icons.menu_book_rounded,
  ),
  ExploreSelectionOption(
    label: 'Manga',
    value: 'MANGA',
    icon: Icons.brush_rounded,
  ),
  ExploreSelectionOption(
    label: 'Comic',
    value: 'COMIC',
    icon: Icons.dashboard_rounded,
  ),
  ExploreSelectionOption(
    label: 'Light novel',
    value: 'LIGHTNOVEL',
    icon: Icons.auto_stories_rounded,
  ),
];

const exploreStatusOptions = [
  ExploreSelectionOption(
    label: 'Tất cả trạng thái',
    value: null,
    icon: Icons.flag_rounded,
  ),
  ExploreSelectionOption(
    label: 'Đang tiến hành',
    value: 'ONGOING',
    icon: Icons.play_circle_outline_rounded,
  ),
  ExploreSelectionOption(
    label: 'Hoàn thành',
    value: 'COMPLETED',
    icon: Icons.check_circle_outline_rounded,
  ),
  ExploreSelectionOption(
    label: 'Tạm dừng',
    value: 'HIATUS',
    icon: Icons.pause_circle_outline_rounded,
  ),
  ExploreSelectionOption(
    label: 'Đã dừng',
    value: 'DROPPED',
    icon: Icons.cancel_outlined,
  ),
];

const exploreSortOptions = [
  ExploreSortOption(
    label: 'Mới nhất',
    description: 'Truyện vừa được tạo gần đây',
    sortBy: 'createdAt',
    sortOrder: 'desc',
    icon: Icons.fiber_new_rounded,
  ),
  ExploreSortOption(
    label: 'Vừa cập nhật',
    description: 'Truyện có thay đổi mới nhất',
    sortBy: 'updatedAt',
    sortOrder: 'desc',
    icon: Icons.update_rounded,
  ),
  ExploreSortOption(
    label: 'Lượt đọc nhiều',
    description: 'Ưu tiên truyện phổ biến',
    sortBy: 'viewCount',
    sortOrder: 'desc',
    icon: Icons.visibility_rounded,
  ),
  ExploreSortOption(
    label: 'Đánh giá cao',
    description: 'Ưu tiên điểm đánh giá',
    sortBy: 'rating',
    sortOrder: 'desc',
    icon: Icons.star_rounded,
  ),
  ExploreSortOption(
    label: 'Tên A-Z',
    description: 'Sắp xếp theo tiêu đề tăng dần',
    sortBy: 'title',
    sortOrder: 'asc',
    icon: Icons.sort_by_alpha_rounded,
  ),
];

String exploreOptionLabel(
  List<ExploreSelectionOption> options,
  String? selectedValue,
  String fallback,
) {
  for (final option in options) {
    if (option.value == selectedValue) {
      return option.value == null ? fallback : option.label;
    }
  }
  return fallback;
}
