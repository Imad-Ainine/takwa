// Regression tests for StatsDao.getLongestStreak() and
// checkAndGrantAchievements(), rewritten to use targeted column
// selections / SQL aggregates instead of loading every daily_records row
// into memory. These lock in the same behavior the full-table-scan
// version had, so the performance rewrite couldn't change results.
//
// See the "Performance" section of the engineering audit for context.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/utils/ramadan_info.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Inserts a daily_records row for an arbitrary date with a preset
  /// netPoints (and optionally a fastingType), bypassing recalcPoints() —
  /// these tests care about the streak/aggregate math, not how points are
  /// derived.
  Future<void> seedDay(
    DateTime date, {
    required int netPoints,
    FastingType? fastingType,
  }) async {
    await db
        .into(db.dailyRecords)
        .insert(
          DailyRecordsCompanion.insert(
            date: date,
            netPoints: Value(netPoints),
            taqwaPoints: Value(netPoints),
            fastingType: fastingType != null
                ? Value(fastingType)
                : const Value.absent(),
          ),
        );
  }

  group('getLongestStreak', () {
    test('returns 0 when there is no history', () async {
      expect(await db.statsDao.getLongestStreak(), 0);
    });

    test('counts a single unbroken run of positive-point days', () async {
      final base = DateTime(2026, 1, 1);
      for (var i = 0; i < 5; i++) {
        await seedDay(base.add(Duration(days: i)), netPoints: 10);
      }
      expect(await db.statsDao.getLongestStreak(), 5);
    });

    test('a zero/negative day breaks the streak', () async {
      final base = DateTime(2026, 1, 1);
      await seedDay(base, netPoints: 10);
      await seedDay(base.add(const Duration(days: 1)), netPoints: 10);
      await seedDay(base.add(const Duration(days: 2)), netPoints: 0); // break
      await seedDay(base.add(const Duration(days: 3)), netPoints: 10);
      await seedDay(base.add(const Duration(days: 4)), netPoints: 10);
      await seedDay(base.add(const Duration(days: 5)), netPoints: 10);

      expect(await db.statsDao.getLongestStreak(), 3); // days 3-5
    });

    test('a gap in dates (missing day) breaks the streak', () async {
      final base = DateTime(2026, 1, 1);
      await seedDay(base, netPoints: 10);
      await seedDay(base.add(const Duration(days: 1)), netPoints: 10);
      // day 2 never logged at all
      await seedDay(base.add(const Duration(days: 3)), netPoints: 10);

      expect(await db.statsDao.getLongestStreak(), 2);
    });

    test('returns the longest run, not the most recent one', () async {
      final base = DateTime(2026, 1, 1);
      // A 4-day streak, a gap, then a 2-day streak.
      for (var i = 0; i < 4; i++) {
        await seedDay(base.add(Duration(days: i)), netPoints: 10);
      }
      await seedDay(base.add(const Duration(days: 4)), netPoints: 0);
      for (var i = 5; i < 7; i++) {
        await seedDay(base.add(Duration(days: i)), netPoints: 10);
      }
      expect(await db.statsDao.getLongestStreak(), 4);
    });
  });

  group('checkAndGrantAchievements — lifetime checks', () {
    test('fasting_nafl is granted once a single nafl fast is logged', () async {
      final record = await db.dailyRecordDao.getOrCreateToday();
      await db.dailyRecordDao.updateFasting(record.id, FastingType.nafl);

      final granted = await db.statsDao.checkAndGrantAchievements();
      expect(granted.map((a) => a.type), contains('fasting_nafl'));

      // Idempotent: calling again doesn't re-grant it.
      final grantedAgain = await db.statsDao.checkAndGrantAchievements();
      expect(grantedAgain.map((a) => a.type), isNot(contains('fasting_nafl')));
    });

    test('ramadan_knight requires at least 10 fard-fasting days', () async {
      final base = DateTime(2026, 1, 1);
      for (var i = 0; i < 9; i++) {
        await seedDay(
          base.add(Duration(days: i)),
          netPoints: 20,
          fastingType: FastingType.fard,
        );
      }
      var granted = await db.statsDao.checkAndGrantAchievements();
      expect(granted.map((a) => a.type), isNot(contains('ramadan_knight')));

      // 10th day of fard fasting tips it over.
      await seedDay(
        base.add(const Duration(days: 9)),
        netPoints: 20,
        fastingType: FastingType.fard,
      );
      granted = await db.statsDao.checkAndGrantAchievements();
      expect(granted.map((a) => a.type), contains('ramadan_knight'));
    });

    test(
      'ramadan_complete requires every day of the current Ramadan to be fasted',
      () async {
        final ramadanFirst = HijriCalendar()
          ..hYear = 1447
          ..hMonth = 9
          ..hDay = 1;
        final info = computeRamadanInfo(ramadanFirst);

        // Fast every day except the last one.
        for (var i = 0; i < info.totalDays - 1; i++) {
          await seedDay(
            info.gregorianStart.add(Duration(days: i)),
            netPoints: 20,
            fastingType: FastingType.fard,
          );
        }
        var granted = await db.statsDao.checkAndGrantAchievements(
          asOfHijri: ramadanFirst,
        );
        expect(granted.map((a) => a.type), isNot(contains('ramadan_complete')));

        // Fasting the final day completes the month.
        await seedDay(
          info.gregorianEnd,
          netPoints: 20,
          fastingType: FastingType.fard,
        );
        granted = await db.statsDao.checkAndGrantAchievements(
          asOfHijri: ramadanFirst,
        );
        expect(granted.map((a) => a.type), contains('ramadan_complete'));
      },
    );

    test(
      'an excused day (makruh) never counts toward ramadan_complete',
      () async {
        // FastingType.makruh means "broke the fast with an excuse", so it is
        // a day NOT fasted. The old query counted anything but `none`.
        final ramadanFirst = HijriCalendar()
          ..hYear = 1447
          ..hMonth = 9
          ..hDay = 1;
        final info = computeRamadanInfo(ramadanFirst);

        for (var i = 0; i < info.totalDays; i++) {
          await seedDay(
            info.gregorianStart.add(Duration(days: i)),
            netPoints: 0,
            fastingType: FastingType.makruh,
          );
        }
        var granted = await db.statsDao.checkAndGrantAchievements(
          asOfHijri: ramadanFirst,
        );
        expect(granted.map((a) => a.type), isNot(contains('ramadan_complete')));

        // One excused day among 29 fasted days still falls short of 30/30.
        await db.delete(db.dailyRecords).go();
        for (var i = 0; i < info.totalDays; i++) {
          await seedDay(
            info.gregorianStart.add(Duration(days: i)),
            netPoints: 20,
            fastingType: i == 0 ? FastingType.makruh : FastingType.fard,
          );
        }
        granted = await db.statsDao.checkAndGrantAchievements(
          asOfHijri: ramadanFirst,
        );
        expect(granted.map((a) => a.type), isNot(contains('ramadan_complete')));
      },
    );

    test(
      'ramadan_complete is not granted outside of Ramadan even with a full month fasted',
      () async {
        final ramadanFirst = HijriCalendar()
          ..hYear = 1447
          ..hMonth = 9
          ..hDay = 1;
        final info = computeRamadanInfo(ramadanFirst);
        for (var i = 0; i < info.totalDays; i++) {
          await seedDay(
            info.gregorianStart.add(Duration(days: i)),
            netPoints: 20,
            fastingType: FastingType.fard,
          );
        }

        final shawwal = HijriCalendar()
          ..hYear = 1447
          ..hMonth = 10
          ..hDay = 5;
        final granted = await db.statsDao.checkAndGrantAchievements(
          asOfHijri: shawwal,
        );
        expect(granted.map((a) => a.type), isNot(contains('ramadan_complete')));
      },
    );

    test('points_100 sums net points across every historical day', () async {
      final base = DateTime(2026, 1, 1);
      for (var i = 0; i < 5; i++) {
        await seedDay(base.add(Duration(days: i)), netPoints: 19);
      }
      var granted = await db.statsDao.checkAndGrantAchievements();
      expect(granted.map((a) => a.type), isNot(contains('points_100')));

      await seedDay(base.add(const Duration(days: 5)), netPoints: 10);
      granted = await db.statsDao.checkAndGrantAchievements();
      expect(granted.map((a) => a.type), contains('points_100'));
    });
  });
}
