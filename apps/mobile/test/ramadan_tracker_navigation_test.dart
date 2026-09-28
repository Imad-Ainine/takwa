import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/app/main_shell.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/ramadan/presentation/screens/ramadan_tracker_screen.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// The route existed and the screen was built, but the only tile pointing at it
/// was gated on the Hijri month of Ramadan, so for eleven months a year nothing
/// in the app could reach it.
void main() {
  AppDatabase newDb() {
    SharedPreferences.setMockInitialValues({});
    return AppDatabase.forTesting(NativeDatabase.memory());
  }

  Future<void> pumpHome(WidgetTester tester, AppDatabase db) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // The drawer overflows horizontally at this width for reasons unrelated to
    // this test; home_cards_test.dart filters the same noise.
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
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const MainShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the home feature grid reaches the tracker year-round', (
    WidgetTester tester,
  ) async {
    final db = newDb();
    // Closed in the body below; this only matters if the test fails first, and
    // a second close is a no-op.
    addTearDown(db.close);
    await pumpHome(tester, db);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(MainShell)),
    )!;
    final label = find.text(l10n.homeFeatureRamadan);
    expect(label, findsOneWidget);

    // Home has more than one vertical scrollable ancestor and naming the right
    // one for scrollUntilVisible is brittle. A tall surface puts the tile on
    // screen instead; the layout above it is unchanged.
    await tester.binding.setSurfaceSize(const Size(390, 2000));
    await tester.pump();

    await tester.tap(
      find.ancestor(of: label, matching: find.byType(TakwaTappable)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(RamadanTrackerScreen), findsOneWidget);

    // Unwind inside the body: the tracker's 1s periodic timer and drift's
    // zero-delay stream-close timers have to be flushed while the test can
    // still pump, or the post-test invariant check fails the run.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await db.close();
  });
}
