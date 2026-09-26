// P1 #3 regression: PrayerNotifier's 1 Hz ticker must NOT push a new
// PrayerScreenState every second. Before the fix, each tick assigned a
// freshly computed `remaining` Duration, so every watcher (PrayerScreen's
// whole tree and HomeScreen's kept-alive 11-section scroll view) rebuilt
// once per second for the app's entire lifetime. Now only discrete changes
// (next prayer / iqama phase / city / loading / prayer-list reload) reach
// the state, and the per-second countdown lives in
// prayerClockTickProvider consumers.
//
// Note: testWidgets pumps VIRTUAL time while DateTime.now() stays on the
// real clock, so fixtures place times minutes/hours away and discrete
// transitions are provoked by reloading prayerTimesProvider, never by
// pumping past an adhan timestamp.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/features/prayer/presentation/screens/prayer_screen.dart';

PrayerTimeInfo _p(
  String name,
  String nameAr,
  String emoji,
  DateTime time,
  int id,
) => PrayerTimeInfo(
  name: name,
  nameAr: nameAr,
  emoji: emoji,
  time: time,
  notifId: id,
);

/// Seeds a resolved location so PrayerNotifier._init() skips
/// LocationPrayerManager (real platform channel) — same trick as
/// prayer_screen_test.dart.
Future<void> _seedLocation(AppDatabase db) async {
  await db.settingsDao.set('latitude', '21.4225');
  await db.settingsDao.set('longitude', '39.8262');
  await db.settingsDao.set('cityName', 'مكة المكرمة');
}

/// Full in-body unwind: flutter_test's "no pending timers" invariant runs
/// BEFORE addTearDown callbacks, so anything that owns a timer must be
/// unwound here, not in teardown. Order that actually works (proven by
/// scratch bisect): unmount the tree, dispose the container, then pump a
/// few times — container.dispose() unwinds drift stream queries via
/// StreamQueryStore.markAsClosed, which schedules a 0-duration timer that
/// only fires on the next pump. The addTearDown fallbacks still run when
/// the body throws early.
Future<void> _tearDownAll(
  WidgetTester tester,
  ProviderContainer container,
  AppDatabase db,
) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  await db.close();
}

void main() {
  testWidgets(
    'prayerScreenProvider emits no new state across several 1s ticks '
    '(P1 #3 rebuild-storm regression)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedLocation(db);

      final now = DateTime.now();
      final times = [
        _p(
          'dhuhr',
          'الظهر',
          '☀️',
          now.subtract(const Duration(minutes: 10)),
          3,
        ),
        // ~2.5h ahead: far from both the adhan and the iqama boundary, so
        // no discrete state change can legitimately occur during ticks.
        _p('asr', 'العصر', '🌤', now.add(const Duration(minutes: 150)), 4),
      ];

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          prayerTimesProvider.overrideWith((ref) async => times),
        ],
      );
      addTearDown(container.dispose);

      var builds = 0;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              builds++;
              final st = ref.watch(prayerScreenProvider);
              return Text(
                st.next?.name ?? '-',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      // Let _init() resolve prayer times and start the ticker.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('asr'), findsOneWidget, reason: 'next prayer resolved');
      final buildsAfterInit = builds;

      // Five 1-second ticker ticks must not rebuild the watcher.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(
        builds,
        buildsAfterInit,
        reason: 'state must be immutable between discrete changes',
      );

      // The shared clock DOES keep ticking — the countdown widgets get
      // their per-second refresh from here instead of the notifier.
      final stamps = <DateTime>[];
      final sub = container.listen<AsyncValue<DateTime>>(
        prayerClockTickProvider,
        (_, next) {
          final v = next.valueOrNull;
          if (v != null) stamps.add(v);
        },
      );
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      sub.close();
      expect(
        stamps.length,
        greaterThanOrEqualTo(2),
        reason: 'prayerClockTickProvider advances every second',
      );

      await _tearDownAll(tester, container, db);
    },
  );

  testWidgets(
    'a discrete next-prayer change still propagates',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedLocation(db);

      final now = DateTime.now();
      var times = [
        _p('asr', 'العصر', '🌤', now.add(const Duration(minutes: 60)), 4),
        _p('maghrib', 'المغرب', '🌆', now.add(const Duration(minutes: 120)), 5),
      ];

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          prayerTimesProvider.overrideWith((ref) async => times),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final st = ref.watch(prayerScreenProvider);
              return Text(
                st.next?.name ?? '-',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('asr'), findsOneWidget);

      // Reload with asr already past — the prayerTimesProvider listener
      // must push the new discrete state (next → maghrib) right away,
      // without waiting for the ticker's next second.
      times = [
        _p('asr', 'العصر', '🌤', now.subtract(const Duration(minutes: 1)), 4),
        _p('maghrib', 'المغرب', '🌆', now.add(const Duration(minutes: 120)), 5),
      ];
      container.invalidate(prayerTimesProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // The async reload completes on the microtask queue: the notifier's
      // state is already maghrib here, but the Consumer element needs one
      // more frame to repaint.
      await tester.pump();
      expect(
        find.text('maghrib'),
        findsOneWidget,
        reason: 'discrete state changes must still reach watchers',
      );

      await _tearDownAll(tester, container, db);
    },
  );
}
