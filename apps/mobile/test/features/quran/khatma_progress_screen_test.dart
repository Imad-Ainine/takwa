// Widget smoke test. Picked as the first widget test in the suite because
// it's self-contained (SharedPreferences + an in-memory DB, no Supabase/
// dotenv/native-plugin bootstrapping like the real app shell needs) and it
// doubles as a regression test for the provider-migration bug fixed
// alongside it: this screen used to read a legacy provider nothing ever
// wrote to, so it always rendered a stuck-at-zero state.
//
// See the "Testing Strategy" section of the engineering audit for context.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/providers/shared_preferences_provider.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/quran/data/quran_models.dart';
import 'package:takwa/features/quran/presentation/screens/khatma_progress_screen.dart';
import 'package:takwa/features/quran/providers/quran_providers.dart';
import 'package:takwa/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The screen now also reads khatmaReadingStatsProvider (for the
    // reading-days calendar / streaks), which needs a real DailyRecordDao
    // — an in-memory Drift DB, same pattern as prayer_screen_test.dart,
    // rather than a real sqlite3 native binding that isn't available here.
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          // Not under test here, and overriding it avoids exercising a real
          // Drift watch-stream (with its own async teardown timing) for a
          // screen that doesn't otherwise touch the database.
          ramadanModeProvider.overrideWith((ref) => Stream.value(false)),
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
          home: const KhatmaProgressScreen(),
        ),
      ),
    );
    // Not pumpAndSettle(): the screen's app bar (AppBarWidget) runs a
    // perpetually repeating decorative AnimationController by design (see
    // widget_test.dart's own comment on the same pattern), so "settled" is
    // never reached — pumpAndSettle timed out here once the screen was
    // migrated onto AppBarWidget. A few bounded pumps are enough for the
    // async providers and one-shot animations to resolve.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('renders without throwing when there is no active khatma', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    // khatmaScreenTitle (AR)
    expect(find.text('تقدم الختمة'), findsOneWidget);
    // With no active khatma, the screen now shows a dedicated empty state
    // (khatmaProgressEmptyTitle, AR) instead of a misleading 0% ring.
    expect(find.text('لا توجد ختمة نشطة حالياً'), findsOneWidget);
  });

  testWidgets(
    'reflects live khatmaExProvider progress, not the legacy provider',
    (tester) async {
      await pumpScreen(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(KhatmaProgressScreen)),
      );
      await container
          .read(khatmaExProvider.notifier)
          .createNew(
            label: 'ختمة الاختبار',
            type: KhatmaType.muyassara,
            startPage: 1,
          );
      await container.read(khatmaExProvider.notifier).advancePage(61);
      // Same reasoning as pumpScreen() above — not pumpAndSettle().
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // pagesRead = 61 - 1 = 60; 60 / 604 * 100 = 9.9 (1dp), matching the
      // widget's own `(progress * 100).toStringAsFixed(1)` formatting.
      // khatmaProgressPercent('9.9') (AR) → '9.9٪ مكتملة'
      expect(tester.takeException(), isNull);
      expect(find.text('9.9٪ مكتملة'), findsOneWidget);
    },
  );
}
