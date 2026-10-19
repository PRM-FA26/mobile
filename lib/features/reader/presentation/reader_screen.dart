import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/reader_chapter.dart';
import '../models/reader_theme.dart';
import '../providers/reader_providers.dart';
import 'widgets/reader_chapter_nav.dart';
import 'widgets/reader_premium_gate.dart';
import 'widgets/reader_theme_circle.dart';

// ── Reader Screen ─────────────────────────────────────────────
class ReaderScreen extends ConsumerStatefulWidget {
  final String storyId;
  final int chapterNumber;
  const ReaderScreen({super.key, required this.storyId, required this.chapterNumber});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  ReaderChapter? _chapter;
  bool _loading = true;
  String? _error;
  bool _showControls = false;
  final _scrollCtrl = ScrollController();
  Timer? _progressTimer;
  double _scrollProgress = 0.0;
  int? _totalChapters;

  @override
  void initState() {
    super.initState();
    _loadChapter(widget.chapterNumber);
    _loadReaderPrefs();
    _scrollCtrl.addListener(_onScroll);
    // Immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _scrollCtrl.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadReaderPrefs() async {
    final storage = ref.read(secureStorageProvider);
    final themeStr = await storage.getReaderTheme();
    final fontSize = await storage.getReaderFontSize();

    if (themeStr != null) {
      final t = ReaderTheme.values.firstWhere((e) => e.name == themeStr, orElse: () => ReaderTheme.light);
      ref.read(readerThemeProvider.notifier).setTheme(t);
    }
    ref.read(readerFontSizeProvider.notifier).setSize(fontSize);
  }

  Future<void> _loadChapter(int number) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>(ApiEndpoints.chapterByNumber(widget.storyId, number));
      final chapter = ReaderChapter.fromJson(data);
      setState(() {
        _chapter = chapter;
        _loading = false;
      });
      _totalChapters ??= chapter.totalChapters;
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        final chapterMeta = await _loadChapterMeta(number);
        if (!mounted) return;
        setState(() {
          _chapter = chapterMeta ?? ReaderChapter.premiumPlaceholder(number);
          _error = 'PREMIUM';
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<ReaderChapter?> _loadChapterMeta(int number) async {
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<dynamic>(ApiEndpoints.storyChapters(widget.storyId));
      final chapters = ReaderChapter.parseList(data);
      _totalChapters ??= chapters.length;
      for (final chapter in chapters) {
        if (chapter.chapterNumber == number) return chapter;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.maxScrollExtent == 0) return;
    final progress = _scrollCtrl.position.pixels / _scrollCtrl.position.maxScrollExtent;
    setState(() => _scrollProgress = progress.clamp(0.0, 1.0));

    // Debounce progress save
    _progressTimer?.cancel();
    _progressTimer = Timer(AppConstants.progressTrackingDebounce, () {
      _saveProgress(progress);
    });
  }

  Future<void> _saveProgress(double progress) async {
    final isLoggedIn = ref.read(authStateProvider);
    if (!isLoggedIn || _chapter == null) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        ApiEndpoints.saveProgress,
        data: {'storyId': widget.storyId, 'chapterId': _chapter!.id, 'progress': progress},
      );
    } catch (_) {}
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _navigateChapter(int delta) {
    final current = _chapter?.chapterNumber ?? widget.chapterNumber;
    final next = current + delta;
    if (next < 1 || (_totalChapters != null && next > _totalChapters!)) return;
    context.go(AppRoutes.reader(widget.storyId, next));
  }

  Future<void> _purchaseChapter() async {
    if (_chapter == null) return;
    final chapterId = _chapter!.id;
    if (chapterId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.readerChapterInfoMissing)));
      }
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiEndpoints.purchaseChapter, data: {'storyId': widget.storyId, 'chapterId': chapterId});
      _loadChapter(_chapter!.chapterNumber);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
      }
    }
  }

  void _setReaderTheme(ReaderTheme t) {
    ref.read(readerThemeProvider.notifier).setTheme(t);
    ref.read(secureStorageProvider).setReaderTheme(t.name);
  }

  void _saveFontSize() {
    final fs = ref.read(readerFontSizeProvider);
    ref.read(secureStorageProvider).setReaderFontSize(fs);
  }

  @override
  Widget build(BuildContext context) {
    final readerTheme = ref.watch(readerThemeProvider);
    final fontSize = ref.watch(readerFontSizeProvider);
    final colors = ReaderColors.of(readerTheme);

    return Scaffold(
      backgroundColor: colors.bg,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            _buildBody(colors, fontSize),
            _buildTopBar(colors),
            _buildBottomBar(colors, readerTheme, fontSize),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ReaderColors colors, double fontSize) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }
    if (_error == 'PREMIUM') {
      return ReaderPremiumGate(
        colors: colors,
        price: _chapter?.price ?? 0,
        onPurchase: _purchaseChapter,
        onBack: () => context.pop(),
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: colors.text)));
    }
    if (_chapter == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 60, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter title
          Text(
            AppStrings.readerChapterLabel(_chapter!.chapterNumber),
            style: TextStyle(color: colors.accent, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            _chapter!.title ?? '',
            style: TextStyle(color: colors.text, fontSize: 22, fontWeight: FontWeight.w900, height: 1.3),
          ),
          const SizedBox(height: 24),
          // Body
          Text(_chapter!.content ?? '', style: AppTypography.readerBody(colors.text, fontSize)),
          const SizedBox(height: 48),
          // Nav buttons
          ReaderChapterNav(
            colors: colors,
            currentChapter: _chapter!.chapterNumber,
            totalChapters: _totalChapters,
            onPrev: () => _navigateChapter(-1),
            onNext: () => _navigateChapter(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ReaderColors colors) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _showControls ? 0 : -(kToolbarHeight + MediaQuery.of(context).padding.top + 10),
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top, 8, 8),
        decoration: BoxDecoration(color: colors.bar, border: Border(bottom: BorderSide(color: colors.border))),
        child: Row(
          children: [
            IconButton(icon: Icon(Icons.arrow_back_rounded, color: colors.text), onPressed: () => context.pop()),
            Expanded(
              child: Text(
                _chapter?.title ?? AppStrings.readerLoadingTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: Icon(Icons.list_rounded, color: colors.text),
              onPressed: () => context.pop(), // Go to chapter list
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ReaderColors colors, ReaderTheme readerTheme, double fontSize) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _showControls ? 0 : -120,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: colors.bar, border: Border(top: BorderSide(color: colors.border))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme selector + Font size
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ReaderThemeCircle(
                  color: AppColors.readerLightBg,
                  selected: readerTheme == ReaderTheme.light,
                  borderColor: colors.border,
                  onTap: () => _setReaderTheme(ReaderTheme.light),
                ),
                const SizedBox(width: 12),
                ReaderThemeCircle(
                  color: AppColors.readerDarkBg,
                  selected: readerTheme == ReaderTheme.dark,
                  borderColor: colors.border,
                  onTap: () => _setReaderTheme(ReaderTheme.dark),
                ),
                const SizedBox(width: 12),
                ReaderThemeCircle(
                  color: AppColors.readerSepiaBg,
                  selected: readerTheme == ReaderTheme.sepia,
                  borderColor: colors.border,
                  onTap: () => _setReaderTheme(ReaderTheme.sepia),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(Icons.text_decrease_rounded, color: colors.text, size: 20),
                  onPressed: () {
                    ref.read(readerFontSizeProvider.notifier).decrease();
                    _saveFontSize();
                  },
                ),
                Text('${fontSize.toInt()}', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.text_increase_rounded, color: colors.text, size: 20),
                  onPressed: () {
                    ref.read(readerFontSizeProvider.notifier).increase();
                    _saveFontSize();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _scrollProgress,
                backgroundColor: colors.border,
                color: colors.accent,
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
