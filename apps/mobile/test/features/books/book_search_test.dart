// Arabic search is diacritic- and spelling-sensitive by default: a user
// typing "انور" must find "الأنوار", and "كتب" must match "كُتِبَ".
// These tests pin the normalisation table and the sort orders the library
// offers, since both are shared by the search field and the sort menu.

import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/features/books/data/book_search.dart';
import 'package:takwa/features/books/data/books_data.dart';

IslamicBook _book({
  required String id,
  required String titleAr,
  String authorAr = 'مؤلف',
  String descriptionAr = '',
  BookCategory category = BookCategory.hadith,
  int publishYear = 100,
}) => IslamicBook(
  id: id,
  titleAr: titleAr,
  titleEn: id,
  authorAr: authorAr,
  authorEn: 'Author',
  descriptionAr: descriptionAr,
  emoji: '📚',
  category: category,
  publishYear: publishYear,
  coverColor: '0xFFC8A96E',
  coverColor2: '0xFF3AAFA9',
);

void main() {
  group('normalizeArabic', () {
    test('strips tashkeel and tatweel', () {
      expect(
        normalizeArabic('القُرْآن الكَريٓم'),
        equals('القران الكريم'.replaceAll('ـ', '')),
      );
    });

    test('folds alef variants, yaa, teh and waw hamza onto one letter', () {
      const inputs = ['أإآٱا', 'ىیئ', 'ةه', 'ؤو'];
      expect(normalizeArabic(inputs[0]), equals('ااااا'));
      expect(normalizeArabic(inputs[1]), equals('ييي'));
      expect(normalizeArabic(inputs[2]), equals('هه'));
      expect(normalizeArabic(inputs[3]), equals('وو'));
    });

    test('collapses whitespace and lowercases latin', () {
      expect(normalizeArabic('  Ibn   Hajar  '), equals('ibn hajar'));
    });

    test('leaves an already-normal string untouched', () {
      const s = 'صحيح البخاري';
      expect(normalizeArabic(s), equals(s));
    });
  });

  group('bookMatchesNormalizedQuery', () {
    final books = [
      _book(
        id: 'bukhari',
        titleAr: 'صحيح البخاري',
        authorAr: 'محمد بن إسماعيل البخاري',
        descriptionAr: 'أصحُّ الكتب بعد القرآن',
      ),
      _book(
        id: 'nawawi',
        titleAr: 'الأربعاء النووية',
        authorAr: 'يحيى بن شرف النووي',
        category: BookCategory.fiqh,
      ),
    ];

    test('matches a title written without hamza or alef madda', () {
      expect(
        bookMatchesNormalizedQuery(books[0], normalizeArabic('بخاري')),
        isTrue,
      );
    });

    test('matches tashkeel-free against a fully-vowelised description', () {
      expect(
        bookMatchesNormalizedQuery(books[0], normalizeArabic('أصح الكتب')),
        isTrue,
      );
    });

    test('matches the Latin title and the author', () {
      expect(
        bookMatchesNormalizedQuery(books[1], normalizeArabic('nawawi')),
        isTrue,
      );
      expect(
        bookMatchesNormalizedQuery(books[1], normalizeArabic('النووي')),
        isTrue,
      );
    });

    test('does not match unrelated text', () {
      expect(
        bookMatchesNormalizedQuery(books[1], normalizeArabic('زاد')),
        isFalse,
      );
    });

    test('an empty query matches everything', () {
      expect(
        bookMatchesNormalizedQuery(books.first, normalizeArabic('   ')),
        isTrue,
      );
    });
  });

  group('sortBooks', () {
    final books = [
      _book(id: 'c', titleAr: 'زاد المعاد', authorAr: 'ابن القيم', publishYear: 751),
      _book(id: 'a', titleAr: 'الأربعون النووية', authorAr: 'النووي', publishYear: 676),
      _book(id: 'b', titleAr: 'رياض الصالحين', authorAr: 'النووي', publishYear: 0),
    ];

    test('title order ignores alef-hamza differences', () {
      final ids = sortBooks(books, BookSortOrder.title).map((b) => b.id).toList();
      expect(ids, equals(['a', 'b', 'c']));
    });

    test('author order breaks ties on title', () {
      final ids = sortBooks(books, BookSortOrder.author).map((b) => b.id).toList();
      expect(ids, equals(['c', 'a', 'b']));
    });

    test('year order parks unknown years last', () {
      final ids = sortBooks(books, BookSortOrder.year).map((b) => b.id).toList();
      expect(ids, equals(['a', 'c', 'b']));
    });

    test('recent order puts unread books after the most recently read', () {
      final ids = sortBooks(
        books,
        BookSortOrder.recent,
        lastRead: {
          'b': DateTime(2026, 9, 1),
          'c': DateTime(2026, 9, 20),
        },
      ).map((b) => b.id).toList();
      expect(ids, equals(['c', 'b', 'a']));
    });

    test('does not reorder the caller list', () {
      final original = [...books];
      sortBooks(books, BookSortOrder.title);
      expect(
        books.map((b) => b.id).toList(),
        equals(original.map((b) => b.id).toList()),
      );
    });
  });
}
