// Rows from the remote `books` table are hand-edited and frequently null,
// numeric or missing where the model expects a string. A bad row used to
// either throw during `fromJson` (killing the whole library) or leak the
// literal "null" into a hadith badge. The `format` getters underneath the
// reader's open path are also pinned here, since a chapter-less book was the
// original RangeError crash.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/features/books/data/books_data.dart';

void main() {
  group('bookColorFromHex', () {
    test('accepts 0x, #RRGGBB and bare RRGGBB forms', () {
      expect(bookColorFromHex('0xFF112233').toARGB32(), 0xFF112233);
      expect(bookColorFromHex('#112233').toARGB32(), 0xFF112233);
      expect(bookColorFromHex('FFC8A96E').toARGB32(), 0xFFC8A96E);
    });

    test('falls back instead of throwing on junk or null', () {
      const fallback = Color(0xDEADBEEF);
      expect(bookColorFromHex(null, fallback: fallback), fallback);
      expect(bookColorFromHex('gold', fallback: fallback), fallback);
      expect(bookColorFromHex('0xZZ', fallback: fallback), fallback);
      // "0" parses fine but is fully transparent — invisible on any theme.
      expect(bookColorFromHex('0', fallback: fallback), fallback);
    });
  });

  group('IslamicBook.fromJson', () {
    test('survives null, numeric and missing fields', () {
      final book = IslamicBook.fromJson(const {
        'id': 7,
        'title_ar': null,
        'author_ar': 12345,
        'chapters': null,
        'cover_url': '   ',
        'pdf_url': '',
        'publish_year': '751',
        'category': 'not-a-category',
        'emoji': '',
      });

      expect(book.id, '7');
      expect(book.titleAr, isEmpty);
      expect(book.authorAr, isEmpty);
      expect(book.chapters, isEmpty);
      expect(book.coverUrl, isNull);
      expect(book.pdfUrl, isNull);
      expect(book.publishYear, 751);
      expect(book.category, BookCategory.hadith);
      expect(book.emoji, '📚');
    });

    test('drops non-object chapter entries instead of throwing', () {
      final book = IslamicBook.fromJson(const {
        'id': 'x',
        'chapters': [
          null,
          'text',
          {'title_ar': 'فصل', 'pages': [null, {'content': 'نص'}]},
        ],
      });

      expect(book.chapters, hasLength(1));
      expect(book.chapters.single.pages, hasLength(1));
      expect(book.chapters.single.pages.single.content, 'نص');
    });

    test('a null hadith badge stays null rather than "null"', () {
      final page = BookPage.fromJson(const {
        'content': 'نص',
        'is_hadith': true,
        'hadith_number': null,
      });
      expect(page.hadithNumber, isNull);
    });
  });

  group('availability', () {
    BookChapter chapter(int pages) => BookChapter(
      index: 0,
      titleAr: 'فصل',
      pages: [
        for (var i = 0; i < pages; i++) BookPage(index: i, content: 'ص$i'),
      ],
    );

    IslamicBook book({List<BookChapter> chapters = const [], String? pdfUrl}) =>
        IslamicBook(
          id: 'b',
          titleAr: 'عنوان',
          titleEn: 'Title',
          authorAr: 'مؤلف',
          authorEn: 'Author',
          descriptionAr: '',
          emoji: '📚',
          category: BookCategory.hadith,
          chapters: chapters,
          pdfUrl: pdfUrl,
          publishYear: 1,
          coverColor: '0xFFC8A96E',
          coverColor2: '0xFF3AAFA9',
        );

    test('a PDF-only book reports no readable text', () {
      final b = book(pdfUrl: 'https://example.com/a.pdf');
      expect(b.hasReadableText, isFalse);
      expect(b.format, BookFormat.pdf);
      expect(b.totalPages, 0);
    });

    test('a metadata-only book reports the none format', () {
      expect(book().format, BookFormat.none);
    });

    test('both sources are reported so the reader can offer a choice', () {
      final b = book(chapters: [chapter(3)], pdfUrl: 'https://example.com/a.pdf');
      expect(b.format, BookFormat.pdfAndText);
      expect(b.totalPages, 3);
    });

    test('a chapter whose pages are all empty is still not readable', () {
      expect(book(chapters: [chapter(0)]).hasReadableText, isFalse);
    });

    test('cover colours parse through the shared helper', () {
      final b = book();
      expect(b.accentColor.toARGB32(), 0xFFC8A96E);
      expect(b.secondaryColor.toARGB32(), 0xFF3AAFA9);
    });
  });
}
