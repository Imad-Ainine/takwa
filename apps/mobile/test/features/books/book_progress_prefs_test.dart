// Completion and the local-only Books preferences.
//
// `bookCompletionFraction` replaced a counter over `read_pages`, whose indices
// restart at 0 in every chapter — a book read to chapter 10 page 3 scored the
// same as one opened once. The prefs repository is the offline path for
// bookmarks and the catalogue cache, so a corrupt payload must degrade rather
// than throw at launch.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/features/books/data/book_prefs_repository.dart';
import 'package:takwa/features/books/data/book_search.dart';
import 'package:takwa/features/books/data/books_data.dart';
import 'package:takwa/features/books/providers/books_reading_provider.dart';

IslamicBook _book(List<int> pagesPerChapter) => IslamicBook(
  id: 'book',
  titleAr: 'عنوان',
  titleEn: 'Title',
  authorAr: 'مؤلف',
  authorEn: 'Author',
  descriptionAr: '',
  emoji: '📚',
  category: BookCategory.hadith,
  publishYear: 1,
  coverColor: '0xFFC8A96E',
  coverColor2: '0xFF3AAFA9',
  chapters: [
    for (var c = 0; c < pagesPerChapter.length; c++)
      BookChapter(
        index: c,
        titleAr: 'فصل ${c + 1}',
        pages: [
          for (var p = 0; p < pagesPerChapter[c]; p++)
            BookPage(index: p, content: 'محتوى'),
        ],
      ),
  ],
);

BookProgress _progress(int chapter, int page) =>
    BookProgress(chapterIndex: chapter, pageIndex: page, readPages: {page});

/// `samePosition` ignores metadata, so the timestamp is filler here.
BookBookmark bookmarkAt(int chapter, int page) => BookBookmark(
  chapterIndex: chapter,
  pageIndex: page,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

void main() {
  late SharedPreferences prefs;
  late BookPrefsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = BookPrefsRepository(prefs);
  });

  group('bookCompletionFraction', () {
    final book = _book([4, 4, 4]);

    test('is zero with no progress', () {
      expect(bookCompletionFraction(book, null), 0);
    });

    test('is zero for a book with no chapters', () {
      expect(
        bookCompletionFraction(_book(const <int>[]), _progress(0, 0)),
        0,
      );
    });

    test('counts whole chapters before the current one', () {
      // Chapter 1 (4 pages done) + page 1 of chapter 2 → 6/12.
      expect(bookCompletionFraction(book, _progress(1, 1)), closeTo(0.5, 1e-9));
    });

    test('reaches 1.0 on the last page', () {
      expect(bookCompletionFraction(book, _progress(2, 3)), 1);
    });

    test('a stale out-of-range position clamps instead of throwing', () {
      expect(bookCompletionFraction(book, _progress(99, 99)), 1);
      // A negative page index cannot read as "half a page done".
      expect(bookCompletionFraction(book, _progress(-5, -5)), 0);
    });

    test('never reports a negative or over-complete share', () {
      for (var c = 0; c < 5; c++) {
        for (var p = 0; p < 5; p++) {
          final f = bookCompletionFraction(book, _progress(c, p));
          expect(f, inInclusiveRange(0, 1));
        }
      }
    });
  });

  group('clamp helpers', () {
    test('clampChapterIndex returns -1 only when there is nothing to open', () {
      expect(clampChapterIndex(_book([1]), 7), 0);
      expect(clampChapterIndex(_book(const <int>[]), 0), -1);
    });

    test('clampPageIndex keeps a page inside its chapter', () {
      expect(clampPageIndex(3, 10), 2);
      expect(clampPageIndex(3, -2), 0);
      expect(clampPageIndex(0, 5), 0);
    });
  });

  group('reader prefs', () {
    test('font size defaults to medium and cycles through three levels', () async {
      expect(repo.getFontSizeLevel(), 1);
      await repo.setFontSizeLevel(2);
      expect(repo.getFontSizeLevel(), 2);
    });

    test('theme index is clamped to the three ReaderTheme values', () async {
      await prefs.setInt('book_reader_theme', 9);
      expect(repo.getReaderThemeIndex(), ReaderTheme.values.length - 1);
      await repo.setReaderThemeIndex(1);
      expect(ReaderTheme.values[repo.getReaderThemeIndex()], ReaderTheme.sepia);
    });

    test('sort order falls back to title on an unknown stored name', () async {
      await prefs.setString('book_library_sort', 'downloads');
      expect(repo.getSortOrder(), BookSortOrder.title);
      await repo.setSortOrder(BookSortOrder.recent);
      expect(repo.getSortOrder(), BookSortOrder.recent);
    });
  });

  group('bookmarks', () {
    const key = 'book_bookmarks_v1';
    final bookmark = BookBookmark(
      chapterIndex: 2,
      pageIndex: 5,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      excerpt: 'إنما الأعمال بالنيات',
    );

    test('round-trip keeps position, timestamp and excerpt', () async {
      await repo.writeBookmarks({
        'book': [bookmark],
      });
      final read = repo.bookmarksFor('book');
      expect(read.single.chapterIndex, 2);
      expect(read.single.pageIndex, 5);
      expect(read.single.excerpt, bookmark.excerpt);
      expect(read.single.createdAt, bookmark.createdAt);
    });

    test('unreadable payloads degrade to no bookmarks', () async {
      await prefs.setString(key, '{not json');
      expect(repo.getBookmarks(), isEmpty);

      await prefs.setString(key, jsonEncode({'book': 'nope'}));
      expect(repo.bookmarksFor('book'), isEmpty);

      await prefs.setString(key, jsonEncode([1, 2, 3]));
      expect(repo.getBookmarks(), isEmpty);
    });

    test('junk entries inside a list are dropped, good ones kept', () async {
      await prefs.setString(key, jsonEncode({
        'book': [
          null,
          5,
          {'c': 1, 'p': 2},
        ],
      }));
      final read = repo.bookmarksFor('book');
      expect(read, hasLength(1));
      // Missing timestamp/excerpt default instead of throwing.
      expect(read.single.samePosition(bookmarkAt(1, 2)), isTrue);
      expect(read.single.excerpt, isEmpty);
    });

    test('an unknown book id returns an empty list', () {
      expect(repo.bookmarksFor('missing'), isEmpty);
    });
  });

  group('catalogue cache', () {
    test('stores metadata but drops chapter bodies', () async {
      await repo.writeBooksCache([_book([2, 2])]);
      final cached = repo.getBooksCache();
      expect(cached, hasLength(1));
      expect(cached.single.titleAr, 'عنوان');
      expect(cached.single.chapters, isEmpty);
    });

    test('keeps the cache small enough for SharedPreferences', () async {
      // One book with a long body must not serialise its text.
      final long = IslamicBook(
        id: 'long',
        titleAr: 'طويل',
        titleEn: 'Long',
        authorAr: 'مؤلف',
        authorEn: 'Author',
        descriptionAr: '',
        emoji: '📚',
        category: BookCategory.tazkiyah,
        publishYear: 1,
        coverColor: '0xFFC8A96E',
        coverColor2: '0xFF3AAFA9',
        chapters: [
          BookChapter(
            index: 0,
            titleAr: 'فصل',
            pages: [
              for (var i = 0; i < 400; i++)
                BookPage(index: i, content: 'كلمة ' * 120),
            ],
          ),
        ],
      );
      await repo.writeBooksCache([long]);
      expect(
        (prefs.getString('books_list_cache_v1') ?? '').length,
        lessThan(2000),
      );
    });

    test('an empty or corrupt cache reads as no books', () async {
      expect(repo.getBooksCache(), isEmpty);
      await prefs.setString('books_list_cache_v1', '[]not json');
      expect(repo.getBooksCache(), isEmpty);
    });
  });
}
