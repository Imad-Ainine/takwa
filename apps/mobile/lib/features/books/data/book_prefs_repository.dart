import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'book_search.dart';
import 'books_data.dart';

/// A saved reading position inside a book's inline text, created by the
/// reader's bookmark action.
///
/// Bookmarks live in SharedPreferences alongside the rest of the reader's
/// local-only state: the synced `book_reading_progress` table has no column
/// for them, and adding one would need a migration the server has not
/// applied. Progress itself still goes through Drift + Supabase.
class BookBookmark {
  const BookBookmark({
    required this.chapterIndex,
    required this.pageIndex,
    required this.createdAt,
    this.excerpt = '',
  });

  final int chapterIndex;
  final int pageIndex;
  final DateTime createdAt;

  /// Short snippet of the page, shown in the bookmarks list.
  final String excerpt;

  Map<String, dynamic> toJson() => {
    'c': chapterIndex,
    'p': pageIndex,
    't': createdAt.millisecondsSinceEpoch,
    'e': excerpt,
  };

  factory BookBookmark.fromJson(Map<String, dynamic> json) => BookBookmark(
    chapterIndex: (json['c'] as num?)?.toInt() ?? 0,
    pageIndex: (json['p'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (json['t'] as num?)?.toInt() ?? 0,
    ),
    excerpt: json['e'] as String? ?? '',
  );

  /// Same reading position, ignoring metadata.
  bool samePosition(BookBookmark other) =>
      other.chapterIndex == chapterIndex && other.pageIndex == pageIndex;
}

/// A cached local PDF reading session (page/total/elapsed seconds).
class PdfSessionSnapshot {
  const PdfSessionSnapshot({
    required this.page,
    required this.total,
    required this.secs,
  });

  final int page;
  final int total;
  final int secs;
}

/// Owns the SharedPreferences keys the Books feature persists to directly —
/// reader font size and the per-book PDF session cache (page/total/elapsed
/// seconds) — so notifiers read/write through here instead of calling the
/// plugin directly. Book *progress* itself lives in Drift (see
/// `BookProgressDao`); this repository only covers the local-only cache that
/// exists to render instantly before Drift/Supabase settle.
class BookPrefsRepository {
  BookPrefsRepository(this._prefs);

  final SharedPreferences _prefs;

  // ── Reader font size (0=small, 1=medium, 2=large) ──
  static const _fontSizeKey = 'book_font_size';

  int getFontSizeLevel() => _prefs.getInt(_fontSizeKey) ?? 1;
  Future<void> setFontSizeLevel(int level) =>
      _prefs.setInt(_fontSizeKey, level);

  // ── PDF session cache, per book ──
  static String _pageKey(String bookId) => 'pdf_session_${bookId}_page';
  static String _totalKey(String bookId) => 'pdf_session_${bookId}_total';
  static String _secsKey(String bookId) => 'pdf_session_${bookId}_secs';

  PdfSessionSnapshot getPdfSession(String bookId) => PdfSessionSnapshot(
    page: _prefs.getInt(_pageKey(bookId)) ?? 1,
    total: _prefs.getInt(_totalKey(bookId)) ?? 0,
    secs: _prefs.getInt(_secsKey(bookId)) ?? 0,
  );

  Future<void> setPdfSession(
    String bookId, {
    required int page,
    required int total,
    required int secs,
  }) async {
    await _prefs.setInt(_pageKey(bookId), page);
    await _prefs.setInt(_totalKey(bookId), total);
    await _prefs.setInt(_secsKey(bookId), secs);
  }

  // ── Reader theme (index into ReaderTheme) ──
  static const _readerThemeKey = 'book_reader_theme';

  int getReaderThemeIndex() => (_prefs.getInt(_readerThemeKey) ?? 0).clamp(0, 2);

  Future<void> setReaderThemeIndex(int index) =>
      _prefs.setInt(_readerThemeKey, index);

  // ── Library sort order ──
  static const _sortOrderKey = 'book_library_sort';

  BookSortOrder getSortOrder() {
    final name = _prefs.getString(_sortOrderKey);
    if (name == null) return BookSortOrder.title;
    return BookSortOrder.values.firstWhere(
      (o) => o.name == name,
      orElse: () => BookSortOrder.title,
    );
  }

  Future<void> setSortOrder(BookSortOrder order) =>
      _prefs.setString(_sortOrderKey, order.name);

  // ── Bookmarks, per book ──
  static const _bookmarksKey = 'book_bookmarks_v1';

  /// Whole bookmark table keyed by book id. Decoded once per read; a corrupt
  /// payload degrades to "no bookmarks" rather than throwing on launch.
  Map<String, List<BookBookmark>> getBookmarks() {
    final raw = _prefs.getString(_bookmarksKey);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map((key, value) {
        final entries = value is List
            ? value
                  .whereType<Map<String, dynamic>>()
                  .map(BookBookmark.fromJson)
                  .toList(growable: false)
            : const <BookBookmark>[];
        return MapEntry('$key', entries);
      });
    } catch (_) {
      return const {};
    }
  }

  List<BookBookmark> bookmarksFor(String bookId) =>
      getBookmarks()[bookId] ?? const [];

  Future<void> writeBookmarks(Map<String, List<BookBookmark>> table) =>
      _prefs.setString(
        _bookmarksKey,
        jsonEncode(
          table.map(
            (key, value) => MapEntry(
              key,
              value.map((b) => b.toJson()).toList(growable: false),
            ),
          ),
        ),
      );

  // ── Books catalogue cache (offline-first library) ──
  static const _booksCacheKey = 'books_list_cache_v1';

  /// Last successfully fetched catalogue, so the library opens instantly and
  /// offline instead of falling back to the three hard-coded defaults.
  List<IslamicBook> getBooksCache() {
    final raw = _prefs.getString(_booksCacheKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(IslamicBook.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Only the catalogue metadata is kept, not chapter bodies — the PDF reader
  /// streams those from Storage anyway, and a full-text cache would dwarf the
  /// SharedPreferences payload budget.
  Future<void> writeBooksCache(List<IslamicBook> books) async {
    final trimmed = books.map(_withoutChapterBodies).toList(growable: false);
    await _prefs.setString(
      _booksCacheKey,
      jsonEncode(trimmed.map((b) => b.toJson()).toList(growable: false)),
    );
  }

  IslamicBook _withoutChapterBodies(IslamicBook book) => IslamicBook(
    id: book.id,
    titleAr: book.titleAr,
    titleEn: book.titleEn,
    authorAr: book.authorAr,
    authorEn: book.authorEn,
    descriptionAr: book.descriptionAr,
    emoji: book.emoji,
    category: book.category,
    chapters: const [],
    coverUrl: book.coverUrl,
    pdfUrl: book.pdfUrl,
    publishYear: book.publishYear,
    coverColor: book.coverColor,
    coverColor2: book.coverColor2,
  );
}
