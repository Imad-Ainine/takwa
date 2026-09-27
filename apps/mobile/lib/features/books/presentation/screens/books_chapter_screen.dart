import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/books/data/books_data.dart';
import 'package:takwa/features/books/providers/books_reading_provider.dart';
import 'package:takwa/features/books/presentation/screens/book_reader_screen.dart';
import 'package:takwa/features/books/presentation/screens/book_pdf_reader_screen.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Book detail: header, description, the entry point into the reader, and the
/// table of contents.
///
/// The body is a [CustomScrollView] so a book with hundreds of chapters builds
/// its rows lazily — the previous `ListView(children: List.generate(...))`
/// constructed every chapter row before the first frame.
class BooksChapterScreen extends ConsumerWidget {
  final IslamicBook book;
  const BooksChapterScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    final c1 = book.accentColor;
    final c2 = book.secondaryColor;

    // Watching the map (not the notifier) is what makes the progress read-out
    // update as the reader writes positions.
    final progressMap = ref.watch(readingProgressProvider);
    final progress = progressMap[book.id];
    final savedProgress = getProgress(progressMap, book.id);
    final fraction = bookCompletionFraction(book, progress);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBarWidget(
        title: book.titleAr,
        firstShade: c1,
        secondShade: c2,
        height: 280,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomLeadingButton(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          book.titleAr,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          book.authorAr,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Hero(
                    tag: 'book-emoji-${book.id}',
                    child: IslamicGlyph(book.emoji, size: 44),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _StatsRow(book: book),
              const SizedBox(height: AppSpacing.sm),
              _ReadingProgressBar(
                fraction: fraction,
                book: book,
                accentColor: Colors.white,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: SliverToBoxAdapter(
              child: _AboutBook(
                book: book,
                accentColor: c1,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: _PrimaryActionButton(
                book: book,
                savedProgress: savedProgress,
                fraction: fraction,
                accentColor: c1,
              ),
            ),
          ),

          if (book.hasReadableText) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.booksChapterChaptersCount(book.chapters.length),
                      style: typography.caption.copyWith(
                        color: colors.textDim,
                      ),
                    ),
                    Text(
                      l10n.booksChapterTocTitle,
                      style: typography.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final chapter = book.chapters[index];
                  final isCurrent = progress?.chapterIndex == index;
                  return _ChapterItem(
                    chapter: chapter,
                    index: index,
                    accentColor: c1,
                    isCurrent: isCurrent,
                    currentPage: isCurrent
                        ? clampPageIndex(chapter.pages.length, progress!.pageIndex)
                        : 0,
                    onTap: () => _openChapter(context, index),
                  );
                }, childCount: book.chapters.length),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  void _openChapter(BuildContext context, int chapterIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(book: book, initialChapterIndex: chapterIndex),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.book});

  final IslamicBook book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _StatChip(label: book.categoryLabel, icon: Icons.category_outlined),
          const SizedBox(width: AppSpacing.sm),
          _StatChip(
            label: l10n.booksChapterPagesCount(book.totalPages),
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatChip(
            label: l10n.booksChapterMinutesAbbrev(book.estimatedReadingMinutes),
            icon: Icons.schedule_rounded,
          ),
        ],
      ),
    );
  }
}

class _AboutBook extends StatelessWidget {
  const _AboutBook({required this.book, required this.accentColor});

  final IslamicBook book;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              l10n.booksChapterAboutTitle,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
                fontSize: context.typography.headingMedium.fontSize,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          book.descriptionAr,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 15,
            color: colors.textSecondary,
            height: 1.8,
          ),
          textAlign: TextAlign.start,
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, color: Colors.white70, size: 14),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final IslamicBook book;
  final BookReadingProgress? savedProgress;
  final double fraction;
  final Color accentColor;

  const _PrimaryActionButton({
    required this.book,
    required this.savedProgress,
    required this.fraction,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final format = book.format;

    if (format == BookFormat.none) {
      // Nothing to open: say so instead of pushing a route that would fail.
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colors.textDim, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l10n.bookReaderContentUnavailable,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  height: 1.7,
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.start,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      );
    }

    final resumable = savedProgress != null && fraction > 0;
    final primaryIsText = format != BookFormat.pdf;

    return Column(
      children: [
        _ActionBtn(
          label: primaryIsText
              ? (resumable
                    ? l10n.booksChapterContinueReadingButton
                    : l10n.booksChapterStartReadingButton)
              : l10n.booksChapterReadPdfButton,
          icon: primaryIsText
              ? (resumable ? Icons.play_arrow_rounded : Icons.menu_book_rounded)
              : Icons.picture_as_pdf_outlined,
          filled: true,
          color: accentColor,
          subtitle: primaryIsText && resumable
              ? _resumeLabel(context, book, savedProgress!)
              : null,
          onTap: () => primaryIsText
              ? Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookReaderScreen(
                      book: book,
                      initialChapterIndex: savedProgress?.chapterIndex ?? 0,
                      initialPageIndex: savedProgress?.pageIndex ?? 0,
                    ),
                  ),
                )
              : Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookPdfReaderScreen(book: book),
                  ),
                ),
        ),
        if (format == BookFormat.pdfAndText) ...[
          const SizedBox(height: AppSpacing.md),
          _ActionBtn(
            label: l10n.booksChapterReadPdfButton,
            icon: Icons.picture_as_pdf_outlined,
            filled: false,
            color: accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookPdfReaderScreen(book: book),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _resumeLabel(
    BuildContext context,
    IslamicBook book,
    BookReadingProgress progress,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final chapter = clampChapterIndex(book, progress.chapterIndex);
    return chapter < 0
        ? l10n.bookReaderPageLabel
        : book.chapters[chapter].titleAr;
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.filled,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = subtitle == null ? 64.0 : 76.0;

    return Semantics(
      button: true,
      label: label,
      child: TakwaTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: filled
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                  )
                : null,
            color: filled ? null : colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: filled
                ? null
                : Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (subtitle != null) ...[
                Expanded(
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                icon,
                color: filled ? Colors.white : color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterItem extends StatelessWidget {
  final BookChapter chapter;
  final int index;
  final Color accentColor;
  final bool isCurrent;
  final int currentPage;
  final VoidCallback onTap;

  const _ChapterItem({
    required this.chapter,
    required this.index,
    required this.accentColor,
    required this.isCurrent,
    required this.currentPage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    final pageCount = chapter.pages.length;

    return Semantics(
      button: true,
      selected: isCurrent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isCurrent
                ? accentColor.withValues(alpha: 0.05)
                : colors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCurrent
                  ? accentColor.withValues(alpha: 0.3)
                  : colors.border,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: colors.textDim,
                size: 20,
              ),
              const Spacer(),
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chapter.titleAr,
                      style: typography.labelLarge.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? accentColor : colors.textPrimary,
                        fontFamily: 'Amiri',
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          l10n.booksChapterPagesCount(pageCount),
                          style: typography.caption,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '•',
                          style: typography.caption.copyWith(
                            color: colors.textDim,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '~${l10n.homeMinutesLabel(chapter.estimatedMinutes)}',
                          style: typography.caption,
                        ),
                      ],
                    ),
                    if (isCurrent && pageCount > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ((currentPage + 1) / pageCount).clamp(
                            0.0,
                            1.0,
                          ),
                          backgroundColor: accentColor.withValues(alpha: 0.1),
                          color: accentColor,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent ? accentColor : colors.card2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent ? Colors.white : colors.textDim,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingProgressBar extends StatelessWidget {
  const _ReadingProgressBar({
    required this.fraction,
    required this.book,
    required this.accentColor,
  });

  final double fraction;
  final IslamicBook book;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final percentage = (fraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              liveRegion: true,
              label: '${book.titleAr}: $percentage%',
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              l10n.booksChapterReadingProgressLabel,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'Amiri',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
