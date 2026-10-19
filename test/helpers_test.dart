import 'package:flutter_test/flutter_test.dart';
import 'package:chapterone_mobile/core/utils/helpers.dart';

void main() {
  group('removeAccents', () {
    test('strips Vietnamese diacritics including đ/Đ', () {
      expect(removeAccents('Tiếng Việt'), 'Tieng Viet');
      expect(removeAccents('đường phố'), 'duong pho');
      expect(removeAccents('Đà Nẵng'), 'Da Nang');
    });

    test('leaves plain ASCII untouched', () {
      expect(removeAccents('Hello World'), 'Hello World');
    });

    test('returns empty string for empty input', () {
      expect(removeAccents(''), '');
    });
  });

  group('countWords', () {
    test('counts words separated by whitespace', () {
      expect(countWords('Hello world'), 2);
      expect(countWords('  Hello   world  '), 2);
    });

    test('returns 0 for empty or whitespace-only input', () {
      expect(countWords(''), 0);
      expect(countWords('   '), 0);
    });
  });

  group('formatRelativeTime', () {
    test('shows "Vừa xong" for just-now timestamps', () {
      expect(formatRelativeTime(DateTime.now()), 'Vừa xong');
    });

    test('shows minutes for < 1 hour ago', () {
      final time = DateTime.now().subtract(const Duration(minutes: 5));
      expect(formatRelativeTime(time), '5 phút trước');
    });

    test('shows hours for < 1 day ago', () {
      final time = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatRelativeTime(time), '3 giờ trước');
    });

    test('shows days for < 7 days ago', () {
      final time = DateTime.now().subtract(const Duration(days: 2));
      expect(formatRelativeTime(time), '2 ngày trước');
    });

    test('falls back to dd/MM/yyyy for 7+ days ago', () {
      final time = DateTime(2026, 1, 15);
      expect(formatRelativeTime(time), '15/01/2026');
    });
  });

  group('formatCompactNumber', () {
    test('leaves small numbers unformatted', () {
      expect(formatCompactNumber(999), '999');
      expect(formatCompactNumber(0), '0');
    });

    test('formats thousands with K suffix', () {
      expect(formatCompactNumber(1234), '1.2K');
      expect(formatCompactNumber(15000), '15.0K');
    });

    test('formats millions with M suffix', () {
      expect(formatCompactNumber(1234567), '1.2M');
    });
  });

  group('formatXu', () {
    test('adds thousands separators', () {
      expect(formatXu(1000), '1.000');
      expect(formatXu(1234567), '1.234.567');
    });

    test('leaves small amounts unformatted', () {
      expect(formatXu(500), '500');
    });
  });
}
