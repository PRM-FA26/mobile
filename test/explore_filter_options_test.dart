import 'package:flutter_test/flutter_test.dart';
import 'package:chapterone_mobile/features/explore/models/explore_filter_options.dart';

void main() {
  group('exploreOptionLabel', () {
    test('returns the matching option label for a selected value', () {
      expect(exploreOptionLabel(exploreTypeOptions, 'MANGA', 'Loại'), 'Manga');
      expect(exploreOptionLabel(exploreStatusOptions, 'COMPLETED', 'Trạng thái'), 'Hoàn thành');
    });

    test('returns the fallback for the "all" (null-value) option', () {
      expect(exploreOptionLabel(exploreTypeOptions, null, 'Loại'), 'Loại');
    });

    test('returns the fallback when the selected value is not in the list', () {
      expect(exploreOptionLabel(exploreTypeOptions, 'UNKNOWN', 'Loại'), 'Loại');
    });
  });

  group('exploreTypeOptions / exploreStatusOptions / exploreSortOptions', () {
    test('always include an "all"/default null-value option first', () {
      expect(exploreTypeOptions.first.value, isNull);
      expect(exploreStatusOptions.first.value, isNull);
    });

    test('sort options carry a valid backend sortBy/sortOrder pair', () {
      for (final option in exploreSortOptions) {
        expect(option.sortBy, isNotEmpty);
        expect(['asc', 'desc'], contains(option.sortOrder));
      }
    });
  });
}
