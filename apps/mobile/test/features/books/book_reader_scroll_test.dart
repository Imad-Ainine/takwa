// The reader's scrolling contract.
//
// Pages of a chapter are one lazily-built list, and the page shown in the
// chrome is derived from where the scroll actually is. These tests pin the
// three things that used to break: opening a book whose rows carry no chapter
// text (RangeError, white screen), page turns that did not move the viewport,
// and progress that never reached storage.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/database/daos.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/providers/shared_preferences_provider.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/books/data/books_data.dart';
import 'package:takwa/features/books/presentation/screens/book_reader_screen.dart';
import 'package:takwa/l10n/app_localizations.dart';

import '../../support/fake_supabase_service.dart';

/// Page-turn chrome in RTL: the left chevron advances.
Finder _next() => find.byIcon(Icons.chevron_left);
Finder _prev() => find.byIcon(Icons.chevron_right);

double _offset(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

/// Taps the middle of the reading surface — the text column, away from both
/// bars.
Future<void> _tapReadingArea(WidgetTester tester) async {
  await tester.tap(find.byType(CustomScrollView));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
}

/// Each bar keys the `IgnorePointer` that gates its touch input, which is also
/// the node the slide/fade animations wrap.
const _topChromeKey = ValueKey('reader-chrome-top');
const _bottomChromeKey = ValueKey('reader-chrome-bottom');

/// One control per bar, used to ask where that bar paints: the top bar's gear,
/// the bottom bar's "next" chevron.
const _topBarControl = Icons.settings_outlined;
const _bottomBarControl = Icons.chevron_left;

/// Where a bar's control actually paints. The slide moves the paint, so a
/// hidden bar reports a centre outside the 800×600 test window.
double _controlTop(WidgetTester tester, IconData control) =>
    tester.getTopLeft(find.byIcon(control)).dy;

/// Whether a bar currently takes taps.
bool _chromeIgnoring(WidgetTester tester, Key key) =>
    tester.widget<IgnorePointer>(find.byKey(key)).ignoring;

IslamicBook _book({
  int chapters = 2,
  int pages = 4,
  String? pdfUrl,
  bool empty = false,
}) => IslamicBook(
  id: empty ? 'empty_book' : 'test_book',
  titleAr: 'كتاب الاختبار',
  titleEn: 'Test Book',
  authorAr: 'مؤلف',
  authorEn: 'Author',
  descriptionAr: 'وصف',
  emoji: '📚',
  category: BookCategory.hadith,
  publishYear: 1,
  coverColor: '0xFFC8A96E',
  coverColor2: '0xFF3AAFA9',
  pdfUrl: pdfUrl,
  chapters: empty
      ? const []
      : [
          for (var c = 0; c < chapters; c++)
            BookChapter(
              index: c,
              titleAr: 'الفصل ${c + 1}',
              pages: [
                for (var p = 0; p < pages; p++)
                  // Long enough that one page overflows the 800×600 test
                  // window: a chapter that fits on screen has no scroll
                  // extent, and the reader would have nothing to turn.
                  BookPage(
                    index: p,
                    title: 'الفصل ${c + 1}',
                    content: 'نص الفصل ${c + 1} صفحة ${p + 1}\n' * 120,
                  ),
              ],
            ),
        ],
);

void main() {
  late AppDatabase db;
  late FakeSupabaseService supabase;
  late AppLocalizations l10n;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    supabase = FakeSupabaseService();
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  tearDown(() async {
    await db.close();
  });

  /// Unmounts the tree and lets the reader's dispose-time save settle, so no
  /// Drift write or debounce timer outlives the test body.
  Future<void> closeReader(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpReader(
    WidgetTester tester,
    IslamicBook book, {
    int chapter = 0,
    int page = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          supabaseServiceProvider.overrideWithValue(supabase),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: BookReaderScreen(
            book: book,
            initialChapterIndex: chapter,
            initialPageIndex: page,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// "3 من 8" — the reader's own page read-out.
  String pageIndicator(int done, int total) =>
      l10n.bookReaderPageProgress('$done', '$total');

  group('opening', () {
    testWidgets('renders the first page of the chapter', (tester) async {
      await pumpReader(tester, _book());
      expect(find.textContaining('نص الفصل 1 صفحة 1'), findsWidgets);
      expect(find.text(pageIndicator(1, 8)), findsOneWidget);
      await closeReader(tester);
    });

    testWidgets('restores a saved page without starting from the top', (
      tester,
    ) async {
      await pumpReader(tester, _book(), chapter: 1, page: 2);
      expect(find.text(pageIndicator(7, 8)), findsOneWidget);
      await closeReader(tester);
    });

    testWidgets('a chapter-less book shows a message instead of crashing', (
      tester,
    ) async {
      await pumpReader(tester, _book(empty: true, pdfUrl: 'https://x/y.pdf'));
      expect(find.text(l10n.bookReaderContentUnavailable), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);
      await closeReader(tester);
    });

    testWidgets('a metadata-only book offers no PDF shortcut', (tester) async {
      await pumpReader(tester, _book(empty: true));
      expect(find.text(l10n.bookReaderContentUnavailable), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      await closeReader(tester);
    });
  });

  group('page turns', () {
    testWidgets('next advances one page and moves the viewport', (
      tester,
    ) async {
      await pumpReader(tester, _book());
      final before = _offset(tester);

      await tester.tap(_next());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(pageIndicator(2, 8)), findsOneWidget);
      expect(_offset(tester), greaterThan(before));
      await closeReader(tester);
    });

    testWidgets('previous returns to the first page of the book', (
      tester,
    ) async {
      await pumpReader(tester, _book(), chapter: 1, page: 0);
      expect(find.text(pageIndicator(5, 8)), findsOneWidget);

      await tester.tap(_prev());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Back across the chapter boundary into chapter 1's last page.
      expect(find.text(pageIndicator(4, 8)), findsOneWidget);
      expect(find.text('الفصل 1'), findsWidgets);
      await closeReader(tester);
    });

    testWidgets('the last page of the book disables next', (tester) async {
      await pumpReader(tester, _book(), chapter: 1, page: 3);
      expect(find.text(pageIndicator(8, 8)), findsOneWidget);

      await tester.tap(_next());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(pageIndicator(8, 8)), findsOneWidget);
      await closeReader(tester);
    });

    testWidgets('turning past a chapter boundary loads the next chapter', (
      tester,
    ) async {
      await pumpReader(tester, _book(chapters: 2, pages: 2));
      await tester.tap(_next());
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(_next());
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(pageIndicator(3, 4)), findsOneWidget);
      expect(find.textContaining("نص الفصل 2 صفحة 1"), findsWidgets);
      await closeReader(tester);
    });
  });

  /// Taps next [times] times, letting each turn's animation finish before the
  /// next one, then waits out the 700 ms save debounce and gives the Drift
  /// write's await chain a few microtask flushes to actually land.
  Future<void> turnPages(WidgetTester tester, int times) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(_next());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 900));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('persistence', () {
    testWidgets('a page turn is stored in Drift after the debounce', (
      tester,
    ) async {
      await pumpReader(tester, _book());
      await turnPages(tester, 1);

      final row = await BookProgressDao(db).getProgress('test_book');
      expect(row?.chapterIndex, 0);
      expect(row?.pageIndex, 1);
      await closeReader(tester);
    });

    testWidgets('rapid turns store the position actually reached', (
      tester,
    ) async {
      await pumpReader(tester, _book(pages: 20, chapters: 1));
      await turnPages(tester, 5);

      final row = await BookProgressDao(db).getProgress('test_book');
      expect(row?.pageIndex, 5);
      await closeReader(tester);
    });

    testWidgets('closing mid-chapter still saves the position', (tester) async {
      await pumpReader(tester, _book());
      await tester.tap(_next());
      await tester.pump(const Duration(milliseconds: 200));
      await closeReader(tester);

      final row = await BookProgressDao(db).getProgress('test_book');
      expect(row?.pageIndex, 1);
    });
  });

  group('distraction-free chrome', () {
    testWidgets('one tap hides both bars, the next tap brings them back', (
      tester,
    ) async {
      await pumpReader(tester, _book());
      expect(_chromeIgnoring(tester, _topChromeKey), isFalse);
      expect(_chromeIgnoring(tester, _bottomChromeKey), isFalse);
      expect(_controlTop(tester, _topBarControl), inInclusiveRange(0, 600));
      expect(_controlTop(tester, _bottomBarControl), inInclusiveRange(0, 600));

      await _tapReadingArea(tester);
      // Slid clear of the screen and no longer reachable by touch.
      expect(_controlTop(tester, _topBarControl), lessThan(0));
      expect(_controlTop(tester, _bottomBarControl), greaterThan(600));
      expect(_chromeIgnoring(tester, _topChromeKey), isTrue);
      expect(_chromeIgnoring(tester, _bottomChromeKey), isTrue);

      await _tapReadingArea(tester);
      expect(_controlTop(tester, _topBarControl), inInclusiveRange(0, 600));
      expect(_controlTop(tester, _bottomBarControl), inInclusiveRange(0, 600));
      expect(_chromeIgnoring(tester, _topChromeKey), isFalse);
      await closeReader(tester);
    });

    testWidgets('hidden bars cannot be tapped through the page', (
      tester,
    ) async {
      await pumpReader(tester, _book());
      final nextSpot = tester.getCenter(_next());
      await _tapReadingArea(tester);

      // The bar is gone, so a tap where "next" used to be only brings it back.
      await tester.tapAt(nextSpot);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      expect(find.text(pageIndicator(1, 8)), findsOneWidget);
      expect(_chromeIgnoring(tester, _bottomChromeKey), isFalse);

      // Now the same tap turns the page.
      await tester.tap(_next());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(pageIndicator(2, 8)), findsOneWidget);
      await closeReader(tester);
    });

    testWidgets('hiding the bars leaves the reading position alone', (
      tester,
    ) async {
      await pumpReader(tester, _book());
      await tester.tap(_next());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final before = _offset(tester);

      await _tapReadingArea(tester);
      expect(_offset(tester), before);
      expect(find.text(pageIndicator(2, 8)), findsOneWidget);

      // Scrolling still works with the chrome out of the way, and a scroll
      // does not decide to bring it back.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(_offset(tester), greaterThan(before));
      expect(_chromeIgnoring(tester, _bottomChromeKey), isTrue);
      await closeReader(tester);
    });
  });
}
