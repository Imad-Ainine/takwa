import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/book_prefs_repository.dart';
import '../data/book_search.dart';
import '../data/books_data.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/database/daos.dart';

final bookPrefsRepositoryProvider = Provider<BookPrefsRepository>((ref) {
  return BookPrefsRepository(ref.watch(sharedPreferencesProvider));
});

class BookProgress {
  final int chapterIndex;
  final int pageIndex;
  final Set<int> readPages;

  /// When this book was last opened; drives the library's "recent" sort and
  /// its continue-reading row. Null only for rows written before the column
  /// existed.
  final DateTime? lastReadAt;

  const BookProgress({
    required this.chapterIndex,
    required this.pageIndex,
    required this.readPages,
    this.lastReadAt,
  });
}

class ReadingProgressNotifier extends StateNotifier<Map<String, BookProgress>> {
  ReadingProgressNotifier(this._ref) : super({}) {
    _load();
  }

  final Ref _ref;

  BookProgressDao get _dao => _ref.read(bookProgressDaoProvider);

  /// Load all book progress from local Drift DB.
  Future<void> _load() async {
    try {
      final rows = await _dao.getAll();
      final map = <String, BookProgress>{};
      for (final row in rows) {
        map[row.bookId] = BookProgress(
          chapterIndex: row.chapterIndex,
          pageIndex: row.pageIndex,
          readPages: _parseReadPages(row.readPages),
          lastReadAt: row.updatedAt,
        );
      }
      state = map;
    } catch (e) {
      developer.log('Failed to load book progress from local DB: $e', name: 'BooksReadingProvider');
    }
  }

  /// `read_pages` is stored as `"0,1,3,7"`. Anything unparseable is dropped
  /// rather than thrown, since one malformed row used to blank the whole map.
  static Set<int> _parseReadPages(String raw) {
    if (raw.trim().isEmpty) return const {};
    return {
      for (final part in raw.split(','))
        if (int.tryParse(part.trim()) case final int value) value,
    };
  }

  /// Save progress locally (Drift) and opportunistically push to Supabase.
  Future<void> save(String bookId, int chapterIndex, int pageIndex) async {
    final existing = state[bookId];
    final updatedReadPages = {...(existing?.readPages ?? <int>{}), pageIndex};
    final now = DateTime.now();

    // 1. Update in-memory state immediately.
    state = {
      ...state,
      bookId: BookProgress(
        chapterIndex: chapterIndex,
        pageIndex: pageIndex,
        readPages: updatedReadPages,
        lastReadAt: now,
      ),
    };

    // 2. Write to local Drift DB (works offline).
    try {
      await _dao.markPage(
        bookId: bookId,
        chapterIndex: chapterIndex,
        pageIndex: pageIndex,
        readPages: updatedReadPages,
      );
    } catch (e) {
      developer.log('Failed to write book progress to local DB: $e', name: 'BooksReadingProvider');
    }

    // 3. Best-effort push to Supabase (ignored if offline).
    try {
      await _ref.read(supabaseServiceProvider).upsertBookProgress(bookId, {
        'chapter_index': chapterIndex,
        'page_index': pageIndex,
        'read_pages': updatedReadPages.toList(),
      });
    } catch (e) {
      developer.log('Offline book sync skipped: $e', name: 'BooksReadingProvider');
    }
  }

  /// Save PDF page progress locally and push to Supabase.
  Future<void> savePdfSession(
    String bookId,
    int pdfPage,
    int totalPdfPages,
    int readingSeconds,
  ) async {
    try {
      await _dao.savePdfSession(
        bookId: bookId,
        pdfPage: pdfPage,
        totalPdfPages: totalPdfPages,
        readingSeconds: readingSeconds,
      );
    } catch (e) {
      developer.log('Failed to write pdf session to local DB: $e', name: 'BooksReadingProvider');
    }
    try {
      await _ref
          .read(supabaseServiceProvider)
          .upsertPdfSession(bookId, pdfPage, totalPdfPages, readingSeconds);
    } catch (e) {
      developer.log('Offline pdf session sync skipped: $e', name: 'BooksReadingProvider');
    }
  }

  /// Pull remote progress from Supabase and merge into local Drift DB.
  Future<void> syncFromRemote() async {
    try {
      final remoteData = await _ref
          .read(supabaseServiceProvider)
          .getAllBookProgress();
      if (remoteData.isEmpty) return;
      for (final item in remoteData) {
        await _dao.upsertFromRemote(item);
      }
      await _load();
    } catch (e) {
      developer.log('Failed to sync remote book progress: $e', name: 'BooksReadingProvider');
    }
  }

  BookProgress? progressFor(String bookId) => state[bookId];
  /// Share of the book the reader has reached, from the furthest position
  /// visited rather than the `read_pages` set: those indices are per-chapter,
  /// so the same number repeats across chapters and a raw count overstates or
  /// understates real completion.
  double completionFor(IslamicBook book) =>
      bookCompletionFraction(book, state[book.id]);

  /// Map of book id → last opened, for the library's "recent" ordering.
  Map<String, DateTime> get lastReadByBook => {
    for (final entry in state.entries)
      if (entry.value.lastReadAt != null) entry.key: entry.value.lastReadAt!,
  };
}

/// Share of [book] reached by [progress], 0.0 → 1.0.
double bookCompletionFraction(IslamicBook book, BookProgress? progress) {
  final total = book.totalPages;
  if (progress == null || total <= 0) return 0;
  final chapter = clampChapterIndex(book, progress.chapterIndex);
  if (chapter < 0) return 0;
  var done = 0;
  for (var i = 0; i < chapter; i++) {
    done += book.chapters[i].pages.length;
  }
  done += (progress.pageIndex + 1).clamp(0, book.chapters[chapter].pages.length);
  return (done / total).clamp(0.0, 1.0);
}

/// Nearest valid chapter index for [book], or -1 when it has no chapters.
int clampChapterIndex(IslamicBook book, int index) {
  if (book.chapters.isEmpty) return -1;
  return index.clamp(0, book.chapters.length - 1);
}

/// Nearest valid page index inside a chapter of [length] pages.
int clampPageIndex(int length, int index) {
  if (length <= 0) return 0;
  return index.clamp(0, length - 1);
}

final readingProgressProvider =
    StateNotifierProvider<ReadingProgressNotifier, Map<String, BookProgress>>(
      (ref) => ReadingProgressNotifier(ref),
    );

// Helper to read progress for a specific book
BookReadingProgress? getProgress(Map<String, BookProgress> map, String bookId) {
  final p = map[bookId];
  if (p == null) return null;
  return BookReadingProgress(
    chapterIndex: p.chapterIndex,
    pageIndex: p.pageIndex,
  );
}

class BookReadingProgress {
  final int chapterIndex;
  final int pageIndex;
  const BookReadingProgress({
    required this.chapterIndex,
    required this.pageIndex,
  });
}

// ─────────────────────────────────────────
//  FONT SIZE (0=small 1=medium 2=large)
// ─────────────────────────────────────────

class BookFontSizeNotifier extends StateNotifier<int> {
  BookFontSizeNotifier(this._repo) : super(_repo.getFontSizeLevel());

  final BookPrefsRepository _repo;

  Future<void> cycle() => setLevel((state + 1) % 3);

  Future<void> setLevel(int level) {
    final next = level.clamp(0, 2);
    if (next == state) return Future.value();
    state = next;
    return _repo.setFontSizeLevel(next);
  }
}

final bookFontSizeProvider = StateNotifierProvider<BookFontSizeNotifier, int>(
  (ref) => BookFontSizeNotifier(ref.watch(bookPrefsRepositoryProvider)),
);

/// Reading levels stay readable on top of the system text scale instead of
/// multiplying by it unbounded — a 3× accessibility scale would otherwise push
/// Arabic body text past the viewport.
double fontSizeFromLevel(int level) {
  switch (level) {
    case 0:
      return 17.0;
    case 2:
      return 24.0;
    default:
      return 20.0;
  }
}

double scaledFontSize(
  BuildContext context,
  int level, {
  double minScaleFactor = 0.85,
  double maxScaleFactor = 1.25,
}) {
  final fontSize = fontSizeFromLevel(level);
  return MediaQuery.textScalerOf(context).clamp(
    minScaleFactor: minScaleFactor,
    maxScaleFactor: maxScaleFactor,
  ).scale(fontSize);
}

// ─────────────────────────────────────────
//  READER THEME
// ─────────────────────────────────────────

/// The reader's colour mode, kept in prefs so it survives across sessions and
/// applies to every book rather than resetting on each open.
class ReaderThemeNotifier extends StateNotifier<ReaderTheme> {
  ReaderThemeNotifier(this._repo)
    : super(ReaderTheme.values[_repo.getReaderThemeIndex()]);

  final BookPrefsRepository _repo;

  Future<void> select(ReaderTheme theme) async {
    if (theme == state) return;
    state = theme;
    await _repo.setReaderThemeIndex(theme.index);
  }
}

final readerThemeProvider =
    StateNotifierProvider<ReaderThemeNotifier, ReaderTheme>(
      (ref) => ReaderThemeNotifier(ref.watch(bookPrefsRepositoryProvider)),
    );

// ─────────────────────────────────────────
//  BOOKMARKS
// ─────────────────────────────────────────

class BookBookmarksNotifier extends StateNotifier<Map<String, List<BookBookmark>>> {
  BookBookmarksNotifier(this._repo) : super(_repo.getBookmarks());

  final BookPrefsRepository _repo;

  List<BookBookmark> forBook(String bookId) =>
      state[bookId] ?? const <BookBookmark>[];

  bool contains(String bookId, int chapterIndex, int pageIndex) =>
      forBook(bookId).any(
        (b) => b.chapterIndex == chapterIndex && b.pageIndex == pageIndex,
      );

  /// Adds [bookmark], or removes it when the same position is already saved.
  /// Returns true when a bookmark was created.
  Future<bool> toggle(String bookId, BookBookmark bookmark) async {
    final current = forBook(bookId);
    final existed = current.any((b) => b.samePosition(bookmark));
    final next = existed
        ? current.where((b) => !b.samePosition(bookmark)).toList()
        : [...current, bookmark];
    await _write(bookId, next);
    return !existed;
  }

  Future<void> remove(String bookId, BookBookmark bookmark) async {
    final next = forBook(
      bookId,
    ).where((b) => !b.samePosition(bookmark)).toList(growable: false);
    await _write(bookId, next);
  }

  Future<void> _write(String bookId, List<BookBookmark> bookmarks) async {
    final sorted = [...bookmarks]
      ..sort((a, b) => a.chapterIndex != b.chapterIndex
          ? a.chapterIndex.compareTo(b.chapterIndex)
          : a.pageIndex.compareTo(b.pageIndex));
    state = {...state, bookId: sorted};
    await _repo.writeBookmarks(state);
  }
}

final bookBookmarksProvider =
    StateNotifierProvider<BookBookmarksNotifier, Map<String, List<BookBookmark>>>(
      (ref) => BookBookmarksNotifier(ref.watch(bookPrefsRepositoryProvider)),
    );

// ─────────────────────────────────────────
//  LIBRARY SORT ORDER
// ─────────────────────────────────────────

class BookSortOrderNotifier extends StateNotifier<BookSortOrder> {
  BookSortOrderNotifier(this._repo) : super(_repo.getSortOrder());

  final BookPrefsRepository _repo;

  Future<void> select(BookSortOrder order) async {
    if (order == state) return;
    state = order;
    await _repo.setSortOrder(order);
  }
}

final bookSortOrderProvider =
    StateNotifierProvider<BookSortOrderNotifier, BookSortOrder>(
      (ref) => BookSortOrderNotifier(ref.watch(bookPrefsRepositoryProvider)),
    );

// ─────────────────────────────────────────
//  BOOKS LIST — offline-first
//  Supabase is authoritative; the last good fetch is cached, and the
//  bundled catalogue is the final fallback.
// ─────────────────────────────────────────
final booksListProvider = FutureProvider<List<IslamicBook>>((ref) async {
  final repo = ref.watch(bookPrefsRepositoryProvider);
  try {
    final data = await ref.read(supabaseServiceProvider).getBooks();
    if (data.isNotEmpty) {
      final books = data.map((json) => IslamicBook.fromJson(json)).toList();
      // Best-effort: a failed cache write must not fail the library.
      unawaited(repo.writeBooksCache(books).catchError((Object _) {}));
      return books;
    }
  } catch (_) {
    // Network unavailable — fall through to cached/bundled data.
  }
  final cached = repo.getBooksCache();
  return cached.isNotEmpty ? cached : kIslamicBooks;
});

/// Books worth resuming: opened before, still unfinished, most recent first.
final continueReadingProvider = Provider<List<ContinueReadingEntry>>((ref) {
  final books = ref.watch(booksListProvider).valueOrNull ?? const [];
  final progress = ref.watch(readingProgressProvider);
  if (progress.isEmpty) return const [];

  final entries = <ContinueReadingEntry>[];
  for (final book in books) {
    final bookProgress = progress[book.id];
    if (bookProgress == null) continue;
    final fraction = bookCompletionFraction(book, bookProgress);
    if (fraction >= 1) continue;
    final saved = getProgress(progress, book.id);
    entries.add(
      ContinueReadingEntry(
        book: book,
        progress: saved!,
        fraction: fraction,
        lastReadAt: bookProgress.lastReadAt,
      ),
    );
  }
  entries.sort(
    (a, b) => (b.lastReadAt ?? DateTime(2000)).compareTo(
      a.lastReadAt ?? DateTime(2000),
    ),
  );
  return List.unmodifiable(entries);
});

class ContinueReadingEntry {
  const ContinueReadingEntry({
    required this.book,
    required this.progress,
    required this.fraction,
    required this.lastReadAt,
  });

  final IslamicBook book;
  final BookReadingProgress progress;
  final double fraction;
  final DateTime? lastReadAt;
}
