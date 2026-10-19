import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../models/reader_theme.dart';

/// Prev/next chapter buttons shown at the end of the chapter content.
class ReaderChapterNav extends StatelessWidget {
  final ReaderColors colors;
  final int currentChapter;
  final int? totalChapters;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const ReaderChapterNav({
    super.key,
    required this.colors,
    required this.currentChapter,
    this.totalChapters,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (currentChapter > 1)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrev,
              icon: Icon(Icons.chevron_left_rounded, color: colors.accent),
              label: Text(AppStrings.readerPrevChapter, style: TextStyle(color: colors.accent)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.accent.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        if (currentChapter > 1 && (totalChapters == null || currentChapter < totalChapters!))
          const SizedBox(width: 12),
        if (totalChapters == null || currentChapter < totalChapters!)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              label: const Text(AppStrings.readerNextChapter),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
      ],
    );
  }
}
