// Bottom-nav behaviour for the redesigned bar: the three worship tabs render
// through flutter_islamic_icons (outline when inactive, solid when active),
// the active tab is marked by gold tint alone — no cell carries a filled
// background — and the cells lay out mirrored under Arabic.
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

  Color Function(IconData) iconColorIn(WidgetTester tester) {
    return (icon) => tester.widget<Icon>(find.byIcon(icon)).color!;
  }

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

  testWidgets('the active tab is tinted gold and swaps that pair to solid', (
    tester,
  ) async {
    await pumpShell(tester);

    final colors =
        Theme.of(tester.element(find.byKey(_capsule)))
            .extension<AppColorsExtension>()!;
    final iconColor = iconColorIn(tester);

    expect(iconColor(FlutterIslamicIcons.solidMosque), colors.goldText);
    expect(iconColor(FlutterIslamicIcons.crescentMoon), colors.textDim);

    await tester.tap(find.byIcon(FlutterIslamicIcons.crescentMoon));
    await settleBar(tester);

    expect(
      iconColor(FlutterIslamicIcons.solidCrescentMoon),
      colors.goldText,
      reason: 'Qiyam is now the selected tab',
    );
    expect(iconColor(FlutterIslamicIcons.mosque), colors.textDim);
    expect(
      find.byIcon(FlutterIslamicIcons.solidMosque),
      findsNothing,
      reason: 'Home fell back to its outline glyph',
    );

    await teardown(tester);
  });

  testWidgets('no tab cell carries a filled background', (tester) async {
    await pumpShell(tester);

    final scope = find.byKey(_capsule);
    final capsule = tester.getRect(scope);

    expect(
      find.descendant(
        of: scope,
        matching: find.byType(AnimatedPositionedDirectional),
      ),
      findsNothing,
      reason: 'the sliding selection pill was removed from the bar',
    );
    expect(
      find.descendant(of: scope, matching: find.byType(DecoratedBox)),
      findsNothing,
      reason: 'only the bar capsule paints; nothing decorates a single cell',
    );

    // Selection still has to survive without the fill, so the outline→solid
    // swap and the gold tint must both move with the tap.
    final colors =
        Theme.of(tester.element(find.byKey(_capsule)))
            .extension<AppColorsExtension>()!;
    final iconColor = iconColorIn(tester);

    await tester.tap(find.byIcon(FlutterIslamicIcons.crescentMoon));
    await settleBar(tester);
    expect(iconColor(FlutterIslamicIcons.solidCrescentMoon), colors.goldText);
    expect(iconColor(FlutterIslamicIcons.mosque), colors.textDim);

    await tester.tap(find.byIcon(FlutterIslamicIcons.prayer));
    await settleBar(tester);
    expect(
      iconColor(FlutterIslamicIcons.solidPrayer),
      colors.goldText,
      reason: 'Muhasaba is now the selected tab',
    );
    expect(
      iconColor(FlutterIslamicIcons.crescentMoon),
      colors.textDim,
      reason: 'Qiyam drops back to the inactive tint',
    );

    // Nothing slides any more, so cell geometry is a static property: every
    // glyph — including the two end cells — sits inside the capsule. Home is
    // re-selected first so the expected glyph set is the boot-time one.
    await tester.tap(find.byIcon(FlutterIslamicIcons.mosque));
    await settleBar(tester);
    for (final icon in [
      FlutterIslamicIcons.solidMosque,
      FlutterIslamicIcons.crescentMoon,
      FlutterIslamicIcons.prayer,
      Icons.bar_chart_outlined,
      Icons.settings_outlined,
    ]) {
      final rect = tester.getRect(find.byIcon(icon));
      expect(
        rect.left >= capsule.left && rect.right <= capsule.right,
        isTrue,
        reason: 'icon $rect must not escape capsule $capsule',
      );
      expect(rect.top >= capsule.top, isTrue);
      expect(rect.bottom <= capsule.bottom, isTrue);
    }

    await teardown(tester);
  });

  testWidgets('Arabic RTL puts the first tab at the right edge', (
    tester,
  ) async {
    await pumpShell(tester, locale: const Locale('ar'));

    final capsule = tester.getRect(find.byKey(_capsule));
    final home = tester.getRect(find.byIcon(FlutterIslamicIcons.solidMosque));

    // Tab 0 is the right-most cell in RTL.
    expect(
      home.center.dx,
      greaterThan(capsule.center.dx),
      reason: 'first RTL tab should sit right of centre',
    );

    await tester.tap(find.byIcon(FlutterIslamicIcons.crescentMoon));
    await settleBar(tester);
    final qiyam = tester.getRect(
      find.byIcon(FlutterIslamicIcons.solidCrescentMoon),
    );
    expect(
      qiyam.center.dx,
      lessThan(home.center.dx),
      reason: 'RTL cell order goes right-to-left',
    );

    await teardown(tester);
  });
}
