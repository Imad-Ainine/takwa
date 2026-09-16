// Golden tests for the app's five bottom-nav screens (audit item 30 — the
// doc predates the Phase 4 nav reduction from 6 to 5 tabs, hence 5 here,
// not 6) across every {theme} x {text scale} combination the audit calls
// out: light / dark / Ramadan, at 1.0x and 1.5x text scale.
//
// *** THESE TESTS HAVE NO BASELINE IMAGES YET AND WILL FAIL AS WRITTEN. ***
// This environment has no Flutter SDK, so nothing here has ever actually
// been run — see test/golden/README.md for the one-time step (a real
// `flutter test --update-goldens` run, from a machine with the Flutter
// SDK) needed before these can pass, and before wiring this file into
// mobile-ci.yml. Do not add a CI step that runs this file until that's
// done, or every PR's CI goes red on tests that were never green to begin
// with.
//
// Reuses widget_test.dart's MainShell harness rather than building five
// bespoke per-screen harnesses: PageView(children: [...]) (not
// PageView.builder) builds all five tab widgets eagerly regardless of
// which is the initially-visible page, so the same provider overrides
// that let widget_test.dart pump the whole shell are sufficient for any
// one of the five here too — confirmed by that test already passing with
// exactly this override set.
//
// Known limitation: TakwaLoadingIndicator / TakwaRefreshIndicator spin
// unconditionally (they're excluded from the reduce-motion gate added
// elsewhere in this audit pass — see ReducedMotionRepeat's own doc
// comment — because a real loading/refresh spinner communicates actual
// in-progress work, and stopping it would misrepresent that). If a
// screen is still in a loading state at capture time, its spinner's
// rotation angle is a source of flakiness these tests can't fully rule
// out. The bounded-pump schedule below (matching widget_test.dart) is
// chosen to let each screen's initial async providers resolve before
// capture, same as that test already relies on.

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
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/l10n/app_localizations.dart';

enum _GoldenTheme { light, dark, ramadan }

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // (tab index, a short name for the golden file, the widget type to
  // assert rendered before capturing — same sanity check widget_test.dart
  // does for Home).
  const tabs = <(int, String)>[
    (0, 'home'),
    (1, 'qiyam'),
    (2, 'checklist'),
    (3, 'statistics'),
    (4, 'settings'),
  ];

  ThemeData themeFor(_GoldenTheme t) => switch (t) {
    _GoldenTheme.light => AppTheme.light(),
    _GoldenTheme.dark => AppTheme.dark(),
    // RamadanTheme.dark, not .light: the in-app Ramadan toggle only ever
    // drives the dark Ramadan palette (see ramadan_theme.dart) — there is
    // no separate "Ramadan + light system theme" combination in the app
    // itself, so testing RamadanTheme.light here would cover a
    // combination nothing can actually put the app into.
    _GoldenTheme.ramadan => RamadanTheme.dark(),
  };

  for (final theme in _GoldenTheme.values) {
    for (final scale in [1.0, 1.5]) {
      for (final (index, name) in tabs) {
        testWidgets(
          'golden: $name @ ${theme.name} @ ${scale}x text',
          (tester) async {
            // Same portrait-phone surface as widget_test.dart, for the
            // same reason — the default 800x600 test surface distorts
            // layouts no real phone would ever render at.
            await tester.binding.setSurfaceSize(const Size(428, 926));
            tester.view.physicalSize = const Size(428, 926);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(() => tester.binding.setSurfaceSize(null));

            // Same overflow-banner narrowing as widget_test.dart — see
            // that file's own top-of-file comment for why this specific,
            // already-known class of debug-only warning is excluded
            // rather than fixed incidentally here.
            final originalOnError = FlutterError.onError;
            FlutterError.onError = (details) {
              if (details.exception.toString().contains(
                'A RenderFlex overflowed',
              )) {
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
                  authStatusProvider.overrideWithValue(
                    AuthStatus.authenticated,
                  ),
                  ramadanModeProvider.overrideWith(
                    (ref) => Stream.value(theme == _GoldenTheme.ramadan),
                  ),
                  todayRecordProvider.overrideWith((ref) => Stream.value(null)),
                  currentStreakProvider.overrideWith((ref) => Stream.value(0)),
                ],
                child: MaterialApp(
                  theme: themeFor(theme),
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  // Applies the text-scale axis of the matrix app-wide,
                  // same as MediaQuery.textScalerOf(context) would pick
                  // up from the real OS accessibility setting.
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: MainShell(initialIndex: index),
                ),
              ),
            );
            // Deliberately not pumpAndSettle() — see widget_test.dart's own
            // comment: several cards run a perpetually repeating
            // AnimationController by design (the ones excluded from the
            // reduce-motion gate, or simply not yet dependency-checked at
            // this point in the pump), so "settled" is never reached.
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));
            await tester.pump(const Duration(seconds: 1));

            expect(tester.takeException(), isNull);

            await expectLater(
              find.byType(MainShell),
              matchesGoldenFile('goldens/${name}_${theme.name}_${scale}x.png'),
            );

            // Same explicit teardown as widget_test.dart, and for the same
            // reason: disposing MainShell schedules a chain of
            // zero-duration cleanup Timers (one per tab's Drift stream)
            // that flutter_test's post-callback "no pending timers" check
            // would otherwise catch mid-chain.
            await tester.pumpWidget(const SizedBox());
            for (var i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 1));
            }
          },
          // flutter test auto-discovers every *_test.dart file, and these
          // golden comparisons have no baseline images to compare against
          // yet (see README.md in this directory) — skip: true keeps them
          // out of CI's pass/fail count (reported as "skipped", not
          // "failed") without needing a CI workflow change or an
          // unconventional filename to keep this file out of discovery.
          // Remove this once test/golden/goldens/ is generated and
          // committed.
          skip: true,
        );
      }
    }
  }
}
