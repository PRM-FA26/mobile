import 'package:flutter_test/flutter_test.dart';
import 'package:chapterone_mobile/features/reader/models/reader_chapter.dart';

void main() {
  group('ReaderChapter.fromJson', () {
    test('parses a full chapter detail payload', () {
      final chapter = ReaderChapter.fromJson({
        'id': 'ch1',
        'chapterNumber': 3,
        'title': 'Chương 3',
        'content': 'Nội dung...',
        'price': 0,
        'totalChapters': 20,
      });

      expect(chapter.id, 'ch1');
      expect(chapter.chapterNumber, 3);
      expect(chapter.title, 'Chương 3');
      expect(chapter.content, 'Nội dung...');
      expect(chapter.totalChapters, 20);
    });

    test('defaults chapterNumber to 0 when missing', () {
      final chapter = ReaderChapter.fromJson({'id': 'ch1'});
      expect(chapter.chapterNumber, 0);
      expect(chapter.title, isNull);
    });
  });

  group('ReaderChapter.premiumPlaceholder', () {
    test('creates a minimal placeholder for a locked chapter', () {
      final placeholder = ReaderChapter.premiumPlaceholder(5, price: 100);
      expect(placeholder.chapterNumber, 5);
      expect(placeholder.price, 100);
      expect(placeholder.id, isNull);
    });

    test('defaults price to 0 when not provided', () {
      final placeholder = ReaderChapter.premiumPlaceholder(5);
      expect(placeholder.price, 0);
    });
  });

  group('ReaderChapter.parseList', () {
    test('reads a direct list', () {
      final chapters = ReaderChapter.parseList([
        {'id': 'a', 'chapterNumber': 1},
        {'id': 'b', 'chapterNumber': 2},
      ]);
      expect(chapters.length, 2);
      expect(chapters[1].chapterNumber, 2);
    });

    test('reads an enveloped list under data/chapters/items/results', () {
      final chapters = ReaderChapter.parseList({
        'chapters': [
          {'id': 'a', 'chapterNumber': 1},
        ],
      });
      expect(chapters.length, 1);
      expect(chapters.first.id, 'a');
    });

    test('falls back to an empty list for unsupported payloads', () {
      expect(ReaderChapter.parseList({'unexpected': 'shape'}), isEmpty);
      expect(ReaderChapter.parseList(null), isEmpty);
    });
  });
}
