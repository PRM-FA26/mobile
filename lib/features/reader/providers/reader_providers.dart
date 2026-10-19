import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../models/reader_theme.dart';

final readerThemeProvider = NotifierProvider<ReaderThemeNotifier, ReaderTheme>(ReaderThemeNotifier.new);

class ReaderThemeNotifier extends Notifier<ReaderTheme> {
  @override
  ReaderTheme build() => ReaderTheme.light;
  void setTheme(ReaderTheme theme) => state = theme;
}

final readerFontSizeProvider = NotifierProvider<ReaderFontSizeNotifier, double>(ReaderFontSizeNotifier.new);

class ReaderFontSizeNotifier extends Notifier<double> {
  @override
  double build() => AppConstants.defaultFontSize;
  void setSize(double size) => state = size.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
  void increase() => state = (state + AppConstants.fontSizeStep).clamp(
    AppConstants.minFontSize,
    AppConstants.maxFontSize,
  );
  void decrease() => state = (state - AppConstants.fontSizeStep).clamp(
    AppConstants.minFontSize,
    AppConstants.maxFontSize,
  );
}
