// Bottom-nav behaviour for the redesigned bar: the three worship tabs render
// through flutter_islamic_icons (outline when inactive, solid when active),
// the gold pill slides to the tapped cell, it never escapes the capsule at
// either end, and it mirrors correctly under Arabic.
//
// Harness is copied from test/widget_test.dart on purpose — same provider
// overrides, same phone-sized surface, same bounded pumps instead of
// pumpAndSettle (HomeScreen's next-prayer pulse repeats forever, so "settled"
// is never reached), and the same explicit tear-down so Drift's chained
// zero-duration cleanup timers don't trip flutter_test's pending-timer check.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/app/main_shell.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/l10n/app_localizations.dart';

const _capsule = Key('bottomNavCapsule');

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpShell(WidgetTester tester, {Locale? locale}) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    tester.view.physicalSize = const Size(428, 926);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // See test/widget_test.dart: HomeScreen's section headers overflow by a
    // few pixels at some widths once async data lands. Real, pre-existing,
    // and unrelated to the bar — but it must not mask a genuine nav failure.
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
          ramadanModeProvider.overrideWith((ref) => Stream.value(false)),
          todayRecordProvider.overrideWith((ref) => Stream.value(null)),
          currentStreakProvider.overrideWith((ref) => Stream.value(0)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(locale ?? const Locale('en')),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> settleBar(WidgetTester tester) async {
    // Pill slide is 280ms, per-tab bounce 300ms.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  }

  Finder pill(Finder scope) => find
      .descendant(
        of: scope,
        matching: find.byType(AnimatedPositionedDirectional),
      )
      .first;

  testWidgets('worship tabs use IslamicIcons, solid for the active tab', (
    tester,
  ) async {
    await pumpShell(tester);

    // Home is selected on boot, so it shows the filled pair while Qiyam and
    // Muhasaba show their outlines. These three glyphs exist nowhere else in
    // the app, so a bare find is unambiguous.
    expect(find.byIcon(FlutterIslamicIcons.solidMosque), findsOneWidget);
    expect(find.byIcon(FlutterIslamicIcons.mosque), findsNothing);
    expect(find.byIcon(FlutterIslamicIcons.crescentMoon), findsOneWidget);
    expect(find.byIcon(FlutterIslamicIcons.prayer), findsOneWidget);

    await teardown(tester);
  });

  testWidgets('tapping a tab slides the pill and swaps that pair to solid', (
    tester,
  ) async {
    await pumpShell(tester);

    final scope = find.byKey(_capsule);
    final before = tester
        .widget<AnimatedPositionedDirectional>(pill(scope))
        .start;

    await tester.tap(find.byIcon(FlutterIslamicIcons.crescentMoon));
    await settleBar(tester);

    final after = tester
        .widget<AnimatedPositionedDirectional>(pill(scope))
        .start;
    expect(after, greaterThan(before!));
    expect(
      find.byIcon(FlutterIslamicIcons.solidCrescentMoon),
      findsOneWidget,
      reason: 'Qiyam is now the selected tab',
    );
    expect(
      find.byIcon(FlutterIslamicIcons.mosque),
      findsOneWidget,
      reason: 'Home fell back to its outline glyph',
    );

    await teardown(tester);
  });

  testWidgets('pill stays inside the capsule at the first and last cell', (
    tester,
  ) async {
    await pumpShell(tester);

    final scope = find.byKey(_capsule);
    final capsule = tester.getRect(scope);

    for (final icon in [
      FlutterIslamicIcons.crescentMoon,
      FlutterIslamicIcons.prayer,
      Icons.bar_chart_outlined,
      Icons.settings_outlined,
    ]) {
      await tester.tap(find.byIcon(icon));
      await settleBar(tester);

      final rect = tester.getRect(pill(scope));
      expect(
        rect.left >= capsule.left - 0.5 && rect.right <= capsule.right + 0.5,
        isTrue,
        reason: 'pill $rect must not escape capsule $capsule',
      );
      expect(rect.top >= capsule.top - 0.5, isTrue);
      expect(rect.bottom <= capsule.bottom + 0.5, isTrue);
    }

    await teardown(tester);
  });

  testWidgets('Arabic RTL mirrors the pill to the opposite edge', (
    tester,
  ) async {
    await pumpShell(tester, locale: const Locale('ar'));

    final scope = find.byKey(_capsule);
    final capsule = tester.getRect(scope);
    final homePill = tester.getRect(pill(scope));

    // Tab 0 is the right-most cell in RTL, so the pill hugs the right edge.
    expect(
      homePill.center.dx,
      greaterThan(capsule.center.dx),
      reason: 'first RTL tab should sit right of centre',
    );

    await tester.tap(find.byIcon(FlutterIslamicIcons.crescentMoon));
    await settleBar(tester);
    final secondPill = tester.getRect(pill(scope));
    expect(
      secondPill.center.dx,
      lessThan(homePill.center.dx),
      reason: 'RTL travel goes right-to-left',
    );

    await teardown(tester);
  });
}
