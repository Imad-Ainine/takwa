import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_refresh_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/books/data/book_search.dart';
import 'package:takwa/features/books/data/books_data.dart';
import 'package:takwa/features/books/presentation/screens/books_chapter_screen.dart';
import 'package:takwa/features/books/providers/books_reading_provider.dart';
import 'package:takwa/l10n/app_localizations.dart';

class BooksLibraryScreen extends ConsumerStatefulWidget {
  const BooksLibraryScreen({super.key});

  @override
  ConsumerState<BooksLibraryScreen> createState() => _BooksLibraryScreenState();
}

class _BooksLibraryScreenState extends ConsumerState<BooksLibraryScreen> {
  final _searchCtrl = TextEditingController();
  BookCategory? _selectedCategory;
  bool _isGridView = true;
  final _scrollCtrl = ScrollController();

  /// Normalised so أنوار/الأنوار/انور and taa/haa spellings all match.
  String get _query => normalizeArabic(_searchCtrl.text);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {});
  }

  void _resetFilters() {
    _searchCtrl.clear();
    setState(() => _selectedCategory = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    final booksAsync = ref.watch(booksListProvider);
    final continueReading = ref.watch(continueReadingProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBarWidget(
        title: l10n.booksLibraryTitle,
        leading: const CustomLeadingButton(),
        scrollController: _scrollCtrl,
        actions: [
          _SortMenu(
            current: ref.watch(bookSortOrderProvider),
            onSelect: (order) =>
                ref.read(bookSortOrderProvider.notifier).select(order),
          ),
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              // Was hardcoded Colors.white — invisible in light mode, where
              // AppBarWidget's showBackground gradient leans light (its own
              // title text already accounts for this; actions: icons didn't).
              color: AppBarWidget.foregroundColorFor(context),
            ),
            tooltip: _isGridView
                ? l10n.booksListViewTooltip
                : l10n.booksGridViewTooltip,
          ),
        ],
      ),
      body: TakwaRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(booksListProvider);
          try {
            await ref.read(booksListProvider.future);
          } catch (_) {}
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Continue reading ──────────────────────────────────
            if (continueReading.isNotEmpty)
              SliverToBoxAdapter(
                child: _ContinueReadingRow(entries: continueReading),
              ),

            // ── Search Bar ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  onClear: _clearSearch,
                  clearTooltip: l10n.booksClearSearchTooltip,
                ),
              ),
            ),

            // ── Categories ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _CategorySelector(
                selected: _selectedCategory,
                onSelect: (cat) => setState(() => _selectedCategory = cat),
              ),
            ),

            // ── Book List/Grid ────────────────────────────────────
            booksAsync.when(
              data: (books) {
                final matches = books.where((b) {
                  final matchCat =
                      _selectedCategory == null ||
                      b.category == _selectedCategory;
                  return matchCat && bookMatchesNormalizedQuery(b, _query);
                }).toList();
                final filtered = sortBooks(
                  matches,
                  ref.watch(bookSortOrderProvider),
                  lastRead: ref
                      .read(readingProgressProvider.notifier)
                      .lastReadByBook,
                );

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoResults(
                      filtered: _query.isNotEmpty || _selectedCategory != null,
                      hint: l10n.booksNoResultsHint,
                      resetLabel: l10n.booksResetFiltersButton,
                      onReset: _resetFilters,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl,
                  ),
                  sliver: _isGridView
                      ? SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                          delegate: SliverChildBuilderDelegate((ctx, i) {
                            final book = filtered[i];
                            return _BookGridCard(
                              book: book,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BooksChapterScreen(book: book),
                                ),
                              ),
                            );
                          }, childCount: filtered.length),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((ctx, i) {
                            final book = filtered[i];
                            return _BookCard(
                              book: book,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BooksChapterScreen(book: book),
                                ),
                              ),
                            );
                          }, childCount: filtered.length),
                        ),
                );
              },
              loading: () => const SliverFillRemaining(child: _BooksSkeleton()),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 80,
                        color: colors.textSecondary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.booksServerConnectionError,
                        style: typography.headingMedium.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.booksConnectionErrorHint,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(booksListProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.gold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxxl,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.prayerScreenRetryButton,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  SEARCH BAR
// ─────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String clearTooltip;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.clearTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.start,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.booksSearchHint,
          hintStyle: TextStyle(
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(Icons.search, color: colors.gold),
          // One tap instead of backspacing every character.
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: clearTooltip,
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: AppSpacing.xl,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  SORT MENU
// ─────────────────────────────────────────

class _SortMenu extends StatelessWidget {
  final BookSortOrder current;
  final ValueChanged<BookSortOrder> onSelect;

  const _SortMenu({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (current) {
      BookSortOrder.title => l10n.booksSortByTitle,
      BookSortOrder.author => l10n.booksSortByAuthor,
      BookSortOrder.year => l10n.booksSortByYear,
      BookSortOrder.recent => l10n.booksSortByRecent,
    };
    return PopupMenuButton<BookSortOrder>(
      initialValue: current,
      onSelected: onSelect,
      tooltip: '${l10n.booksSortMenuLabel}: $label',
      color: context.colors.card,
      icon: Icon(
        Icons.sort_rounded,
        color: AppBarWidget.foregroundColorFor(context),
      ),
      itemBuilder: (context) => [
        for (final order in BookSortOrder.values)
          PopupMenuItem(
            value: order,
            child: Text(
              switch (order) {
                BookSortOrder.title => l10n.booksSortByTitle,
                BookSortOrder.author => l10n.booksSortByAuthor,
                BookSortOrder.year => l10n.booksSortByYear,
                BookSortOrder.recent => l10n.booksSortByRecent,
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────
//  CONTINUE READING
// ─────────────────────────────────────────

class _ContinueReadingRow extends StatelessWidget {
  final List<ContinueReadingEntry> entries;

  const _ContinueReadingRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text(
            l10n.booksContinueReadingTitle,
            style: typography.labelLarge.copyWith(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
            textDirection: TextDirection.rtl,
          ),
        ),
        SizedBox(
          height: 132,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = entries[i];
              final book = entry.book;
              final accent = book.accentColor;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: SizedBox(
                  width: 210,
                  child: _ContinueReadingTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BooksChapterScreen(book: book),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 74,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [accent, book.secondaryColor],
                            ),
                          ),
                          child: Center(
                            child: IslamicGlyph(book.emoji, size: 24),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                book.titleAr,
                                style: typography.labelLarge.copyWith(
                                  fontFamily: 'Amiri',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.start,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: entry.fraction,
                                  minHeight: 4,
                                  backgroundColor: accent.withValues(
                                    alpha: 0.15,
                                  ),
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${(entry.fraction * 100).round()}%',
                                style: typography.caption.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ContinueReadingTile({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      link: true,
      child: TakwaTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  NO RESULTS
// ─────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final bool filtered;
  final String hint;
  final String resetLabel;
  final VoidCallback onReset;

  const _NoResults({
    required this.filtered,
    required this.hint,
    required this.resetLabel,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧐', style: TextStyle(fontSize: 50)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              filtered ? hint : l10n.booksNoResultsFound,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            if (filtered) ...[
              const SizedBox(height: AppSpacing.xl),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
                label: Text(
                  resetLabel,
                  style: const TextStyle(fontFamily: 'Amiri'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  CATEGORY SELECTOR
// ─────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  final BookCategory? selected;
  final ValueChanged<BookCategory?> onSelect;

  const _CategorySelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    const categories = BookCategory.values;

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        reverse: true, // RTL feel
        itemCount: categories.length + 1,
        itemBuilder: (ctx, i) {
          final isAll = i == 0;
          final cat = isAll ? null : categories[i - 1];
          final isSelected = selected == cat;
          final label = isAll ? l10n.booksCategoryAll : _labelFor(l10n, cat!);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onSelect(cat),
              backgroundColor: colors.card,
              selectedColor: colors.gold.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? colors.gold : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                side: BorderSide(
                  color: isSelected ? colors.gold : colors.border,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  String _labelFor(AppLocalizations l10n, BookCategory cat) => switch (cat) {
    BookCategory.hadith => l10n.booksCategoryHadith,
    BookCategory.fiqh => l10n.booksCategoryFiqh,
    BookCategory.seerah => l10n.booksCategorySeerah,
    BookCategory.aqeedah => l10n.booksCategoryAqeedah,
    BookCategory.adab => l10n.booksCategoryAdab,
    BookCategory.tazkiyah => l10n.booksCategoryTazkiyah,
    BookCategory.quran => l10n.booksCategoryQuranicSciences,
  };
}

// ─────────────────────────────────────────
//  BOOK CARD (IMPROVED)
// ─────────────────────────────────────────

class _BookCard extends ConsumerWidget {
  final IslamicBook book;
  final VoidCallback onTap;
  const _BookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    final progress = ref.watch(readingProgressProvider);
    final c1 = book.accentColor;
    final c2 = book.secondaryColor;
    final fraction = bookCompletionFraction(book, progress[book.id]);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 20),
        child: Stack(
          children: [
            // Background Card
            Positioned.fill(
              left: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new,
                            size: 14,
                            color: colors.textSecondary.withValues(alpha: 0.3),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: c1.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              book.categoryLabel,
                              style: typography.caption.copyWith(
                                color: c1,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        book.titleAr,
                        style: typography.headingMedium.copyWith(
                          fontSize: 18,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        book.authorAr,
                        style: typography.caption.copyWith(
                          color: colors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (fraction > 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  minHeight: 4,
                                  backgroundColor: c1.withValues(alpha: 0.12),
                                  color: c1,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${(fraction * 100).round()}%',
                              style: typography.caption.copyWith(
                                color: c1,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _InfoChip(
                            icon: Icons.calendar_today,
                            text: '${book.publishYear} ${l10n.hijriEraSuffix}',
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _InfoChip(
                            icon: Icons.auto_stories,
                            text: book.publishYear > 500
                                ? l10n.booksVolumeLabel
                                : l10n.booksBookletLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Floating Book Cover
            Positioned(
              right: 20,
              top: 10,
              bottom: 10,
              child: Hero(
                tag: 'book_${book.id}',
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: c1.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [c1, c2],
                            ),
                          ),
                        ),
                        if (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Center(
                              child: IslamicGlyph(book.emoji, size: 40),
                            ),
                          )
                        else
                          Center(child: IslamicGlyph(book.emoji, size: 40)),
                        // Overlay shine
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: const Alignment(-0.5, -0.5),
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
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

// ─────────────────────────────────────────
//  BOOK GRID CARD
// ─────────────────────────────────────────

class _BookGridCard extends ConsumerWidget {
  final IslamicBook book;
  final VoidCallback onTap;
  const _BookGridCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final c1 = book.accentColor;
    final c2 = book.secondaryColor;
    final fraction = bookCompletionFraction(
      book,
      ref.watch(readingProgressProvider)[book.id],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [c1, c2],
                        ),
                      ),
                    ),
                    if (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            Center(child: IslamicGlyph(book.emoji, size: 30)),
                      )
                    else
                      Center(child: IslamicGlyph(book.emoji, size: 30)),
                    if (fraction > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 4,
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                          valueColor: AlwaysStoppedAnimation<Color>(c1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      book.titleAr,
                      style: typography.labelLarge.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      book.authorAr,
                      style: typography.caption.copyWith(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.goldDim,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        book.categoryLabel,
                        style: typography.caption.copyWith(
                          color: colors.gold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
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
}

// ─────────────────────────────────────────
//  INFO CHIP
// ─────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: colors.textSecondary.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(icon, size: 12, color: colors.gold.withValues(alpha: 0.6)),
      ],
    );
  }
}

// ─────────────────────────────────────────
//  BOOKS SKELETON (LOADING STATE)
// ─────────────────────────────────────────
class _BooksSkeleton extends StatelessWidget {
  const _BooksSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    return Center(
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TakwaLoadingIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.booksLoadingMessage,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
