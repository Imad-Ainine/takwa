import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/books/data/books_data.dart';
import 'package:takwa/features/books/providers/books_reading_provider.dart';
import 'package:takwa/l10n/app_localizations.dart';

enum ReaderTheme { light, sepia, dark }

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
    with SingleTickerProviderStateMixin {
  late int _chapterIdx;
  late int _pageIdx;
  bool _showUI = true;
  ReaderTheme _currentTheme = ReaderTheme.light;
  late AnimationController _uiAnim;
  late Animation<double> _uiFade;

  // ── Computed helpers ─────────────────────────────────────────
  BookChapter get _chapter => widget.book.chapters[_chapterIdx];
  BookPage get _page => _chapter.pages[_pageIdx];
  bool get _isFirstPage => _chapterIdx == 0 && _pageIdx == 0;
  bool get _isLastPage =>
      _chapterIdx == widget.book.chapters.length - 1 &&
      _pageIdx == _chapter.pages.length - 1;

  @override
  void initState() {
    super.initState();
    _chapterIdx = widget.initialChapterIndex;
    _pageIdx = widget.initialPageIndex;

    _uiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _uiFade = CurvedAnimation(parent: _uiAnim, curve: Curves.easeInOut);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initial progress save
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveProgress();
    });
  }

  @override
  void dispose() {
    _uiAnim.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    if (_showUI) {
      _uiAnim.forward();
    } else {
      _uiAnim.reverse();
    }
  }

  void _goNext() {
    if (_isLastPage) return;
    setState(() {
      if (_pageIdx < _chapter.pages.length - 1) {
        _pageIdx++;
      } else {
        _chapterIdx++;
        _pageIdx = 0;
      }
    });
    _saveProgress();
  }

  void _goPrev() {
    if (_isFirstPage) return;
    setState(() {
      if (_pageIdx > 0) {
        _pageIdx--;
      } else {
        _chapterIdx--;
        _pageIdx = widget.book.chapters[_chapterIdx].pages.length - 1;
      }
    });
    _saveProgress();
  }

  void _saveProgress() {
    ref
        .read(readingProgressProvider.notifier)
        .save(widget.book.id, _chapterIdx, _pageIdx);
  }

  Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFFC8A96E);
    try {
      if (hex.startsWith('0x')) return Color(int.parse(hex));
      if (hex.startsWith('#')) {
        return Color(int.parse('0xFF${hex.substring(1)}'));
      }
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return const Color(0xFFC8A96E);
    }
  }

  Color _getBgColor() => switch (_currentTheme) {
    ReaderTheme.light => Colors.white,
    ReaderTheme.sepia => const Color(0xFFF4ECD8),
    ReaderTheme.dark => const Color(0xFF121212),
  };

  Color _getTextColor() => switch (_currentTheme) {
    ReaderTheme.light => const Color(0xFF2D2D2D),
    ReaderTheme.sepia => const Color(0xFF5B4636),
    ReaderTheme.dark => const Color(0xFFE0E0E0),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final fontSizeLevel = ref.watch(bookFontSizeProvider);
    final fontSize = fontSizeFromLevel(fontSizeLevel);
    final accentColor = _parseColor(widget.book.coverColor);

    final bgColor = _getBgColor();
    final textColor = _getTextColor();

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: _toggleUI,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // ── Decorative background in Sepia ────────────────
            if (_currentTheme == ReaderTheme.sepia)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.03,
                  child: Image.asset(
                    'assets/images/pattern_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),

            // ── Page Content ──────────────────────────────────
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 110, 24, 130),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Chapter title at top
                    Center(
                      child: Text(
                        '◈ ${_chapter.titleAr} ◈',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          color: accentColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Content Rendering
                    if (_page.isHadith) ...[
                      _HadithCard(
                        page: _page,
                        accentColor: accentColor,
                        bodyFontSize: fontSize,
                        textColor: textColor,
                        theme: _currentTheme,
                      ),
                    ] else ...[
                      if (_page.title != null) ...[
                        Text(
                          _page.title!,
                          style: typography.headingMedium.copyWith(
                            color: accentColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Amiri',
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      Text(
                        _page.content,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: fontSize,
                          color: textColor,
                          height: 2.2,
                        ),
                        textAlign: TextAlign.start,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                    const SizedBox(height: 60),

                    // Ornamental Footer
                    Center(
                      child: Opacity(
                        opacity: 0.3,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 40, height: 1, color: accentColor),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: accentColor,
                                size: 18,
                              ),
                            ),
                            Container(width: 40, height: 1, color: accentColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Top Bar ─────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _uiFade,
                child: _TopBar(
                  book: widget.book,
                  chapter: _chapter,
                  accentColor: accentColor,
                  fontSizeLevel: fontSizeLevel,
                  currentTheme: _currentTheme,
                  onFontSizeToggle: () =>
                      ref.read(bookFontSizeProvider.notifier).cycle(),
                  onThemeChange: (t) => setState(() => _currentTheme = t),
                ),
              ),
            ),

            // ── Bottom Bar ──────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _uiFade,
                child: _BottomNav(
                  book: widget.book,
                  chapterIndex: _chapterIdx,
                  pageIndex: _pageIdx,
                  accentColor: accentColor,
                  isFirst: _isFirstPage,
                  isLast: _isLastPage,
                  onPrev: _goPrev,
                  onNext: _goNext,
                ),
              ),
            ),
          ],
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (page.source != null) ...[
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
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
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
                page.hadithNumber ?? '',
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
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
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
    );
  }
}

// ─────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final IslamicBook book;
  final BookChapter chapter;
  final Color accentColor;
  final int fontSizeLevel;
  final ReaderTheme currentTheme;
  final VoidCallback onFontSizeToggle;
  final ValueChanged<ReaderTheme> onThemeChange;

  const _TopBar({
    required this.book,
    required this.chapter,
    required this.accentColor,
    required this.fontSizeLevel,
    required this.currentTheme,
    required this.onFontSizeToggle,
    required this.onThemeChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final isDark = currentTheme == ReaderTheme.dark;
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              // Settings Button
              _IconBtn(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => _SettingsSheet(
                      currentTheme: currentTheme,
                      onThemeChange: onThemeChange,
                      fontSizeLevel: fontSizeLevel,
                      onFontSizeToggle: onFontSizeToggle,
                      accentColor: accentColor,
                    ),
                  );
                },
                currentTheme: currentTheme,
                child: Icon(
                  Icons.settings_outlined,
                  color: accentColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
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
                    Text(
                      chapter.titleAr,
                      style: typography.caption.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Back button
              _IconBtn(
                onTap: () => Navigator.pop(context),
                currentTheme: currentTheme,
                child: Icon(Icons.close, color: accentColor, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  final ReaderTheme currentTheme;
  final ValueChanged<ReaderTheme> onThemeChange;
  final int fontSizeLevel;
  final VoidCallback onFontSizeToggle;
  final Color accentColor;

  const _SettingsSheet({
    required this.currentTheme,
    required this.onThemeChange,
    required this.fontSizeLevel,
    required this.onFontSizeToggle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.bookReaderCustomizeTitle,
            style: typography.headingMedium.copyWith(fontFamily: 'Amiri'),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // Themes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ReaderTheme.values.map((t) {
              final isSelected = currentTheme == t;
              final color = switch (t) {
                ReaderTheme.light => Colors.white,
                ReaderTheme.sepia => const Color(0xFFF4ECD8),
                ReaderTheme.dark => const Color(0xFF1E1E1E),
              };
              return GestureDetector(
                onTap: () => onThemeChange(t),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? accentColor : colors.border,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: t == ReaderTheme.dark
                                  ? Colors.white
                                  : accentColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      switch (t) {
                        ReaderTheme.light => l10n.bookReaderThemeDay,
                        ReaderTheme.sepia => l10n.bookReaderThemeSepia,
                        ReaderTheme.dark => l10n.quranReaderThemeNight,
                      },
                      style: typography.caption.copyWith(
                        color: isSelected ? colors.gold : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : null,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: AppSpacing.xxxl),

          // Font Size
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.quranReaderFontSizeLabel,
                style: typography.labelLarge.copyWith(fontFamily: 'Amiri'),
              ),
              Row(
                children: [
                  _SizeBtn(
                    label: l10n.bookReaderFontSizeSampleLetter,
                    isSelected: fontSizeLevel == 0,
                    onTap: onFontSizeToggle,
                    fontSize: 14,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _SizeBtn(
                    label: l10n.bookReaderFontSizeSampleLetter,
                    isSelected: fontSizeLevel == 1,
                    onTap: onFontSizeToggle,
                    fontSize: 18,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _SizeBtn(
                    label: l10n.bookReaderFontSizeSampleLetter,
                    isSelected: fontSizeLevel == 2,
                    onTap: onFontSizeToggle,
                    fontSize: 22,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.gold.withValues(alpha: 0.1) : colors.background,
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
    );
  }
}

// ─────────────────────────────────────────
//  BOTTOM NAVIGATION
// ─────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final IslamicBook book;
  final int chapterIndex;
  final int pageIndex;
  final Color accentColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _BottomNav({
    required this.book,
    required this.chapterIndex,
    required this.pageIndex,
    required this.accentColor,
    required this.isFirst,
    required this.isLast,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;

    // Compute global page progress
    int globalDone = 0;
    if (book.chapters.isNotEmpty) {
      for (int ci = 0; ci < chapterIndex; ci++) {
        globalDone += book.chapters[ci].totalPages;
      }
    }
    globalDone += pageIndex + 1;
    final total = book.totalPages > 0 ? book.totalPages : 1;
    final progress = (globalDone / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [colors.background, colors.background.withValues(alpha: 0.0)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Track
            Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavButton(
                  icon: Icons.chevron_left,
                  label: l10n.bookReaderNextButton,
                  enabled: !isLast,
                  accentColor: accentColor,
                  onTap: onNext,
                ),
                Column(
                  children: [
                    Text(
                      l10n.bookReaderPageProgress(
                        globalDone.toString(),
                        total.toString(),
                      ),
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      l10n.bookReaderPageLabel,
                      style: typography.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                _NavButton(
                  icon: Icons.chevron_right,
                  label: l10n.bookReaderPrevButton,
                  enabled: !isFirst,
                  accentColor: accentColor,
                  onTap: onPrev,
                  isRtl: true,
                ),
              ],
            ),
          ],
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
    if (!enabled) return const SizedBox(width: 100);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
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
                  Icon(icon, size: 20, color: accentColor),
                ]
              : [
                  Icon(icon, size: 20, color: accentColor),
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
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final ReaderTheme currentTheme;

  const _IconBtn({
    required this.child,
    required this.onTap,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = currentTheme == ReaderTheme.dark;
    return TakwaTappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(23),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(child: child),
      ),
    );
  }
}
