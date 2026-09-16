import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/book_prefs_repository.dart';
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

  const BookProgress({
    required this.chapterIndex,
    required this.pageIndex,
    required this.readPages,
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
        final readPages = row.readPages.isEmpty
            ? <int>{}
            : row.readPages.split(',').map(int.parse).toSet();
        map[row.bookId] = BookProgress(
          chapterIndex: row.chapterIndex,
          pageIndex: row.pageIndex,
          readPages: readPages,
        );
      }
      state = map;
    } catch (e) {
      developer.log('Failed to load book progress from local DB: $e', name: 'BooksReadingProvider');
    }
  }

  /// Save progress locally (Drift) and opportunistically push to Supabase.
  Future<void> save(String bookId, int chapterIndex, int pageIndex) async {
    final existing = state[bookId];
    final updatedReadPages = {...(existing?.readPages ?? <int>{}), pageIndex};

    // 1. Update in-memory state immediately.
    state = {
      ...state,
      bookId: BookProgress(
        chapterIndex: chapterIndex,
        pageIndex: pageIndex,
        readPages: updatedReadPages,
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

  bool isPageRead(String bookId, int pageIndex) =>
      state[bookId]?.readPages.contains(pageIndex) ?? false;

  double getProgress(String bookId, int totalPages) {
    if (totalPages == 0) return 0;
    final readCount = state[bookId]?.readPages.length ?? 0;
    return (readCount / totalPages).clamp(0, 1.0);
  }
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

  Future<void> cycle() async {
    final next = (state + 1) % 3;
    state = next;
    await _repo.setFontSizeLevel(next);
  }
}

final bookFontSizeProvider = StateNotifierProvider<BookFontSizeNotifier, int>(
  (ref) => BookFontSizeNotifier(ref.watch(bookPrefsRepositoryProvider)),
);

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

// ─────────────────────────────────────────
//  BOOKS LIST — offline-first
//  Tries Supabase first, falls back to kIslamicBooks if offline.
// ─────────────────────────────────────────
final booksListProvider = FutureProvider<List<IslamicBook>>((ref) async {
  try {
    final data = await ref.read(supabaseServiceProvider).getBooks();
    if (data.isNotEmpty) {
      return data.map((json) => IslamicBook.fromJson(json)).toList();
    }
  } catch (_) {
    // Network unavailable — fall through to local data.
  }
  return kIslamicBooks;
});
