import 'books_data.dart';

/// Arabic-aware search and ordering for the Books library.
///
/// Arabic text rarely matches a naive `contains()`: a query typed without
/// diacritics misses a title stored with them, and أ إ آ ا (or ى/ي, ة/ه) are
/// the same letter to a reader. Both the stored value and the query are folded
/// through [normalizeArabic] before comparing.

/// Order the library can be displayed in. Persisted by name, so new values
/// must be appended rather than renumbered.
enum BookSortOrder {
  /// Alphabetical by Arabic title — the same order the server returns.
  title,
  author,

  /// Earliest hijri publication year first.
  year,

  /// Most recently opened first; unread books fall to the back.
  recent,
}

/// Diacritics and Quranic annotation marks carry no searchable value.
const _markRanges = <List<int>>[
  [0x0610, 0x061A],
  [0x064B, 0x065F],
  [0x0670, 0x0670],
  [0x06D6, 0x06DC],
  [0x06DF, 0x06E4],
  [0x06E7, 0x06E8],
  [0x06EA, 0x06ED],
  [0x08D3, 0x08FF],
];

bool _isMark(int rune) {
  for (final range in _markRanges) {
    if (rune >= range[0] && rune <= range[1]) return true;
  }
  return false;
}

/// Folds [input] so comparisons tolerate diacritics, letter-form variants and
/// stray whitespace. Latin text is lowercased.
String normalizeArabic(String input) {
  if (input.isEmpty) return '';
  final buffer = StringBuffer();
  var atLineStart = true;

  for (final rune in input.runes) {
    if (_isMark(rune)) continue;
    // Kashida is pure decoration; zero-width characters are invisible.
    if (rune == 0x0640 ||
        rune == 0x200B ||
        rune == 0x200C ||
        rune == 0x200D ||
        rune == 0xFEFF) {
      continue;
    }
    final char = String.fromCharCode(_foldedRune(rune));
    if (char == ' ' || char == '\n' || char == '\t') {
      if (!atLineStart) buffer.write(' ');
      atLineStart = true;
      continue;
    }
    atLineStart = false;
    buffer.write(char);
  }

  return buffer.toString().trim().toLowerCase();
}

/// Letter-form unification: alef/hamza variants, yaa, and ta marbuta all
/// collapse onto their base consonant.
int _foldedRune(int rune) => switch (rune) {
  // آ أ إ ٱ ا
  0x0622 || 0x0623 || 0x0625 || 0x0671 || 0x0627 => 0x0627,
  // ى ی ي ئ
  0x0649 || 0x06CC || 0x064A || 0x0626 => 0x064A,
  // ة ه
  0x0629 || 0x0647 => 0x0647,
  // ؤ و
  0x0624 || 0x0648 => 0x0648,
  _ => rune,
};

/// True when [book] matches an already-normalized [query].
///
/// Searches the Arabic title, author, description and category label, plus the
/// Latin title/author so an untranslated query still resolves.
bool bookMatchesNormalizedQuery(IslamicBook book, String query) {
  if (query.isEmpty) return true;
  return normalizeArabic(book.titleAr).contains(query) ||
      normalizeArabic(book.titleEn).contains(query) ||
      normalizeArabic(book.authorAr).contains(query) ||
      normalizeArabic(book.authorEn).contains(query) ||
      normalizeArabic(book.descriptionAr).contains(query) ||
      normalizeArabic(book.categoryLabel).contains(query);
}

/// Returns [books] in [order]. [lastRead] drives the `recent` ordering; books
/// without an entry keep their incoming relative order at the back.
List<IslamicBook> sortBooks(
  List<IslamicBook> books,
  BookSortOrder order, {
  Map<String, DateTime>? lastRead,
}) {
  final sorted = [...books];
  switch (order) {
    case BookSortOrder.title:
      sorted.sort(
        (a, b) => _byTextThen(
          normalizeArabic(a.titleAr),
          normalizeArabic(b.titleAr),
          normalizeArabic(a.authorAr),
          normalizeArabic(b.authorAr),
        ),
      );
    case BookSortOrder.author:
      sorted.sort(
        (a, b) => _byTextThen(
          normalizeArabic(a.authorAr),
          normalizeArabic(b.authorAr),
          normalizeArabic(a.titleAr),
          normalizeArabic(b.titleAr),
        ),
      );
    case BookSortOrder.year:
      // A zero year means "unknown"; park those at the end.
      sorted.sort((a, b) {
        if (a.publishYear == 0 && b.publishYear == 0) return 0;
        if (a.publishYear == 0) return 1;
        if (b.publishYear == 0) return -1;
        return a.publishYear.compareTo(b.publishYear);
      });
    case BookSortOrder.recent:
      final reads = lastRead ?? const <String, DateTime>{};
      sorted.sort((a, b) {
        final left = reads[a.id];
        final right = reads[b.id];
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });
  }
  return sorted;
}

int _byTextThen(String left, String right, String tieLeft, String tieRight) {
  final primary = left.compareTo(right);
  return primary != 0 ? primary : tieLeft.compareTo(tieRight);
}
