import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:quran_library/quran_library.dart' as ql;
import '../../data/muyassar_tafsir_loader.dart';
import '../../data/quran_data.dart';
import '../../data/quran_models.dart';
import '../../providers/quran_providers.dart';
import '../../utils/quran_helpers.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ── Color constants ──────────────────────────────────────────
const _kBgDark = Color(0xFF0D1E2D);
const _kBgGreen = Color(0xFF0A2818);
const _kGold = Color(0xFFC8A96E);
const _kGoldLight = Color(0xFFE4C98A);
const _kGreenHdr = Color(0xFF1A5234);
const _kBorderG = Color(0xFF2A7A50);
const _kTextWhite = Color(0xFFF5F0E8);
const _kTextDim = Color(0xFFB0C8B8);

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
  double _currentScale = 1.0;
  bool _isZoomed = false;

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

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _khatmaNotifier = ref.read(khatmaExProvider.notifier);

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
    _currentScale = savedScale;
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
    if (widget.startFromKhatma) {
      final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
      // Deferred to the next event-loop tick: Riverpod prohibits modifying
      // provider state synchronously during widget unmounting / dispose.
      // Calling via Future(() { ... }) avoids the assertion:
      // "Tried to modify a provider while the widget tree was building."
      Future(() {
        _khatmaNotifier.addReadingTime(elapsed);
      });
    }
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

    final surahNum = _surahForPage(p);
    final surahName = ql.QuranLibrary.quranCtrl.surahs[surahNum - 1].arabicName;
    ref
        .read(quranLastReadProvider.notifier)
        .save(
          QuranBookmark(
            surahNum: surahNum,
            ayahNum: 1,
            page: p,
            surahName: surahName,
            savedAt: DateTime.now(),
          ),
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
    if (zoomed != _isZoomed || (_currentScale - scale).abs() > 0.02) {
      setState(() {
        _isZoomed = zoomed;
        _currentScale = scale;
      });
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
    showDialog(context: context, builder: (_) => const _ReadingGuideDialog());
  }

  void _showPageNavigation() {
    showDialog(
      context: context,
      builder: (_) => _PageNavigationDialog(
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
      builder: (_) => _FontSizeSheet(
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
      builder: (_) => _SurahPickerSheet(
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
      builder: (_) => _JuzPickerSheet(
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
      builder: (_) => _ReciterSheet(
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
      builder: (_) => _DownloadSheet(
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
      builder: (_) => _KhatmaStatsSheet(
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
      builder: (_) => _AyahOptionsSheet(
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
  void _openTafsirOrTranslation(int surahNum, int ayahNum, {required bool translation}) {
    final ayah = _findAyah(surahNum, ayahNum);
    if (ayah == null) return;
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
      builder: (_) => _SettingsSheet(
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

    final state = ref.watch(quranStateProvider);
    final audio = ref.watch(quranAudioProvider);
    final bookmarks = ref.watch(quranBookmarksProvider);
    final juz = pageToJuz(_currentPage);
    final surahNum = _surahForPage(_currentPage);
    final isBookmarked = bookmarks.any((b) => b.page == _currentPage);

    // Theme colors
    final bgColor = switch (state.theme) {
      ReaderTheme.white => Colors.white,
      ReaderTheme.sepia => const Color(0xFFF4ECD8),
      ReaderTheme.night => _kBgDark,
    };
    final textColor = switch (state.theme) {
      ReaderTheme.white => Colors.black87,
      ReaderTheme.sepia => const Color(0xFF3A2810),
      ReaderTheme.night => _kTextWhite,
    };
    final isDark = state.theme == ReaderTheme.night;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // ── Background pattern ───────────────────────────
            if (isDark) Positioned.fill(child: _QuranBgDecor()),

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
                          color: _kGold.withValues(alpha: 0.6),
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
                            color: _kGold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(_currentScale * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _kGold,
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
                  child: _TopBar(
                    surahNum: surahNum,
                    currentPage: _currentPage,
                    isDark: isDark,
                    currentTheme: state.theme,
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
                  child: _BottomBar(
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

class _QuranBgDecor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _QuranBgPainter(), size: Size.infinite);
  }
}

class _QuranBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0B1E2D), Color(0xFF0A1A28), Color(0xFF0D1F2E)],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // Subtle gold geometric pattern
    final p = Paint()
      ..color = const Color.fromARGB(6, 255, 166, 0)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 80.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        _drawStar(canvas, Offset(x, y), step * 0.35, p);
      }
    }

    // Top glow
    final topGlow = RadialGradient(
      colors: [_kGreenHdr.withValues(alpha: 0.12), Colors.transparent],
    );
    canvas.drawCircle(
      Offset(size.width / 2, 0),
      size.width * 0.7,
      Paint()
        ..shader = topGlow.createShader(
          Rect.fromCircle(
            center: Offset(size.width / 2, 0),
            radius: size.width * 0.7,
          ),
        ),
    );
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    const n = 8;
    final path = Path();
    for (int i = 0; i < n * 2; i++) {
      final angle = i * 3.14159 / n;
      final dist = i.isEven ? r : r * 0.45;
      final pt = Offset(c.dx + dist * _cos(angle), c.dy + dist * _sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  double _cos(double a) => math.cos(a);
  double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_) => false;
}

class _QuranPageView extends StatelessWidget {
  final int page;
  final int Function(int) surahForPage;
  final double fontSize;
  final Color textColor, bgColor;
  final bool isDark;
  final QuranAudioState audio;
  final void Function(int, int) onAyahTap;

  const _QuranPageView({
    required this.page,
    required this.surahForPage,
    required this.fontSize,
    required this.textColor,
    required this.bgColor,
    required this.isDark,
    required this.audio,
    required this.onAyahTap,
  });

  @override
  Widget build(BuildContext context) {
    final pageAyahs = ql.QuranLibrary.quranCtrl.getPageAyahsByIndex(page - 1);
    if (pageAyahs.isEmpty) return const SizedBox();

    // Group ayahs by surah number
    final groups = <int, List<ql.AyahModel>>{};
    for (final a in pageAyahs) {
      final sNum = a.surahNumber ?? 1;
      groups.putIfAbsent(sNum, () => []).add(a);
    }
    final sortedSurahNums = groups.keys.toList()..sort();

    return Container(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.only(top: 76, bottom: 96),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: sortedSurahNums.map((sNum) {
              final surahAyahs = groups[sNum]!;
              final surahIdx = sNum - 1;
              final isSurahStart = kSurahData[surahIdx].startPage == page;
              final noBasmala = sNum == 9; // At-Tawbah is index 9 (1-based)

              return Column(
                children: [
                  if (isSurahStart) ...[
                    _SurahHeader(surahMeta: kSurahData[surahIdx]),
                    if (!noBasmala)
                      _BasmalaLine(textColor: textColor, isDark: isDark),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  _PageContent(
                    surahNum: sNum,
                    ayahs: surahAyahs,
                    fontSize: fontSize,
                    textColor: textColor,
                    audio: audio,
                    isDark: isDark,
                    onAyahTap: onAyahTap,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Surah Header (matches reference screenshots) ────────────
class _SurahHeader extends StatelessWidget {
  final SurahMeta surahMeta;
  const _SurahHeader({required this.surahMeta});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? surahMeta.nameAr : surahMeta.nameEn;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E3B), Color(0xFF0E3D26)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: _kGold.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kGreenHdr.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corner decorations
          const Positioned(
            top: 4,
            right: 8,
            child: _CornerOrnament(flip: false),
          ),
          const Positioned(top: 4, left: 8, child: _CornerOrnament(flip: true)),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: AppSpacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  surahMeta.type == 'meccan'
                      ? l10n.quranReaderMeccan
                      : l10n.quranReaderMedinan,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    color: _kGoldLight,
                  ),
                ),
                Text(
                  l10n.quranReaderSurahHeaderTitle(name),
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    color: _kGold,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Color(0x40C8A96E), blurRadius: 8)],
                  ),
                ),
                Text(
                  l10n.quranReaderAyahCountBadge(surahMeta.ayahCount),
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    color: _kGoldLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerOrnament extends StatelessWidget {
  final bool flip;
  const _CornerOrnament({required this.flip});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: const Text(
        '﴾',
        style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: _kGold),
      ),
    );
  }
}

// ── Basmala ─────────────────────────────────────────────────
class _BasmalaLine extends StatelessWidget {
  final Color textColor;
  final bool isDark;
  const _BasmalaLine({required this.textColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: AppSpacing.xxl,
      ),
      child: Text(
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22,
          color: isDark ? _kGoldLight : textColor,
          height: 1.8,
        ),
      ),
    );
  }
}

// ── Page Content ─────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final int surahNum;
  final List<ql.AyahModel> ayahs;
  final double fontSize;
  final Color textColor;
  final QuranAudioState audio;
  final bool isDark;
  final void Function(int, int) onAyahTap;

  const _PageContent({
    required this.surahNum,
    required this.ayahs,
    required this.fontSize,
    required this.textColor,
    required this.audio,
    required this.isDark,
    required this.onAyahTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text.rich(
        TextSpan(
          children: ayahs.map<InlineSpan>((a) {
            final ayahNum = a.ayahNumber;
            final isPlaying =
                audio.isPlaying &&
                audio.surah == surahNum &&
                audio.ayah == ayahNum;

            return TextSpan(
              children: [
                TextSpan(
                  text: '${a.text} ',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: fontSize,
                    color: isPlaying ? _kGold : textColor,
                    height: 2.1,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () => onAyahTap(surahNum, ayahNum),
                    onLongPress: () => onAyahTap(surahNum, ayahNum),
                    child: _AyahNumberBadge(
                      num: ayahNum,
                      isPlaying: isPlaying,
                      isDark: isDark,
                    ),
                  ),
                ),
                const TextSpan(text: '  '),
              ],
            );
          }).toList(),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

// ── Ayah number badge ────────────────────────────────────────
class _AyahNumberBadge extends StatelessWidget {
  final int num;
  final bool isPlaying, isDark;
  const _AyahNumberBadge({
    required this.num,
    required this.isPlaying,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ring = isPlaying
        ? _kGold
        : (isDark ? Colors.white24 : Colors.black26);
    final txt = isPlaying ? _kGold : (isDark ? Colors.white54 : Colors.black45);

    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPlaying ? _kGold.withValues(alpha: 0.15) : Colors.transparent,
        border: Border.all(color: ring, width: 0.8),
      ),
      child: Center(
        child: Text(
          ar(num),
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 9,
            color: txt,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int surahNum;
  final int currentPage;
  final bool isDark;
  final ReaderTheme currentTheme;
  final bool isBookmarked;
  final bool isAudioPlaying;
  final VoidCallback onBack;
  final VoidCallback onThemeToggle;
  final VoidCallback onFontSize;
  final VoidCallback onAudio;
  final VoidCallback onBookmark;
  final VoidCallback onGuide;
  final VoidCallback onSettings;
  final VoidCallback onSurahTap;

  const _TopBar({
    required this.surahNum,
    required this.currentPage,
    required this.isDark,
    required this.currentTheme,
    required this.isBookmarked,
    required this.isAudioPlaying,
    required this.onBack,
    required this.onThemeToggle,
    required this.onFontSize,
    required this.onAudio,
    required this.onBookmark,
    required this.onGuide,
    required this.onSettings,
    required this.onSurahTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overlay = isDark
        ? const Color(0xD00A2818)
        : Colors.white.withValues(alpha: 0.92);
    final fg = isDark ? Colors.white70 : Colors.black54;
    final divider = isDark ? Colors.white12 : Colors.black12;

    final themeIcon = switch (currentTheme) {
      ReaderTheme.night => Icons.nightlight_round,
      ReaderTheme.white => Icons.wb_sunny_rounded,
      ReaderTheme.sepia => Icons.menu_book_rounded,
    };
    final themeColor = switch (currentTheme) {
      ReaderTheme.night => _kGold,
      ReaderTheme.white => const Color(0xFFD97706),
      ReaderTheme.sepia => const Color(0xFF92400E),
    };

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [overlay, Colors.transparent],
              )
            : null,
        color: isDark ? null : overlay,
        border: Border(bottom: BorderSide(color: divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
          child: Row(
            children: [
              // Theme mode toggle button (dynamic icon)
              _TapIcon(
                icon: themeIcon,
                color: themeColor,
                tooltip: 'تبديل المظهر',
                onTap: onThemeToggle,
              ),
              // Font size / zoom button
              _TapIcon(
                icon: Icons.format_size_rounded,
                color: fg,
                tooltip: 'حجم الخط والصفحة',
                onTap: onFontSize,
              ),
              // Audio toggle button
              _TapIcon(
                icon: isAudioPlaying
                    ? Icons.headphones
                    : Icons.headphones_outlined,
                color: isAudioPlaying ? _kGold : fg,
                tooltip: 'الاستماع',
                badgeColor: isAudioPlaying ? _kGold : null,
                onTap: onAudio,
              ),
              // Bookmark toggle button
              _TapIcon(
                icon: isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: isBookmarked ? _kGold : fg,
                tooltip: 'فاصل القراءة',
                onTap: onBookmark,
              ),
              // Help / Guide
              _TapIcon(
                icon: Icons.help_outline_rounded,
                color: fg,
                tooltip: 'دليل القراءة',
                onTap: onGuide,
              ),
              // Settings
              _TapIcon(
                icon: Icons.tune_rounded,
                color: fg,
                tooltip: 'الإعدادات',
                onTap: onSettings,
              ),
              const Spacer(),
              // Clickable Surah name pill
              GestureDetector(
                onTap: onSurahTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? _kGold.withValues(alpha: 0.35)
                          : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: _kGold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        l10n.quranReaderSurahLabel(
                          localizedSurahName(context, surahNum),
                        ),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Right: back button
              const CustomLeadingButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? badgeColor;

  const _TapIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    // TakwaTappable is opaque by default already, matching the explicit
    // HitTestBehavior.opaque this GestureDetector used to set.
    Widget child = TakwaTappable(
      onTap: onTap,
      // A toolbar icon button, sized by its own padding rather than a
      // fixed box — see quran_widgets.dart's icon buttons for why
      // minTapSize is null here.
      minTapSize: null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Icon(icon, color: color, size: 22),
            if (badgeColor != null)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                ),
              ),
          ],
        ),
      ),
    );
    if (tooltip != null) {
      child = Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

class _BottomBar extends StatelessWidget {
  final int juz, currentPage, totalPages, surahNum, pagesRead;
  final bool isDark;
  final QuranAudioState audio;
  final VoidCallback onTogglePlay;
  final VoidCallback onStop;
  final VoidCallback onSpeedTap;
  final VoidCallback onPageNav;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onJuzNav;
  final VoidCallback onKhatmaStats;
  final VoidCallback onReciter;
  final VoidCallback onDownload;
  final VoidCallback onFullscreen;

  const _BottomBar({
    required this.juz,
    required this.currentPage,
    required this.totalPages,
    required this.surahNum,
    required this.pagesRead,
    required this.isDark,
    required this.audio,
    required this.onTogglePlay,
    required this.onStop,
    required this.onSpeedTap,
    required this.onPageNav,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onJuzNav,
    required this.onKhatmaStats,
    required this.onReciter,
    required this.onDownload,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark
        ? const Color(0xF00A2818)
        : Colors.white.withValues(alpha: 0.95);
    final textDim = isDark ? Colors.white54 : Colors.black45;
    final border = isDark ? Colors.white10 : Colors.black12;

    const khatmaPages = 12;
    final readCount = pagesRead.clamp(0, khatmaPages);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [bg, Colors.transparent],
              )
            : null,
        color: isDark ? null : bg,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Progress row with navigation ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Juz chip (tap opens Juz jump sheet)
                  GestureDetector(
                    onTap: onJuzNav,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _infoChip(
                            l10n.quranReaderJuzChip(
                              localizedNumeral(context, juz),
                            ),
                            isDark ? _kGoldLight : const Color(0xFF1A5234),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: textDim,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center: Prev/Next step buttons + Page of Total
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // In RTL Mushaf: Next page is to the left (chevron_left)
                      _navArrow(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'الصفحة التالية',
                        color: currentPage < totalPages
                            ? textDim
                            : Colors.transparent,
                        onTap: currentPage < totalPages ? onNextPage : null,
                      ),
                      GestureDetector(
                        onTap: onPageNav,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                          child: _infoChip(
                            l10n.quranReaderPageOfTotalChip(
                              localizedNumeral(context, currentPage),
                              localizedNumeral(context, totalPages),
                            ),
                            isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      // In RTL Mushaf: Previous page is to the right (chevron_right)
                      _navArrow(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'الصفحة السابقة',
                        color: currentPage > 1 ? textDim : Colors.transparent,
                        onTap: currentPage > 1 ? onPrevPage : null,
                      ),
                    ],
                  ),

                  // Khatma read count chip (tap opens Khatma stats)
                  GestureDetector(
                    onTap: onKhatmaStats,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _infoChip(
                            l10n.quranReaderReadCountChip(
                              localizedNumeral(context, readCount),
                              localizedNumeral(context, khatmaPages),
                            ),
                            textDim,
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 13,
                            color: textDim,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 6,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: readCount / khatmaPages,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(_kGreenHdr),
                  minHeight: 3,
                ),
              ),
            ),

            // ── Audio controls row ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    // Left icons: Reciter selection, Download, Fullscreen
                    _audioIcon(
                      Icons.person_outline_rounded,
                      textDim,
                      onReciter,
                      tooltip: 'اختيار القارئ',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _audioIcon(
                      Icons.download_outlined,
                      textDim,
                      onDownload,
                      tooltip: 'تحميل التلاوة',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _audioIcon(
                      Icons.fit_screen_outlined,
                      textDim,
                      onFullscreen,
                      tooltip: 'وضع ملء الشاشة',
                    ),
                    const Spacer(),

                    // Play/pause button
                    TakwaTappable(
                      onTap: onTogglePlay,
                      // Sits in a fixed-height audio toolbar row — see
                      // quran_widgets.dart's icon buttons for why
                      // minTapSize is null here.
                      minTapSize: null,
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: audio.isLoading ? Colors.white24 : _kGreenHdr,
                          boxShadow: [
                            BoxShadow(
                              color: _kGreenHdr.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: audio.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: TakwaLoadingIndicator(size: 24),
                              )
                            : Icon(
                                audio.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Surah & Ayah info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          localizedSurahName(context, surahNum),
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          '${localizedSurahName(context, audio.surah)}: ${localizedNumeral(context, audio.ayah)}',
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 11,
                            color: textDim,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Speed control
                    GestureDetector(
                      onTap: onSpeedTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: textDim),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '${audio.speed}x',
                          style: TextStyle(
                            color: textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Stop
                    TakwaTappable(
                      onTap: onStop,
                      minTapSize: null,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        child: Icon(
                          Icons.stop_rounded,
                          color: textDim,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navArrow({
    required IconData icon,
    required String tooltip,
    required Color color,
    VoidCallback? onTap,
  }) => Tooltip(
    message: tooltip,
    // No semanticLabel: the Tooltip above already contributes one.
    child: TakwaTappable(
      onTap: onTap,
      minTapSize: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(icon, size: 22, color: color),
      ),
    ),
  );

  Widget _infoChip(String text, Color color) => Text(
    text,
    style: TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 11, color: color),
  );

  Widget _audioIcon(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    Widget btn = TakwaTappable(
      onTap: onTap,
      minTapSize: null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(icon, color: color, size: 20),
      ),
    );
    if (tooltip != null) {
      // No semanticLabel on the tappable above: this Tooltip supplies one.
      btn = Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }
}

class _ReadingGuideDialog extends StatelessWidget {
  const _ReadingGuideDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xxl),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A5234),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📖', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.quranReaderGuideTitle,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Guide items
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  _GuideItem(emoji: '👆', text: l10n.quranReaderGuideTapToggle),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '👆👆',
                    text: l10n.quranReaderGuideDoubleTapZoom,
                  ),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '👈',
                    text: l10n.quranReaderGuideSwipeNavigate,
                  ),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '📌',
                    text: l10n.quranReaderGuideLongPress,
                    subItems: [
                      l10n.quranReaderGuideSaveAyah,
                      l10n.quranReaderGuideShareAyah,
                      l10n.quranReaderGuideTafsir,
                      l10n.quranReaderGuideTranslation,
                      l10n.quranReaderGuideListen,
                    ],
                  ),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '🎧',
                    text: l10n.quranReaderGuideAudioButton,
                  ),
                  const SizedBox(height: 10),
                  _GuideItem(
                    emoji: '🌙',
                    text: l10n.quranReaderGuideNightModeButton,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Got it button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      l10n.quranReaderGuideGotIt,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A5234),
                      ),
                    ),
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

class _GuideItem extends StatelessWidget {
  final String emoji, text;
  final List<String>? subItems;
  const _GuideItem({required this.emoji, required this.text, this.subItems});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              if (subItems != null)
                ...subItems!.map(
                  (s) => Padding(
                    padding: const EdgeInsetsDirectional.only(top: 3, end: 8),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageNavigationDialog extends StatefulWidget {
  final int currentPage, totalPages;
  final void Function(int) onNavigate;

  const _PageNavigationDialog({
    required this.currentPage,
    required this.totalPages,
    required this.onNavigate,
  });

  @override
  State<_PageNavigationDialog> createState() => _PageNavigationDialogState();
}

class _PageNavigationDialogState extends State<_PageNavigationDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _navigate() {
    final val = int.tryParse(_ctrl.text);
    if (val == null || val < 1 || val > widget.totalPages) {
      setState(
        () => _error = AppLocalizations.of(context)!.quranReaderPageJumpError(
          localizedNumeral(context, widget.totalPages),
        ),
      );
      return;
    }
    widget.onNavigate(val);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2D3E),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TakwaTappable(
                  onTap: () => Navigator.pop(context),
                  // Inline with the dialog title via spaceBetween.
                  minTapSize: null,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white38,
                    size: 20,
                  ),
                ),
                Text(
                  l10n.quranReaderGoToPageTitle,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.quranReaderCurrentPageLabel(
                localizedNumeral(context, widget.currentPage),
              ),
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 13,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.quranReaderPageInputLabel(
                l10n.quranReaderPageRangeHint(
                  localizedNumeral(context, widget.totalPages),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 12,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 14),
            // Input
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: l10n.quranReaderPageRangeHint(
                  localizedNumeral(context, widget.totalPages),
                ),
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                errorText: _error,
                errorStyle: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 11,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Center(
                        child: Text(
                          l10n.quranReaderCancelButton,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _navigate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A5234),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1A5234,
                            ).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          l10n.quranReaderGoButton,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahOptionsSheet extends StatelessWidget {
  final int surahNum, ayahNum;
  final VoidCallback onSave, onShare, onTafsir, onTranslation, onPlay;

  const _AyahOptionsSheet({
    required this.surahNum,
    required this.ayahNum,
    required this.onSave,
    required this.onShare,
    required this.onTafsir,
    required this.onTranslation,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surahName = localizedSurahName(context, surahNum);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1E2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.quranReaderAyahRefLabel(
              localizedNumeral(context, ayahNum),
              surahName,
            ),
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 17,
              color: _kGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),
          _OptionRow(
            emoji: '⭐',
            label: l10n.quranReaderSaveAyahOption,
            onTap: onSave,
          ),
          _OptionRow(
            emoji: '📤',
            label: l10n.quranReaderShareAyahOption,
            onTap: onShare,
          ),
          _OptionRow(
            emoji: '📖',
            label: l10n.quranReaderTafsirOption,
            onTap: onTafsir,
          ),
          _OptionRow(
            emoji: '🌐',
            label: l10n.quranReaderTranslationOption,
            onTap: onTranslation,
          ),
          _OptionRow(
            emoji: '🔊',
            label: l10n.quranReaderListenAyahOption,
            onTap: onPlay,
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _OptionRow({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: Colors.white24,
              size: 18,
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(emoji, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  final ReaderTheme theme;
  final double currentScale;
  final ValueChanged<ReaderTheme> onThemeChanged;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onResetScale;
  final VoidCallback onReciterTap;

  const _SettingsSheet({
    required this.theme,
    required this.currentScale,
    required this.onThemeChanged,
    required this.onScaleChanged,
    required this.onResetScale,
    required this.onReciterTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: Color(0xFF0D3A26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.quranReaderSettingsTitle,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              color: _kGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Theme Selection ───────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.quranReaderBackgroundStyleLabel,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: ReaderTheme.values.map((t) {
              final labels = {
                'night': l10n.quranReaderThemeNight,
                'sepia': l10n.quranReaderThemeSepia,
                'white': l10n.quranReaderThemeWhite,
              };
              final selected = theme == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onThemeChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? _kGold : Colors.white10,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: selected ? _kGoldLight : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labels[t.name] ?? t.name,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          color: selected
                              ? const Color(0xFF0D3A26)
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Font Size & Zoom ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onResetScale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'إعادة ضبط',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: _kGoldLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Text(
                'حجم الخط والصفحة (${(currentScale * 100).round()}%)',
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _scaleBtn(
                label: 'A-',
                tooltip: 'تصغير',
                onTap: () => onScaleChanged(currentScale - 0.08),
              ),
              Expanded(
                child: Slider(
                  value: currentScale.clamp(0.85, 1.6),
                  min: 0.85,
                  max: 1.6,
                  activeColor: _kGold,
                  inactiveColor: Colors.white24,
                  onChanged: onScaleChanged,
                ),
              ),
              _scaleBtn(
                label: 'A+',
                tooltip: 'تكبير',
                onTap: () => onScaleChanged(currentScale + 0.08),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Reciter selection button ──────────────────
          GestureDetector(
            onTap: onReciterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chevron_left, color: Colors.white38),
                  Spacer(),
                  Text(
                    'تغيير القارئ الصوتي',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.record_voice_over_outlined,
                    color: _kGold,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scaleBtn({
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}

// ─── Font Size & Page Zoom Sheet ─────────────────────────────
class _FontSizeSheet extends StatefulWidget {
  final double currentScale;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onReset;

  const _FontSizeSheet({
    required this.currentScale,
    required this.onScaleChanged,
    required this.onReset,
  });

  @override
  State<_FontSizeSheet> createState() => _FontSizeSheetState();
}

class _FontSizeSheetState extends State<_FontSizeSheet> {
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = widget.currentScale;
  }

  void _update(double val) {
    final clamped = val.clamp(0.85, 1.6);
    setState(() => _scale = clamped);
    widget.onScaleChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_scale * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2F20),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  widget.onReset();
                  setState(() => _scale = 1.0);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    'الوضع الافتراضي (100%)',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: _kGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Text(
                'حجم الخط والصفحة: $percent%',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 19,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Presets row
          Row(
            children: [
              _presetChip('85%', 0.85),
              const SizedBox(width: 6),
              _presetChip('100%', 1.0),
              const SizedBox(width: 6),
              _presetChip('115%', 1.15),
              const SizedBox(width: 6),
              _presetChip('130%', 1.30),
              const SizedBox(width: 6),
              _presetChip('150%', 1.50),
            ],
          ),

          const SizedBox(height: 22),

          // Slider row with A- and A+ steppers
          Row(
            children: [
              GestureDetector(
                onTap: () => _update(_scale - 0.05),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Center(
                    child: Text(
                      'A-',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18,
                    ),
                  ),
                  child: Slider(
                    value: _scale.clamp(0.85, 1.6),
                    min: 0.85,
                    max: 1.6,
                    activeColor: _kGold,
                    inactiveColor: Colors.white24,
                    onChanged: _update,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _update(_scale + 0.05),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Center(
                    child: Text(
                      'A+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Informational note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _kGold, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يحافظ التكبير على أسطر صفحة المصحف الـ 15 كاملة دون أي اختلال في رسم المصحف الشريف.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, double val) {
    final selected = (_scale - val).abs() < 0.04;
    return Expanded(
      child: GestureDetector(
        onTap: () => _update(val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _kGold : Colors.white10,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? _kGoldLight : Colors.white12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF0A2818) : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Surah Picker Sheet ──────────────────────────────────────
class _SurahPickerSheet extends StatefulWidget {
  final int currentSurah;
  final ValueChanged<SurahMeta> onSelectSurah;

  const _SurahPickerSheet({
    required this.currentSurah,
    required this.onSelectSurah,
  });

  @override
  State<_SurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<_SurahPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kSurahData.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.nameAr.contains(q) ||
          s.nameEn.toLowerCase().contains(q) ||
          s.number.toString() == q;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          const Text(
            'فهرس سور القرآن الكريم',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kGold,
            ),
          ),
          const SizedBox(height: 12),

          // Search field
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: const TextStyle(fontFamily: 'Amiri', color: Colors.white),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'ابحث باسم السورة أو رقمها...',
              hintStyle: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                color: Colors.white38,
                fontSize: 13,
              ),
              prefixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Surah list
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (ctx, idx) {
                final surah = filtered[idx];
                final isCurrent = surah.number == widget.currentSurah;
                return ListTile(
                  onTap: () => widget.onSelectSurah(surah),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? _kGold
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ص ${surah.startPage}',
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 11,
                        color: isCurrent
                            ? const Color(0xFF0F261C)
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    surah.nameAr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? _kGoldLight : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${surah.type == 'meccan' ? 'مكية' : 'مدنية'} • ${surah.ayahCount} آيات • الجزء ${surah.juzNumber}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                  trailing: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? _kGold : Colors.white24,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${surah.number}',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? _kGold : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Juz Picker Sheet ────────────────────────────────────────
class _JuzPickerSheet extends StatelessWidget {
  final int currentJuz;
  final ValueChanged<int> onSelectJuz;

  const _JuzPickerSheet({required this.currentJuz, required this.onSelectJuz});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2A1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'أجزاء القرآن الكريم',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kGold,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: 30,
              itemBuilder: (ctx, idx) {
                final juzNum = idx + 1;
                final startPage = juzToPage(juzNum);
                final isSelected = juzNum == currentJuz;
                return GestureDetector(
                  onTap: () => onSelectJuz(juzNum),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? _kGold : Colors.white10,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? _kGoldLight : Colors.white12,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'الجزء $juzNum',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF0A2818)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'صفحة $startPage',
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 11,
                            color: isSelected
                                ? const Color(0xFF0A2818).withValues(alpha: 0.8)
                                : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reciter Picker Sheet ────────────────────────────────────
class _ReciterSheet extends StatelessWidget {
  final String currentReciterId;
  final ValueChanged<QuranReciter> onSelectReciter;

  const _ReciterSheet({
    required this.currentReciterId,
    required this.onSelectReciter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'اختيار القارئ الصوتي',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kGold,
            ),
          ),
          const SizedBox(height: 14),
          ...kDefaultReciters.map((r) {
            final isSelected = r.id == currentReciterId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _kGold.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? _kGold : Colors.white12),
              ),
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  onTap: () => onSelectReciter(r),
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? _kGold : Colors.white38,
                  ),
                  title: Text(
                    r.nameAr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  subtitle: Text(
                    r.nameEn,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Download Audio Sheet ────────────────────────────────────
class _DownloadSheet extends StatelessWidget {
  final SurahMeta surah;
  final VoidCallback onDownload;

  const _DownloadSheet({required this.surah, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تحميل سورة ${surah.nameAr}',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kGold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'عدد الآيات: ${surah.ayahCount} • الحجم التقديري: ~${(surah.ayahCount * 0.08).toStringAsFixed(1)} ميجابايت',
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onDownload,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5234),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A5234).withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'تحميل السورة للاستماع دون إنترنت',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Khatma Stats Sheet ──────────────────────────────────────
class _KhatmaStatsSheet extends StatelessWidget {
  final int pagesRead;
  final int currentPage;
  final DateTime sessionStart;

  const _KhatmaStatsSheet({
    required this.pagesRead,
    required this.currentPage,
    required this.sessionStart,
  });

  @override
  Widget build(BuildContext context) {
    final elapsedMinutes = DateTime.now().difference(sessionStart).inMinutes;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'إحصائيات جلسة القراءة',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kGold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _statCard(
                'الصفحات المقروءة',
                '$pagesRead صفحة',
                Icons.menu_book_rounded,
              ),
              const SizedBox(width: 10),
              _statCard(
                'مدة القراءة',
                '$elapsedMinutes دقيقة',
                Icons.timer_outlined,
              ),
              const SizedBox(width: 10),
              _statCard(
                'الصفحة الحالية',
                '$currentPage / 604',
                Icons.auto_stories_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: const Center(
                child: Text(
                  'إغلاق',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kGold, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    ),
  );
}
