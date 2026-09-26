import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:takwa/l10n/app_localizations.dart';
import 'package:quran_library/quran_library.dart' as ql;
import '../../data/muyassar_tafsir_loader.dart';
import '../../data/quran_data.dart';
import '../../data/quran_models.dart';
import '../../providers/quran_providers.dart';
import '../../utils/quran_helpers.dart';
import '../widgets/reader/quran_reader_background.dart';
import '../widgets/reader/quran_reader_bars.dart';
import '../widgets/reader/quran_reader_dialogs.dart';
import '../widgets/reader/quran_reader_picker_sheets.dart';
import '../widgets/reader/quran_reader_sheets.dart';
import '../widgets/reader/quran_reader_colors.dart';

class QuranReaderScreen extends ConsumerStatefulWidget {
  final bool startFromKhatma;
  final int? initialSurah;
  final int? initialPage;
  // Unique-quran-wide ayah number (AyahModel.ayahUQNumber) to jump to and
  // briefly highlight on open — e.g. from the daily-verse card or a shared
  // ayah link. Only used together with initialPage (the page that ayah is
  // on); ignored if initialPage is null.
  final int? initialAyahUQNumber;

  const QuranReaderScreen({
    super.key,
    this.startFromKhatma = false,
    this.initialSurah,
    this.initialPage,
    this.initialAyahUQNumber,
  });

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen>
    with TickerProviderStateMixin {
  late AnimationController _toolbarAnim;
  late Animation<double> _topFade;
  late Animation<Offset> _topSlide, _bottomSlide;

  // Zoom & Font Scale Controller (preserves 15-line Uthmani Mushaf layout)
  late final TransformationController _transformationController;
  AnimationController? _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;
  bool _isZoomed = false;

  /// The live zoom factor, read straight from the controller instead of
  /// mirrored into a field: `_onTransformationChanged` only rebuilds this
  /// screen when the zoomed/unzoomed state flips, so a copied field would
  /// go stale mid-pinch.
  double get _currentScale =>
      _transformationController.value.getMaxScaleOnAxis();

  int _currentPage = 1;
  bool _toolbarVisible = true;
  static const int _totalPages = 604;

  // Passed to QuranLibraryScreen exactly once at mount and never changed —
  // the widget re-applies pageIndex to the shared QuranCtrl singleton on
  // every rebuild it goes through (its own internal behavior, not
  // something this screen controls), so a reactive value here would
  // fight the user's own swipes/jumps on every unrelated rebuild (e.g.
  // audio state ticking). _currentPage below is the one that actually
  // tracks "where we are now", updated via onPageChanged.
  late final int _initialPageIndex;

  // Tracks how many pages read in this session
  int _sessionPagesRead = 0;
  int _sessionStartPage = 1;

  // Wall-clock time this reading session started, for the Khatma
  // "reading time" stats — only accumulated (in dispose()) when this
  // screen was opened from an active Khatma, since a Khatma is the only
  // thing that currently surfaces reading-time stats.
  late final DateTime _sessionStart;

  // Captured in initState rather than read via `ref` inside dispose():
  // Riverpod's ConsumerStatefulElement tears down its ref-handling before
  // State.dispose() runs, so `ref.read(...)` there throws "Cannot use
  // 'ref' after the widget was disposed." Reading the notifier once,
  // early, and calling straight into it in dispose() sidesteps that.
  late final KhatmaExNotifier _khatmaNotifier;
  late final QuranLastReadNotifier _lastReadNotifier;

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _khatmaNotifier = ref.read(khatmaExProvider.notifier);
    _lastReadNotifier = ref.read(quranLastReadProvider.notifier);

    int startPage = 1;
    if (widget.initialPage != null) {
      startPage = widget.initialPage!.clamp(1, _totalPages);
    } else if (widget.initialSurah != null) {
      final idx = (widget.initialSurah! - 1).clamp(0, kSurahData.length - 1);
      startPage = kSurahData[idx].startPage;
    } else {
      startPage = ref
          .read(quranStateProvider)
          .currentPage
          .clamp(1, _totalPages);
    }

    _currentPage = startPage;
    _sessionStartPage = startPage;
    _initialPageIndex = startPage - 1;

    _toolbarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _topFade = _toolbarAnim;
    _topSlide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _toolbarAnim, curve: Curves.easeOutCubic),
        );
    _bottomSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _toolbarAnim, curve: Curves.easeOutCubic),
        );

    // Zoom transformation controller
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    // Restore the persisted font-size/zoom preference (quranStateProvider's
    // fontSize is the source of truth _applyFontScale writes to) instead of
    // always starting at 100%. Without this, every fresh QuranReaderScreen
    // silently ignored whatever the reader-settings sheet had saved — the
    // slider always looked reset after leaving and reopening the reader.
    final savedFontSize = ref.read(quranStateProvider).fontSize;
    final savedScale = (savedFontSize / 22.0).clamp(0.85, 2.0);
    _isZoomed = (savedScale - 1.0).abs() > 0.02;
    _transformationController.value = Matrix4.diagonal3Values(
      savedScale,
      savedScale,
      1.0,
    );

    // Crucial: lock quran_library internal scale factor to 1.0 so flowing layout mode is never triggered
    try {
      ql.QuranLibrary.quranCtrl.state.scaleFactor.value = 1.0;
    } catch (_) {}

    // quran_library's QuranCtrl (its page controller included) is a
    // GetX-lifetime singleton, not scoped to this screen: it survives
    // across every QuranReaderScreen instance for as long as the app
    // process is alive. The `pageIndex` constructor param passed to
    // ql.QuranLibraryScreen below only ever updates its *display* value
    // (and is silently ignored altogether when pageIndex == 0, i.e. page
    // 1) — it never actually moves that shared page controller. So without
    // this explicit jump, "Continue Reading" (or any other entry point)
    // could open showing whatever page a previous reader session last
    // scrolled to, rather than the page this screen was asked to open.
    // ql.QuranLibrary().jumpToPage()/jumpToAyah() are the library's own
    // documented, tested APIs for this — already used elsewhere in this
    // file (_onPrevPage, _jumpToSurah, ...) — so this uses the same path
    // instead of relying on the constructor param.
    try {
      if (widget.initialAyahUQNumber != null) {
        ql.QuranLibrary().jumpToAyah(startPage, widget.initialAyahUQNumber!);
      } else {
        ql.QuranLibrary().jumpToPage(startPage);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
    // Deferred to the next event-loop tick: Riverpod prohibits modifying
    // provider state synchronously during widget unmounting / dispose.
    // Calling via Future(() { ... }) avoids the assertion:
    // "Tried to modify a provider while the widget tree was building."
    Future(() {
      // Reading time is a Khatma-only stat — only tracked when this
      // session was started from an active Khatma.
      if (widget.startFromKhatma) _khatmaNotifier.addReadingTime(elapsed);
      // Flush the throttled progress pushes so pages read in the last
      // few seconds sync now instead of waiting for the next app start.
      _khatmaNotifier.flushPendingPush();
      _lastReadNotifier.flushPendingPush();
    });
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _zoomAnimController?.dispose();
    _toolbarAnim.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────
  int _surahForPage(int page) {
    for (int i = kSurahData.length - 1; i >= 0; i--) {
      if (page >= kSurahData[i].startPage) return i + 1;
    }
    return 1;
  }

  void _onPageChanged(int pageIndex) {
    final p = pageIndex + 1;
    if (p == _currentPage || p < 1 || p > _totalPages) return;
    setState(() {
      _sessionPagesRead = (p - _sessionStartPage).abs();
      _currentPage = p;
    });
    ref.read(quranStateProvider.notifier).setPage(p);

    if (widget.startFromKhatma) {
      _khatmaNotifier.advancePage(p);
    }

    // Record where reading actually stopped. The first ayah listed for
    // the page (from quran_library's real page data) is the one the
    // page begins with — previously this always saved ayah 1, which was
    // only correct when the page happened to start a new surah.
    final pos = _positionForPage(p);
    ref
        .read(quranLastReadProvider.notifier)
        .save(
          QuranBookmark(
            surahNum: pos.$1,
            ayahNum: pos.$2,
            page: p,
            surahName: pos.$3,
            savedAt: DateTime.now(),
          ),
        );
  }

  /// (surah number, first ayah on the page, Arabic surah name) for a
  // page — falls back to the surah boundary from kSurahData + ayah 1 when
  // the library data isn't available.
  (int, int, String) _positionForPage(int page) {
    try {
      final pageAyahs = ql.QuranLibrary.quranCtrl.getPageAyahsByIndex(page - 1);
      if (pageAyahs.isNotEmpty) {
        final first = pageAyahs.first;
        final surahNum = (first.surahNumber ?? 1).clamp(1, kSurahData.length);
        return (
          surahNum,
          first.ayahNumber,
          ql.QuranLibrary.quranCtrl.surahs[surahNum - 1].arabicName,
        );
      }
    } catch (_) {}
    final surahNum = _surahForPage(page);
    return (
      surahNum,
      1,
      ql.QuranLibrary.quranCtrl.surahs[surahNum - 1].arabicName,
    );
  }

  void _toggleToolbar() {
    setState(() => _toolbarVisible = !_toolbarVisible);
    _toolbarVisible ? _toolbarAnim.forward() : _toolbarAnim.reverse();
  }

  // ── Zoom & Font Size ───────────────────────────────────────
  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = (scale - 1.0).abs() > 0.02;
    // Only the boolean is mirrored into widget state. It gates `panEnabled`
    // and whether the badge is shown at all, and it changes once per pinch
    // gesture; the numeric scale is read through the `_currentScale` getter
    // (and by the badge's own listener), so a pinch no longer rebuilds the
    // whole reader on every pointer event.
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _animateZoom(double targetScale) {
    _zoomAnimController?.dispose();
    final startMatrix = _transformationController.value;
    // scale() is deprecated in this Flutter version's vector_math —
    // multiply() by an explicit scale matrix is the equivalent.
    final endMatrix = Matrix4.identity()
      ..multiply(Matrix4.diagonal3Values(targetScale, targetScale, 1.0));
    _zoomAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _zoomAnimation = Matrix4Tween(begin: startMatrix, end: endMatrix).animate(
      CurvedAnimation(parent: _zoomAnimController!, curve: Curves.easeOutCubic),
    );
    _zoomAnimation!.addListener(() {
      _transformationController.value = _zoomAnimation!.value;
    });
    _zoomAnimController!.forward();
  }

  void _resetZoom() => _animateZoom(1.0);

  void _onDoubleTap() {
    if (_isZoomed) {
      _resetZoom();
    } else {
      _animateZoom(1.25);
    }
  }

  void _applyFontScale(double targetScale) {
    final clamped = targetScale.clamp(0.85, 2.0);
    _animateZoom(clamped);
    final fs = (clamped * 22.0).clamp(16.0, 36.0);
    ref.read(quranStateProvider.notifier).setFontSize(fs);
  }

  // ── Theme & Bookmark Actions ───────────────────────────────
  void _toggleTheme() {
    final current = ref.read(quranStateProvider).theme;
    final next = switch (current) {
      ReaderTheme.night => ReaderTheme.white,
      ReaderTheme.white => ReaderTheme.sepia,
      ReaderTheme.sepia => ReaderTheme.night,
    };
    ref.read(quranStateProvider.notifier).setTheme(next);
    HapticFeedback.selectionClick();
    final l10n = AppLocalizations.of(context)!;
    final name = switch (next) {
      ReaderTheme.night => l10n.quranReaderThemeNight,
      ReaderTheme.white => l10n.quranReaderThemeWhite,
      ReaderTheme.sepia => l10n.quranReaderThemeSepia,
    };
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              next == ReaderTheme.night
                  ? Icons.nightlight_round
                  : (next == ReaderTheme.white
                        ? Icons.wb_sunny_rounded
                        : Icons.menu_book_rounded),
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(fontFamily: 'Amiri')),
          ],
        ),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A5234),
      ),
    );
  }

  void _toggleBookmark() {
    final bookmarks = ref.read(quranBookmarksProvider);
    final existing = bookmarks.where((b) => b.page == _currentPage).firstOrNull;
    if (existing != null) {
      ref
          .read(quranBookmarksProvider.notifier)
          .remove(existing.surahNum, existing.ayahNum);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تمت إزالة الفاصل',
            style: TextStyle(fontFamily: 'Amiri'),
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _saveBookmark();
    }
  }

  // ── Page & Surah Navigation ────────────────────────────────
  void _onPrevPage() {
    if (_currentPage > 1) {
      ql.QuranLibrary().jumpToPage(_currentPage - 1);
    }
  }

  void _onNextPage() {
    if (_currentPage < _totalPages) {
      ql.QuranLibrary().jumpToPage(_currentPage + 1);
    }
  }

  void _jumpToSurah(int surahNum) {
    final idx = (surahNum - 1).clamp(0, kSurahData.length - 1);
    final startPage = kSurahData[idx].startPage;
    ql.QuranLibrary().jumpToPage(startPage);
  }

  void _jumpToJuz(int juzNum) {
    final targetPage = juzToPage(juzNum);
    ql.QuranLibrary().jumpToPage(targetPage);
  }

  // ── Dialogs & Sheets ───────────────────────────────────────
  void _showReadingGuide() {
    showDialog(
      context: context,
      builder: (_) => const QuranReaderGuideDialog(),
    );
  }

  void _showPageNavigation() {
    showDialog(
      context: context,
      builder: (_) => QuranReaderPageNavigationDialog(
        currentPage: _currentPage,
        totalPages: _totalPages,
        onNavigate: (page) => ql.QuranLibrary().jumpToPage(page),
      ),
    );
  }

  void _showFontSizeDialog() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuranReaderFontSizeSheet(
        currentScale: _currentScale,
        onScaleChanged: _applyFontScale,
        onReset: _resetZoom,
      ),
    );
  }

  void _showSurahPicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuranSurahPickerSheet(
        currentSurah: _surahForPage(_currentPage),
        onSelectSurah: (surah) {
          Navigator.pop(context);
          _jumpToSurah(surah.number);
        },
      ),
    );
  }

  void _showJuzPicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuranJuzPickerSheet(
        currentJuz: pageToJuz(_currentPage),
        onSelectJuz: (juz) {
          Navigator.pop(context);
          _jumpToJuz(juz);
        },
      ),
    );
  }

  void _showReciterPicker() {
    final audio = ref.read(quranAudioProvider);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuranReciterSheet(
        currentReciterId: audio.reciterId,
        onSelectReciter: (reciter) {
          Navigator.pop(context);
          ref.read(quranAudioProvider.notifier).setReciter(reciter.id);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'القارئ: ${reciter.nameAr}',
                style: const TextStyle(fontFamily: 'Amiri'),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1A5234),
            ),
          );
        },
      ),
    );
  }

  void _showDownloadSheet() {
    final surahNum = _surahForPage(_currentPage);
    final idx = (surahNum - 1).clamp(0, kSurahData.length - 1);
    final surah = kSurahData[idx];
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranDownloadSheet(
        surah: surah,
        onDownload: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'جارٍ تجهيز تلاوة سورة ${surah.nameAr} للاستماع دون إنترنت...',
                style: const TextStyle(fontFamily: 'Amiri'),
              ),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1A5234),
            ),
          );
        },
      ),
    );
  }

  void _showKhatmaStats() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranKhatmaStatsSheet(
        pagesRead: _sessionPagesRead,
        currentPage: _currentPage,
        sessionStart: _sessionStart,
      ),
    );
  }

  // Looks up the full AyahModel for (surahNum, ayahNum) from the shared
  // quran_library data — needed for the actual ayah text (share) and its
  // quran-wide unique number (deep-link/highlight). Returns null rather
  // than throwing if the library data isn't ready or the numbers are out
  // of range, so callers can fall back gracefully.
  ql.AyahModel? _findAyah(int surahNum, int ayahNum) {
    try {
      final surahs = ql.QuranLibrary.quranCtrl.surahs;
      if (surahNum < 1 || surahNum > surahs.length) return null;
      final ayahs = surahs[surahNum - 1].ayahs;
      for (final a in ayahs) {
        if (a.ayahNumber == ayahNum) return a;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _shareAyah(int surahNum, int ayahNum) {
    final l10n = AppLocalizations.of(context)!;
    final ayah = _findAyah(surahNum, ayahNum);
    final surahName = ayah?.arabicName ?? localizedSurahName(context, surahNum);
    final text = ayah?.text.trim();
    final reference = l10n.quranReaderAyahRefLabel(
      localizedNumeral(context, ayahNum),
      surahName,
    );
    final link = 'https://takwa.app/quran?surah=$surahNum&ayah=$ayahNum';
    final shareText = [
      if (text != null && text.isNotEmpty) '"$text"',
      reference,
      link,
    ].join('\n\n');
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  void _saveAyahBookmark(int surahNum, int ayahNum) {
    final ayah = _findAyah(surahNum, ayahNum);
    final surahName = ayah?.arabicName ?? localizedSurahName(context, surahNum);
    ref
        .read(quranBookmarksProvider.notifier)
        .add(
          QuranBookmark(
            surahNum: surahNum,
            ayahNum: ayahNum,
            page: ayah?.page ?? _currentPage,
            surahName: surahName,
            savedAt: DateTime.now(),
          ),
        );
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.quranReaderBookmarkSaved),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAyahOptions(int surahNum, int ayahNum) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranReaderAyahOptionsSheet(
        surahNum: surahNum,
        ayahNum: ayahNum,
        onSave: () {
          Navigator.pop(context);
          _saveAyahBookmark(surahNum, ayahNum);
        },
        onShare: () {
          Navigator.pop(context);
          _shareAyah(surahNum, ayahNum);
        },
        onTafsir: () {
          Navigator.pop(context);
          _openTafsir(surahNum, ayahNum);
        },
        onTranslation: () {
          Navigator.pop(context);
          _openTranslation(surahNum, ayahNum);
        },
        onPlay: () {
          Navigator.pop(context);
          ref
              .read(quranAudioProvider.notifier)
              .playAyah(context, surahNum, ayahNum);
        },
      ),
    );
  }

  // ── Tafsir & Translation ───────────────────────────────────
  // Both reuse quran_library's own tafsir bottom sheet (font-size controls,
  // tafsir/translation switcher already built in) — only the initially
  // selected entry differs between the two.
  Future<void> _openTafsirOrTranslation(
    int surahNum,
    int ayahNum, {
    required bool translation,
  }) async {
    final ayah = _findAyah(surahNum, ayahNum);
    if (ayah == null) return;
    // Registration is deferred off app startup (P1 #6) — await it here so
    // Al-Muyassar is in TafsirCtrl's lists before the index lookup below.
    // Idempotent and already-resolved in the common case.
    await MuyassarTafsirLoader.register();
    if (!mounted) return;
    final tafsirCtrl = ql.TafsirCtrl.instance;
    final idx = translation
        ? tafsirCtrl.tafsirAndTranslationsItems.indexWhere(
            (e) => e.isTranslation && e.fileName == 'en',
          )
        : MuyassarTafsirLoader.indexIn(tafsirCtrl);
    if (idx != -1) {
      tafsirCtrl.radioValue.value = idx;
      if (translation) tafsirCtrl.translationLangCode = 'en';
    }
    final isDark = ref.read(quranStateProvider).theme == ReaderTheme.night;
    // quran_library's own `showTafsirOnTap` is declared as `extension on
    // void`, which Dart only lets a library call unqualified from inside
    // itself — calling it through an `as ql` prefixed import (required
    // everywhere else in this file) fails to resolve at compile time. So
    // this shows the same `ShowTafseer` widget that function wraps,
    // reproducing its bottom-sheet chrome directly instead.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) => Scaffold(
        backgroundColor: Colors.transparent,
        body: ql.ShowTafseer(
          context: modalContext,
          ayahUQNumber: ayah.ayahUQNumber,
          ayahNumber: ayah.ayahNumber,
          pageIndex: ayah.page - 1,
          isDark: isDark,
        ),
      ),
    );
  }

  void _openTafsir(int surahNum, int ayahNum) =>
      _openTafsirOrTranslation(surahNum, ayahNum, translation: false);

  void _openTranslation(int surahNum, int ayahNum) =>
      _openTafsirOrTranslation(surahNum, ayahNum, translation: true);

  void _showSettings() {
    final state = ref.read(quranStateProvider);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuranReaderSettingsSheet(
        theme: state.theme,
        currentScale: _currentScale,
        onThemeChanged: (t) =>
            ref.read(quranStateProvider.notifier).setTheme(t),
        onScaleChanged: _applyFontScale,
        // Goes through _applyFontScale (not the bare _resetZoom used by the
        // double-tap gesture) so resetting here also persists fontSize back
        // to its default — otherwise the next time this reader opened, the
        // restored-on-init scale would silently undo the reset.
        onResetScale: () => _applyFontScale(1.0),
        onReciterTap: () {
          Navigator.pop(context);
          _showReciterPicker();
        },
      ),
    );
  }

  void _saveBookmark() {
    final surahNum = _surahForPage(_currentPage);
    final surahName = ql.QuranLibrary.quranCtrl.surahs[surahNum - 1].arabicName;
    ref
        .read(quranBookmarksProvider.notifier)
        .add(
          QuranBookmark(
            surahNum: surahNum,
            ayahNum: 1,
            page: _currentPage,
            surahName: surahName,
            savedAt: DateTime.now(),
          ),
        );
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.quranReaderBookmarkSaved),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Surfaces ayah-audio failures (e.g. no network) as a snackbar instead
    // of the previous silent no-op — playAyah() already resets isPlaying/
    // isLoading on failure, so without this the only sign anything went
    // wrong was the play button quietly going back to its idle state.
    ref.listen(quranAudioProvider, (prev, next) {
      if (next.hasError && prev?.hasError != true) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.quranReaderAudioError),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Only the theme is read during build (page/font-size changes come from
    // local state or `ref.read`), so watch that field alone: a whole-object
    // watch rebuilt this entire screen — the InteractiveViewer and the
    // quran_library page stack included — on every font-size tick of a
    // slider drag and on every persisted page number.
    final theme = ref.watch(quranStateProvider.select((s) => s.theme));
    final audio = ref.watch(quranAudioProvider);
    final bookmarks = ref.watch(quranBookmarksProvider);
    final juz = pageToJuz(_currentPage);
    final surahNum = _surahForPage(_currentPage);
    final isBookmarked = bookmarks.any((b) => b.page == _currentPage);

    // Theme colors
    final bgColor = switch (theme) {
      ReaderTheme.white => Colors.white,
      ReaderTheme.sepia => const Color(0xFFF4ECD8),
      ReaderTheme.night => kReaderBgDark,
    };
    final textColor = switch (theme) {
      ReaderTheme.white => Colors.black87,
      ReaderTheme.sepia => const Color(0xFF3A2810),
      ReaderTheme.night => kReaderTextWhite,
    };
    final isDark = theme == ReaderTheme.night;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // ── Background pattern ───────────────────────────
            if (isDark) const Positioned.fill(child: QuranReaderBgDecor()),

            // ── Page viewer with zoom support (preserving 15-line layout)
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _onDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.85,
                  maxScale: 2.2,
                  panEnabled: _isZoomed,
                  scaleEnabled: true,
                  clipBehavior: Clip.none,
                  child: ql.QuranLibraryScreen(
                    parentContext: context,
                    pageIndex: _initialPageIndex,
                    isDark: isDark,
                    backgroundColor: bgColor,
                    textColor: textColor,
                    useDefaultAppBar: false,
                    isShowTabBar: false,
                    isShowDisplayModeBar: false,
                    isShowAudioSlider: false,
                    onPageChanged: _onPageChanged,
                    // Tapping empty page space toggles the toolbars
                    onPagePress: _toggleToolbar,
                    onAyahLongPress: (details, ayah) => _showAyahOptions(
                      ayah.surahNumber ?? surahNum,
                      ayah.ayahNumber,
                    ),
                  ),
                ),
              ),
            ),

            // ── Floating Zoom Indicator Badge ────────────────
            if (_isZoomed)
              Positioned(
                bottom: _toolbarVisible ? 120 : 28,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _resetZoom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xE01A5234)
                            : Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kReaderGold.withValues(alpha: 0.6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in_rounded,
                            color: kReaderGold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          ValueListenableBuilder(
                            valueListenable: _transformationController,
                            builder: (context, matrix, _) => Text(
                              '${(matrix.getMaxScaleOnAxis() * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kReaderGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'إعادة ضبط',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                color: Color(0xFF0A2818),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Top toolbar ──────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _topSlide,
                child: FadeTransition(
                  opacity: _topFade,
                  child: QuranReaderTopBar(
                    surahNum: surahNum,
                    currentPage: _currentPage,
                    isDark: isDark,
                    currentTheme: theme,
                    isBookmarked: isBookmarked,
                    isAudioPlaying: audio.isPlaying,
                    onBack: () => Navigator.pop(context),
                    onThemeToggle: _toggleTheme,
                    onFontSize: _showFontSizeDialog,
                    onAudio: () => ref
                        .read(quranAudioProvider.notifier)
                        .togglePlay(context, surahNum, 1),
                    onBookmark: _toggleBookmark,
                    onGuide: _showReadingGuide,
                    onSettings: _showSettings,
                    onSurahTap: _showSurahPicker,
                  ),
                ),
              ),
            ),

            // ── Bottom bar ───────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _bottomSlide,
                child: FadeTransition(
                  opacity: _topFade,
                  child: QuranReaderBottomBar(
                    juz: juz,
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    surahNum: surahNum,
                    pagesRead: _sessionPagesRead,
                    isDark: isDark,
                    audio: audio,
                    onTogglePlay: () => ref
                        .read(quranAudioProvider.notifier)
                        .togglePlay(context, surahNum, 1),
                    onStop: () => ref.read(quranAudioProvider.notifier).stop(),
                    onSpeedTap: () {
                      const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
                      final idx = speeds.indexOf(audio.speed);
                      ref
                          .read(quranAudioProvider.notifier)
                          .setSpeed(speeds[(idx + 1) % speeds.length]);
                    },
                    onPageNav: _showPageNavigation,
                    onPrevPage: _onPrevPage,
                    onNextPage: _onNextPage,
                    onJuzNav: _showJuzPicker,
                    onKhatmaStats: _showKhatmaStats,
                    onReciter: _showReciterPicker,
                    onDownload: _showDownloadSheet,
                    onFullscreen: _toggleToolbar,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
