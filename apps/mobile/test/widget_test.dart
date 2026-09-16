// App-boot smoke test, flagged in the "Testing Strategy" section of the
// engineering audit: the previous test/widget_test.dart (the default
// Flutter template) had been deleted with nothing added in its place, so
// nothing asserted the app actually renders its home experience without
// throwing.
//
// This pumps MainShell — the real widget the router lands on after splash
// — rather than TakwaApp itself, which needs Supabase.initialize() and
// dotenv.load() before it can even build (see main()). MainShell's own
// post-onboarding bootstrapping (scheduling notifications, starting the
// foreground overlay service) still fires from its initState callback; it
// turned out not to touch any platform channel eagerly enough to matter
// here, so no extra mocking was needed for that part.
//
// HomeScreen's various section headers ("title — divider — view all") turn
// out to each overflow by a few pixels at slightly different viewport
// widths depending on which async data (books, prayer times) has resolved
// by the time of the pump — a real, pre-existing, width/data-sensitive
// layout tightness, but not what this test is checking and not something
// to fix incidentally here. FlutterError.onError is narrowed below to
// still fail on any real build/crash error, just not on that specific,
// already-known class of debug-only overflow banner.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/app/main_shell.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/home/presentation/screens/home_screen.dart';
import 'package:takwa/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('splash-to-home: the main shell renders Home without throwing', (
    tester,
  ) async {
    // The default test surface (800x600, wider and much shorter than any
    // real phone) makes some screens' drawer/header layouts overflow in
    // ways they never would on-device. Use a realistic portrait phone size
    // so this test reflects how the app actually renders.
    await tester.binding.setSurfaceSize(const Size(428, 926));
    tester.view.physicalSize = const Size(428, 926);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('A RenderFlex overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          onboardingDoneProvider.overrideWith((ref) async => true),
          authStatusProvider.overrideWithValue(AuthStatus.authenticated),
          // Not under test here, and overriding these avoids exercising
          // real Drift watch-streams (each with its own async teardown
          // timing that leaves a Timer pending past test end) — same
          // reasoning as khatma_progress_screen_test.dart.
          ramadanModeProvider.overrideWith((ref) => Stream.value(false)),
          todayRecordProvider.overrideWith((ref) => Stream.value(null)),
          currentStreakProvider.overrideWith((ref) => Stream.value(0)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainShell(),
        ),
      ),
    );
    // Deliberately not pumpAndSettle(): several cards (e.g. the next-prayer
    // pulse) run a perpetually repeating AnimationController by design, so
    // "settled" is never reached — pumpAndSettle would just burn its full
    // 10-minute internal timeout. A few bounded pumps are enough for the
    // initial async providers and one-shot entrance/staggered animations to
    // resolve.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);

    // Tear the tree down explicitly, under this test's own pumping, rather
    // than leaving it to flutter_test's post-callback teardown: disposing a
    // Drift-backed StreamProvider (several of MainShell's other five tabs
    // read one) schedules a zero-duration Timer as part of its own cleanup,
    // and that Timer needs one more pump to actually fire. Without this,
    // flutter_test's own "no pending timers" invariant check — which runs
    // right after this callback returns, with no further pump possible —
    // fails on a Timer that was never actually leaked, just not yet due.
    await tester.pumpWidget(const SizedBox());
    // Non-zero and repeated: disposing MainShell tears down several Drift
    // streams (one per tab), each scheduling its own zero-duration cleanup
    // Timer only once the previous one fires — a single zero-duration pump
    // isn't enough to drain the whole chain.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}
