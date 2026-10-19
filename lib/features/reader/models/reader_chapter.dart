/// A single chapter's reading content, as returned by the chapter-detail
/// endpoint (`ApiEndpoints.chapterByNumber`).
///
/// Kept separate from the list-view `Chapter` model in
/// `shared/models/models.dart` because the reader also needs a minimal
/// placeholder (no `id`/`title` yet) while a locked/premium chapter's price
/// is being resolved from the chapter list, before full content is fetched.
class ReaderChapter {
  final String? id;
  final int chapterNumber;
  final String? title;
  final String? content;
  final int? price;
  final int? totalChapters;

  const ReaderChapter({
    this.id,
    required this.chapterNumber,
    this.title,
    this.content,
    this.price,
    this.totalChapters,
  });

  factory ReaderChapter.fromJson(Map<String, dynamic> json) => ReaderChapter(
    id: json['id'] as String?,
    chapterNumber: json['chapterNumber'] as int? ?? 0,
    title: json['title'] as String?,
    content: json['content'] as String?,
    price: json['price'] as int?,
    totalChapters: json['totalChapters'] as int?,
  );

  /// Used when a 403 (premium/locked) response has no chapter body yet.
  factory ReaderChapter.premiumPlaceholder(int chapterNumber, {int? price}) =>
      ReaderChapter(chapterNumber: chapterNumber, price: price ?? 0);

  /// Parses the story's chapter list (used to look up price/title for a
  /// locked chapter before it has been purchased).
  static List<ReaderChapter> parseList(dynamic value) {
    return _extractList(
      value,
    ).whereType<Map>().map((e) => ReaderChapter.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      for (final key in ['data', 'chapters', 'items', 'results']) {
        final nested = value[key];
        if (nested is List) return nested;
      }
    }
    return const [];
  }
}
