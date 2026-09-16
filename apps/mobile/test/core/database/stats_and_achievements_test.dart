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
import 'package:takwa/core/database/app_database.dart';

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
