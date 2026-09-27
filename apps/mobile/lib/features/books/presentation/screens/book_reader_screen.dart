import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/books/data/book_prefs_repository.dart';
import 'package:takwa/features/books/data/books_data.dart';
import 'package:takwa/features/books/presentation/screens/book_pdf_reader_screen.dart';
import 'package:takwa/features/books/providers/books_reading_provider.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Reader colour pair for a [ReaderTheme]. Shared by the page body and the
/// chrome so background, text and bars cannot drift apart.
Color readerBackground(ReaderTheme theme) => switch (theme) {
  ReaderTheme.light => Colors.white,
  ReaderTheme.sepia => const Color(0xFFF4ECD8),
  ReaderTheme.dark => const Color(0xFF121212),
};

Color readerForeground(ReaderTheme theme) => switch (theme) {
  ReaderTheme.light => const Color(0xFF2D2D2D),
  ReaderTheme.sepia => const Color(0xFF5B4636),
  ReaderTheme.dark => const Color(0xFFE0E0E0),
};

/// Inline text reader.
///
/// A chapter scrolls as one continuous list instead of one
/// `SingleChildScrollView` per page: pages are laid out lazily, prev/next
/// animate the viewport to the neighbouring page, and the reading position
/// comes from where the scroll actually is. That keeps a long chapter cheap to
/// scroll and fixes the old behaviour where the scroll offset carried over from
/// one page to the next.
class BookReaderScreen extends ConsumerStatefulWidget {
  final IslamicBook book;
  final int initialChapterIndex;
  final int initialPageIndex;

  const BookReaderScreen({
    super.key,
    required this.book,
    this.initialChapterIndex = 0,
    this.initialPageIndex = 0,
  });

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Reading starts below the top bar; the same inset anchors which page is
  /// considered current. Refreshed from the device padding in [build] so a
  /// notch never puts text under the chrome.
  double _topInset = 96.0;
  static const _bottomInset = 132.0;
  double get _anchorLine => _topInset + 8;

  /// Chapters carrying text, in book order. Empty chapters are skipped rather
  /// than opened and found blank.
  late final List<int> _chapterOrder;

  /// Index into [_chapterOrder].
  int _slot = 0;
  int _chapterIdx = 0;
  List<BookPage> _pages = const [];
  List<GlobalKey> _pageKeys = const [];

  final _scrollCtrl = ScrollController();
  final _scrollKey = GlobalKey();

  ReadingProgressNotifier? _progress;

  /// Current page, published to the chrome only. The list never rebuilds
  /// because of it, which is what keeps scrolling smooth.
  final _pageNotifier = ValueNotifier<int>(0);

  Timer? _saveDebounce;

  /// Page targeted by an in-flight turn, while the viewport is still moving
  /// there. Scroll ticks report the *previous* frame's geometry, so anchoring
  /// during a turn drags the page read-out (and the next tap's target) back to
  /// the page being left — which is how a fast double tap used to turn one
  /// page instead of two.
  int? _turnTarget;
  Timer? _turnTimer;

  int _generation = 0;
  bool _showUI = true;
  late AnimationController _uiAnim;
  late Animation<double> _uiFade;

  bool get _hasContent => _pages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Captured here because `ref` is already unusable by the time [dispose]
    // runs, and that flush is what keeps a mid-chapter exit from losing the
    // page the reader is on.
    _progress = ref.read(readingProgressProvider.notifier);
    _chapterOrder = _readableChapters(widget.book);
    if (_chapterOrder.isNotEmpty) {
      _slot = _slotForChapter(widget.initialChapterIndex);
      _applyChapter(_chapterOrder[_slot], widget.initialPageIndex);
    }

    _uiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _uiFade = CurvedAnimation(parent: _uiAnim, curve: Curves.easeInOut);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pages.isEmpty) return;
      _scrollToPage(_pageNotifier.value, animate: false);
      _flushProgress();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounce?.cancel();
    _turnTimer?.cancel();
    // The reader is usually closed mid-chapter: flush before tearing down.
    if (_chapterOrder.isNotEmpty) _flushProgress();
    _uiAnim.dispose();
    _pageNotifier.dispose();
    _scrollCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _saveDebounce?.cancel();
      _flushProgress();
    }
  }

  // ── Position bookkeeping ─────────────────────────────────────

  static List<int> _readableChapters(IslamicBook book) {
    final indices = <int>[];
    for (var i = 0; i < book.chapters.length; i++) {
      if (book.chapters[i].pages.isNotEmpty) indices.add(i);
    }
    return indices;
  }

  /// Slot whose chapter is [chapterIndex], or the next one carrying text.
  int _slotForChapter(int chapterIndex) {
    for (var i = 0; i < _chapterOrder.length; i++) {
      if (_chapterOrder[i] >= chapterIndex) return i;
    }
    return _chapterOrder.length - 1;
  }

  void _applyChapter(int chapterIndex, int page) {
    final chapter = widget.book.chapters[chapterIndex];
    _chapterIdx = chapterIndex;
    _pages = chapter.pages;
    _pageKeys = List.generate(_pages.length, (_) => GlobalKey());
    _turnTimer?.cancel();
    _turnTarget = null;
    _pageNotifier.value = clampPageIndex(_pages.length, page);
  }

  /// Pages before the current position, across the whole book.
  int _pagesReadAt(int page) {
    var done = 0;
    for (final chapter in _chapterOrder) {
      if (chapter >= _chapterIdx) break;
      done += widget.book.chapters[chapter].pages.length;
    }
    return done + page + 1;
  }

  void _flushProgress() {
    if (_chapterOrder.isEmpty) return;
    _progress?.save(widget.book.id, _chapterIdx, _pageNotifier.value);
  }

  /// Coalesces scroll-driven writes: a fling across twenty pages should not
  /// enqueue twenty Drift upserts and twenty network calls.
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () {
      _saveDebounce = null;
      if (mounted) _flushProgress();
    });
  }

  // ── Scrolling ────────────────────────────────────────────────

  /// Defers anchor-based re-anchoring until the viewport has settled, then
  /// reconciles with the position actually reached.
  void _beginTurn(int target, {required bool animate}) {
    _turnTarget = target;
    _turnTimer?.cancel();
    _turnTimer = Timer(
      animate
          ? const Duration(milliseconds: 420)
          : const Duration(milliseconds: 80),
      _endTurn,
    );
  }

  void _endTurn() {
    _turnTimer = null;
    if (!mounted) return;
    // Reconcile after layout, never during a scroll tick: ticks report the
    // previous frame's geometry, which would put the anchor line back on the
    // page the turn left.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _turnTarget = null;
      _applyAnchor();
    });
  }

  /// Publishes the page under the anchor line, persisting the move if the
  /// viewport ended somewhere other than the announced page.
  void _applyAnchor() {
    final anchored = _anchoredPage();
    if (anchored != _pageNotifier.value) {
      _pageNotifier.value = anchored;
      _scheduleSave();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth > 0 || !_hasContent) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }
    final target = _turnTarget;
    if (target != null) {
      final userDragging =
          notification is ScrollUpdateNotification &&
          notification.dragDetails != null;
      if (!userDragging && _anchoredPage() != target) return false;
      _turnTimer?.cancel();
      _turnTarget = null;
    }
    _applyAnchor();
    return false;
  }

  /// Walks outwards from the last known page to find the card under the anchor
  /// line. Amortised O(1): consecutive frames differ by a few items at most,
  /// and only laid-out children report geometry.
  int _anchoredPage() {
    if (_pageKeys.isEmpty) return 0;
    final viewport = _scrollKey.currentContext;
    var i = _pageNotifier.value.clamp(0, _pageKeys.length - 1);

    for (var guard = 0; guard <= _pageKeys.length; guard++) {
      if (i <= 0) {
        final first = _pageKeys[0].currentContext;
        final top = first == null ? null : _topOf(first, viewport);
        if (top == null) return 0;
        if (top + (first!.size?.height ?? 0) > _anchorLine) return 0;
        i = 1;
        continue;
      }
      if (i >= _pageKeys.length) return _pageKeys.length - 1;

      final ctx = _pageKeys[i].currentContext;
      if (ctx == null) return i; // Outside the cache window: keep last known.
      final top = _topOf(ctx, viewport);
      if (top == null) return i;
      if (top > _anchorLine) {
        i--;
        continue;
      }
      if (top + (ctx.size?.height ?? 0) <= _anchorLine) {
        i++;
        continue;
      }
      return i;
    }
    return i;
  }

  double? _topOf(BuildContext context, BuildContext? viewport) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject
        .localToGlobal(Offset.zero, ancestor: viewport?.findRenderObject())
        .dy;
  }

  void _scrollToPage(int page, {bool animate = true}) {
    if (!_scrollCtrl.hasClients || !_hasContent) return;
    final position = _scrollCtrl.position;
    final viewport = _scrollKey.currentContext;
    final target = page.clamp(0, _pages.length - 1);
    final ctx = _pageKeys[target].currentContext;

    if (ctx != null) {
      final top = _topOf(ctx, viewport);
      if (top != null) {
        final offset = (position.pixels + top - _anchorLine).clamp(
          0.0,
          position.maxScrollExtent,
        );
        if (animate) {
          position.animateTo(
            offset,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        } else {
          position.jumpTo(offset);
        }
        _beginTurn(target, animate: animate);
        if (_pageNotifier.value != target) {
          _pageNotifier.value = target;
          _scheduleSave();
        }
        return;
      }
    }

    // Not laid out yet (a deep restore, or a far jump): move to a
    // proportional guess, then correct once the child has been built.
    final lastIndex = _pages.length - 1;
    final estimate = lastIndex <= 0
        ? 0.0
        : (position.maxScrollExtent * (target / lastIndex)).clamp(
            0.0,
            position.maxScrollExtent,
          );
    position.jumpTo(estimate);
    _beginTurn(target, animate: animate);
    if (_pageNotifier.value != target) {
      _pageNotifier.value = target;
      _scheduleSave();
    }
    _refineScrollTo(target, _generation, attempts: 4);
  }

  void _refineScrollTo(int page, int generation, {required int attempts}) {
    if (attempts <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A chapter switch invalidates the pending correction.
      if (!mounted || generation != _generation) return;
      if (page >= _pages.length) return;
      if (_pageKeys[page].currentContext == null) {
        _refineScrollTo(page, generation, attempts: attempts - 1);
        return;
      }
      _scrollToPage(page, animate: false);
    });
  }

  // ── Navigation ───────────────────────────────────────────────

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    if (_showUI) {
      _uiAnim.forward();
    } else {
      _uiAnim.reverse();
    }
  }

  void _goNext() {
    if (_pageNotifier.value < _pages.length - 1) {
      _scrollToPage(_pageNotifier.value + 1);
      return;
    }
    _openSlot(_slot + 1, page: 0);
  }

  void _goPrev() {
    if (_pageNotifier.value > 0) {
      _scrollToPage(_pageNotifier.value - 1);
      return;
    }
    if (_slot == 0) {
      _scrollToPage(0);
      return;
    }
    final previous = widget.book.chapters[_chapterOrder[_slot - 1]];
    _openSlot(_slot - 1, page: previous.pages.length - 1);
  }

  /// Switches the visible chapter — used by page turns past the ends and by
  /// the chapter jump sheet.
  void _openSlot(int slot, {required int page}) {
    if (_chapterOrder.isEmpty) return;
    final nextSlot = slot.clamp(0, _chapterOrder.length - 1);
    final chapterIndex = _chapterOrder[nextSlot];
    if (chapterIndex == _chapterIdx && nextSlot == _slot) {
      _scrollToPage(clampPageIndex(_pages.length, page));
      return;
    }

    _generation++;
    _turnTimer?.cancel();
    _turnTarget = null;
    setState(() {
      _slot = nextSlot;
      _applyChapter(chapterIndex, page);
    });
    final target = _pageNotifier.value;
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      _scrollToPage(target, animate: false);
    });
    _flushProgress();
  }

  void _jumpToBookmark(BookBookmark bookmark) {
    if (_chapterOrder.isEmpty) return;
    final slot = _slotForChapter(bookmark.chapterIndex);
    if (_chapterOrder[slot] == bookmark.chapterIndex) {
      _scrollToPage(clampPageIndex(_pages.length, bookmark.pageIndex));
      return;
    }
    _openSlot(slot, page: bookmark.pageIndex);
  }

  // ── Chrome actions ───────────────────────────────────────────

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ReaderSettingsSheet(
        book: widget.book,
        onThemeChange: (theme) {
          ref.read(readerThemeProvider.notifier).select(theme);
        },
        onFontSizeSelect: (level) {
          ref.read(bookFontSizeProvider.notifier).setLevel(level);
        },
        onJumpToBookmark: (bookmark) {
          Navigator.pop(context);
          _jumpToBookmark(bookmark);
        },
      ),
    );
  }

  Future<void> _toggleBookmark() async {
    if (_chapterOrder.isEmpty || _pages.isEmpty) return;
    final page = _pageNotifier.value;
    final notifier = ref.read(bookBookmarksProvider.notifier);
    final wasMarked = notifier.contains(widget.book.id, _chapterIdx, page);
    if (wasMarked) {
      await notifier.remove(widget.book.id, _bookmarkAt(page));
    } else {
      await notifier.toggle(widget.book.id, _bookmarkAt(page));
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasMarked
              ? l10n.bookReaderBookmarkRemovedToast
              : l10n.bookReaderBookmarkSavedToast,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  BookBookmark _bookmarkAt(int page) => BookBookmark(
    chapterIndex: _chapterIdx,
    pageIndex: page.clamp(0, _pages.length - 1),
    createdAt: DateTime.now(),
    excerpt: _excerptFor(_pages[page.clamp(0, _pages.length - 1)]),
  );

  void _openChapterList() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChapterJumpSheet(
        book: widget.book,
        chapterOrder: _chapterOrder,
        currentChapter: _chapterIdx,
        onSelect: (slot) {
          Navigator.pop(context);
          _openSlot(slot, page: 0);
        },
      ),
    );
  }

  static String _excerptFor(BookPage page) {
    final source = page.title?.isNotEmpty == true ? page.title! : page.content;
    final flattened = source.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flattened.length <= 60
        ? flattened
        : '${flattened.substring(0, 60)}…';
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _topInset = MediaQuery.paddingOf(context).top + 72;
    final fontSizeLevel = ref.watch(bookFontSizeProvider);
    final theme = ref.watch(readerThemeProvider);
    final bookmarks = ref.watch(bookBookmarksProvider);
    final bodyFontSize = scaledFontSize(context, fontSizeLevel);

    final bgColor = readerBackground(theme);
    final textColor = readerForeground(theme);
    final accentColor = widget.book.accentColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: _toggleUI,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            if (theme == ReaderTheme.sepia)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.03,
                    child: Image.asset(
                      'assets/images/pattern_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              ),

            Positioned.fill(
              child: _hasContent
                  ? _buildReader(accentColor, textColor, bodyFontSize, theme)
                  : _buildUnavailable(accentColor, textColor),
            ),

            if (_hasContent) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _uiFade,
                  child: IgnorePointer(
                    ignoring: !_showUI,
                    child: _TopBar(
                      book: widget.book,
                      chapter: widget.book.chapters[_chapterIdx],
                      accentColor: accentColor,
                      theme: theme,
                      pageNotifier: _pageNotifier,
                      isBookmarked: (page) => _isBookmarked(bookmarks, page),
                      onBookmarkToggle: _toggleBookmark,
                      onOpenChapters: _openChapterList,
                      onOpenSettings: _openSettings,
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _uiFade,
                  child: IgnorePointer(
                    ignoring: !_showUI,
                    child: _BottomNav(
                      totalPages: widget.book.totalPages,
                      chapter: widget.book.chapters[_chapterIdx],
                      pagesReadAt: _pagesReadAt,
                      accentColor: accentColor,
                      theme: theme,
                      pageNotifier: _pageNotifier,
                      hasPrevious: (page) => _slot > 0 || page > 0,
                      hasNext: (page) =>
                          _slot < _chapterOrder.length - 1 ||
                          page < _pages.length - 1,
                      onPrev: _goPrev,
                      onNext: _goNext,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isBookmarked(Map<String, List<BookBookmark>> table, int page) {
    final entries = table[widget.book.id];
    if (entries == null) return false;
    return entries.any(
      (b) => b.chapterIndex == _chapterIdx && b.pageIndex == page,
    );
  }

  Widget _buildReader(
    Color accentColor,
    Color textColor,
    double bodyFontSize,
    ReaderTheme theme,
  ) {
    final chapter = widget.book.chapters[_chapterIdx];
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: CustomScrollView(
        key: _scrollKey,
        controller: _scrollCtrl,
        // Pre-lays a few pages in each direction so a fling never stalls on
        // layout, without keeping the whole chapter alive.
        scrollCacheExtent: const ScrollCacheExtent.pixels(1200),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(24, _topInset, 24, _bottomInset),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == 0) {
                  return _ChapterHeader(
                    chapter: chapter,
                    accentColor: accentColor,
                  );
                }
                final pageIndex = index - 1;
                return RepaintBoundary(
                  key: _pageKeys[pageIndex],
                  child: _ReaderPage(
                    page: _pages[pageIndex],
                    accentColor: accentColor,
                    textColor: textColor,
                    bodyFontSize: bodyFontSize,
                    theme: theme,
                  ),
                );
              }, childCount: _pages.length + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailable(Color accentColor, Color textColor) {
    final l10n = AppLocalizations.of(context)!;
    final hasPdf = widget.book.pdfUrl != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IslamicGlyph(widget.book.emoji, size: 44, badge: null),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.bookReaderContentUnavailable,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 17,
                color: textColor,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            if (hasPdf) ...[
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookPdfReaderScreen(book: widget.book),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: Text(l10n.booksChapterReadPdfButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  CHAPTER HEADER + PAGE
// ─────────────────────────────────────────

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({required this.chapter, required this.accentColor});

  final BookChapter chapter;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Column(
        children: [
          Text(
            '◈ ${chapter.titleAr} ◈',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: accentColor.withValues(alpha: 0.85),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: accentColor.withValues(alpha: 0.18)),
        ],
      ),
    );
  }
}

class _ReaderPage extends StatelessWidget {
  const _ReaderPage({
    required this.page,
    required this.accentColor,
    required this.textColor,
    required this.bodyFontSize,
    required this.theme,
  });

  final BookPage page;
  final Color accentColor;
  final Color textColor;
  final double bodyFontSize;
  final ReaderTheme theme;

  @override
  Widget build(BuildContext context) {
    if (page.isHadith) {
      return _HadithCard(
        page: page,
        accentColor: accentColor,
        bodyFontSize: bodyFontSize,
        textColor: textColor,
        theme: theme,
      );
    }
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (page.title != null) ...[
            Text(
              page.title!,
              style: typography.headingMedium.copyWith(
                color: accentColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.start,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          Text(
            page.content,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: bodyFontSize,
              color: textColor,
              height: 2.2,
            ),
            textAlign: TextAlign.start,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  HADITH CARD
// ─────────────────────────────────────────

class _HadithCard extends StatelessWidget {
  final BookPage page;
  final Color accentColor;
  final double bodyFontSize;
  final Color textColor;
  final ReaderTheme theme;

  const _HadithCard({
    required this.page,
    required this.accentColor,
    required this.bodyFontSize,
    required this.textColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final cardBg = theme == ReaderTheme.dark
        ? Colors.white.withValues(alpha: 0.05)
        : accentColor.withValues(alpha: 0.05);
    final cardBorder = theme == ReaderTheme.dark
        ? Colors.white.withValues(alpha: 0.10)
        : accentColor.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (page.source != null && page.source!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    page.source!,
                    style: typography.caption.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (page.hadithNumber != null && page.hadithNumber!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    page.hadithNumber!,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (page.title != null) ...[
            Text(
              page.title!,
              style: typography.headingMedium.copyWith(
                color: accentColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.start,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
            ),
            child: Text(
              page.content,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: bodyFontSize,
                color: textColor,
                height: 2.4,
              ),
              textAlign: TextAlign.start,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.book,
    required this.chapter,
    required this.accentColor,
    required this.theme,
    required this.pageNotifier,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onOpenChapters,
    required this.onOpenSettings,
    required this.onClose,
  });

  final IslamicBook book;
  final BookChapter chapter;
  final Color accentColor;
  final ReaderTheme theme;
  final ValueListenable<int> pageNotifier;
  final bool Function(int page) isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onOpenChapters;
  final VoidCallback onOpenSettings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typography = context.typography;

    final isDark = theme == ReaderTheme.dark;
    final barBg = isDark ? Colors.black : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [barBg, barBg.withValues(alpha: 0.0)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
          child: Row(
            children: [
              _IconBtn(
                theme: theme,
                onTap: onOpenSettings,
                tooltip: l10n.bookReaderCustomizeTitle,
                child: Icon(
                  Icons.settings_outlined,
                  color: accentColor,
                  size: 22,
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: pageNotifier,
                builder: (context, page, _) => _IconBtn(
                  theme: theme,
                  onTap: onBookmarkToggle,
                  tooltip: isBookmarked(page)
                      ? l10n.bookReaderBookmarkRemoveTooltip
                      : l10n.bookReaderBookmarkAddTooltip,
                  child: Icon(
                    isBookmarked(page)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TakwaTappable(
                  onTap: onOpenChapters,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Text(
                          book.titleAr,
                          style: typography.caption.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                chapter.titleAr,
                                style: typography.caption.copyWith(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.unfold_more_rounded,
                              size: 13,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _IconBtn(
                theme: theme,
                onTap: onClose,
                tooltip: l10n.commonCancel,
                child: Icon(Icons.close_rounded, color: accentColor, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  BOTTOM NAVIGATION
// ─────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.totalPages,
    required this.chapter,
    required this.pagesReadAt,
    required this.accentColor,
    required this.theme,
    required this.pageNotifier,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  final int totalPages;
  final BookChapter chapter;
  final int Function(int page) pagesReadAt;
  final Color accentColor;
  final ReaderTheme theme;
  final ValueListenable<int> pageNotifier;
  final bool Function(int page) hasPrevious;
  final bool Function(int page) hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    final isDark = theme == ReaderTheme.dark;
    final trackColor = isDark ? Colors.white24 : colors.border;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            readerBackground(theme),
            readerBackground(theme).withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: pageNotifier,
            builder: (context, page, _) {
              final done = pagesReadAt(page).clamp(0, totalPages);
              final total = totalPages > 0 ? totalPages : 1;
              final progress = (done / total).clamp(0.0, 1.0);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: trackColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavButton(
                        // RTL reading: the left chevron advances, so "next"
                        // stays live wherever the book can move forward —
                        // including onto the next chapter.
                        icon: Icons.chevron_left,
                        label: l10n.bookReaderNextButton,
                        enabled: hasNext(page),
                        accentColor: accentColor,
                        onTap: onNext,
                      ),
                      Semantics(
                        liveRegion: true,
                        label: l10n.bookReaderPageProgress('$done', '$total'),
                        child: Column(
                          children: [
                            Text(
                              l10n.bookReaderPageProgress('$done', '$total'),
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.bookReaderPageLabel,
                              style: typography.caption.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      _NavButton(
                        icon: Icons.chevron_right,
                        label: l10n.bookReaderPrevButton,
                        enabled: hasPrevious(page),
                        accentColor: accentColor,
                        onTap: onPrev,
                        isRtl: true,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isRtl;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
    this.isRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: enabled ? 0.1 : 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: accentColor.withValues(alpha: enabled ? 0.2 : 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isRtl
            ? [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  icon,
                  size: 20,
                  color: accentColor.withValues(alpha: enabled ? 1 : 0.35),
                ),
              ]
            : [
                Icon(
                  icon,
                  size: 20,
                  color: accentColor.withValues(alpha: enabled ? 1 : 0.35),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: enabled
          ? TakwaTappable(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: content,
            )
          : Opacity(opacity: 0.5, child: content),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final ReaderTheme theme;
  final String? tooltip;

  const _IconBtn({
    required this.child,
    required this.onTap,
    required this.theme,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme == ReaderTheme.dark;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      color: isDark ? Colors.white : Colors.black87,
      style: IconButton.styleFrom(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        minimumSize: const Size(44, 44),
      ),
      icon: child,
    );
  }
}

// ─────────────────────────────────────────
//  SETTINGS SHEET (theme, size, bookmarks)
// ─────────────────────────────────────────

class _ReaderSettingsSheet extends ConsumerWidget {
  const _ReaderSettingsSheet({
    required this.book,
    required this.onThemeChange,
    required this.onFontSizeSelect,
    required this.onJumpToBookmark,
  });

  final IslamicBook book;
  final ValueChanged<ReaderTheme> onThemeChange;
  final ValueChanged<int> onFontSizeSelect;
  final ValueChanged<BookBookmark> onJumpToBookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    final theme = ref.watch(readerThemeProvider);
    final fontSizeLevel = ref.watch(bookFontSizeProvider);
    final bookmarks = ref.watch(bookBookmarksProvider)[book.id] ?? const [];
    final accentColor = book.accentColor;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.bookReaderCustomizeTitle,
              style: typography.headingMedium.copyWith(fontFamily: 'Amiri'),
              textAlign: TextAlign.end,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text(
              l10n.bookReaderThemeSectionLabel,
              style: typography.caption.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.end,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ReaderTheme.values.map((t) {
                final isSelected = theme == t;
                final color = readerBackground(t);
                return _ThemeOption(
                  label: switch (t) {
                    ReaderTheme.light => l10n.bookReaderThemeDay,
                    ReaderTheme.sepia => l10n.bookReaderThemeSepia,
                    ReaderTheme.dark => l10n.quranReaderThemeNight,
                  },
                  color: color,
                  selected: isSelected,
                  accentColor: accentColor,
                  onTap: () => onThemeChange(t),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xxl),
            Divider(color: colors.border),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'أ ب ج',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: fontSizeFromLevel(fontSizeLevel),
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  l10n.quranReaderFontSizeLabel,
                  style: typography.labelLarge.copyWith(fontFamily: 'Amiri'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (var level = 0; level <= 2; level++) ...[
                  _SizeBtn(
                    label: l10n.bookReaderFontSizeSampleLetter,
                    isSelected: fontSizeLevel == level,
                    onTap: () => onFontSizeSelect(level),
                    fontSize: 14.0 + level * 4,
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),
            Divider(color: colors.border),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.bookReaderBookmarksTitle,
              style: typography.labelLarge.copyWith(fontFamily: 'Amiri'),
              textAlign: TextAlign.end,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppSpacing.md),
            if (bookmarks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  l10n.bookReaderBookmarksEmpty,
                  style: typography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              )
            else
              Column(
                children: [
                  for (final bookmark in bookmarks)
                    _BookmarkTile(
                      book: book,
                      bookmark: bookmark,
                      onOpen: () => onJumpToBookmark(bookmark),
                      onRemove: () => ref
                          .read(bookBookmarksProvider.notifier)
                          .remove(book.id, bookmark),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: TakwaTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accentColor : colors.border,
                    width: selected ? 3 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() < 0.4
                            ? Colors.white
                            : accentColor,
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 12,
                  color: selected ? colors.gold : colors.textSecondary,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeBtn extends StatelessWidget {
  final String label;
  final double fontSize;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeBtn({
    required this.label,
    required this.fontSize,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: isSelected,
      child: TakwaTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? colors.gold.withValues(alpha: 0.1)
                : colors.background,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? colors.gold : colors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: fontSize,
              color: isSelected ? colors.gold : colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.book,
    required this.bookmark,
    required this.onOpen,
    required this.onRemove,
  });

  final IslamicBook book;
  final BookBookmark bookmark;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final chapters = book.chapters;
    final chapterTitle = bookmark.chapterIndex < chapters.length
        ? chapters[bookmark.chapterIndex].titleAr
        : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      onTap: onOpen,
      title: Text(
        bookmark.excerpt.isEmpty ? chapterTitle : bookmark.excerpt,
        style: typography.bodySmall.copyWith(height: 1.5),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        chapterTitle,
        style: typography.caption.copyWith(color: colors.textDim),
        textDirection: TextDirection.rtl,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded, size: 18),
        color: colors.textDim,
        onPressed: onRemove,
      ),
    );
  }
}

// ─────────────────────────────────────────
//  CHAPTER JUMP SHEET
// ─────────────────────────────────────────

class _ChapterJumpSheet extends StatelessWidget {
  const _ChapterJumpSheet({
    required this.book,
    required this.chapterOrder,
    required this.currentChapter,
    required this.onSelect,
  });

  final IslamicBook book;
  final List<int> chapterOrder;
  final int currentChapter;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    final accentColor = book.accentColor;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                l10n.booksChapterTocTitle,
                style: typography.headingMedium.copyWith(
                  fontFamily: 'Amiri',
                  color: accentColor,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: chapterOrder.length,
                itemBuilder: (context, slot) {
                  final chapterIndex = chapterOrder[slot];
                  final chapter = book.chapters[chapterIndex];
                  final isCurrent = chapterIndex == currentChapter;
                  return ListTile(
                    onTap: () => onSelect(slot),
                    selected: isCurrent,
                    selectedTileColor: accentColor.withValues(alpha: 0.08),
                    leading: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent ? accentColor : colors.card2,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        '${chapterIndex + 1}',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : colors.textDim,
                        ),
                      ),
                    ),
                    title: Text(
                      chapter.titleAr,
                      style: typography.labelLarge.copyWith(
                        fontFamily: 'Amiri',
                        color: isCurrent ? accentColor : colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      textDirection: TextDirection.rtl,
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.play_arrow_rounded, color: accentColor)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
