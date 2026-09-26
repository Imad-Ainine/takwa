// Regression tests for StatsDao.getLongestStreak() and
// checkAndGrantAchievements(), rewritten to use targeted column
// selections / SQL aggregates instead of loading every daily_records row
// into memory. These lock in the same behavior the full-table-scan
// version had, so the performance rewrite couldn't change results.
//
// See the "Performance" section of the engineering audit for context.

import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  // The month/range statistics moved from "load every row, fold in Dart" to
  // single COUNT(*) FILTER / SUM() queries (P1 #5). These lock the aggregate
  // results — in particular the intEnum comparison behind `performed`, which
  // is easy to get wrong silently since both sides are just integers in SQL.
  group('aggregate statistics over a range', () {
    /// Two days in July 2026: day 1 has 3 of 5 prayers performed, day 2 has
    /// 2 of 5. Together: 5 performed out of 10 slots = 0.5.
    Future<void> seedPrayerDays() async {
      await db
          .into(db.dailyRecords)
          .insert(
            DailyRecordsCompanion.insert(
              date: DateTime(2026, 7, 1),
              netPoints: const Value(30),
              quranPages: const Value(12),
              fajrStatus: const Value(PrayerStatus.performed),
              dhuhrStatus: const Value(PrayerStatus.performed),
              asrStatus: const Value(PrayerStatus.performed),
              maghribStatus: const Value(PrayerStatus.missed),
              ishaStatus: const Value(PrayerStatus.qadaa),
            ),
          );
      await db
          .into(db.dailyRecords)
          .insert(
            DailyRecordsCompanion.insert(
              date: DateTime(2026, 7, 2),
              netPoints: const Value(20),
              quranPages: const Value(8),
              fajrStatus: const Value(PrayerStatus.performed),
              dhuhrStatus: const Value(PrayerStatus.performed),
              asrStatus: const Value(PrayerStatus.missed),
              maghribStatus: const Value(PrayerStatus.missed),
              ishaStatus: const Value(PrayerStatus.missed),
            ),
          );
    }

    test('getMonthStats sums points, pages and prayer rate', () async {
      await seedPrayerDays();
      final stats = await db.statsDao.getMonthStats(2026, 7);
      expect(stats.totalPoints, 50);
      expect(stats.quranPages, 20);
      expect(stats.prayerRate, 0.5);
    });

    test('getStatsForRange ignores days outside the range', () async {
      await seedPrayerDays();
      await seedDay(DateTime(2026, 8, 1), netPoints: 999);
      final stats = await db.statsDao.getStatsForRange(
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 2),
      );
      expect(stats.totalPoints, 50);
      expect(stats.quranPages, 20);
      expect(stats.prayerRate, 0.5);
    });

    test('getPerPrayerRates divides each prayer by the day count', () async {
      await seedPrayerDays();
      final rates = await db.statsDao.getPerPrayerRates(
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 2),
      );
      expect(rates.map((r) => r.rate), [1.0, 1.0, 0.5, 0.0, 0.0]);
    });

    test('an empty range yields zeros rather than dividing by zero', () async {
      final stats = await db.statsDao.getMonthStats(2026, 3);
      expect(stats.totalPoints, 0);
      expect(stats.prayerRate, 0);

      final rates = await db.statsDao.getPerPrayerRates(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 31),
      );
      expect(rates, hasLength(5));
      expect(rates.every((r) => r.rate == 0), isTrue);
    });
  });

  // Two grant passes can legitimately run at the same moment — the statistics
  // screen's post-frame sweep while the achievements screen refreshes — and
  // both used to read "not earned yet" before either wrote, leaving the same
  // achievement stored twice (duplicate badge, and the unlock animation
  // replaying because each copy starts out unseen).
  group('achievement grants are race-proof', () {
    Future<List<Achievement>> rowsOfType(String type) =>
        (db.select(db.achievements)
              ..where((a) => a.type.equals(type)))
            .get();

    /// Three consecutive positive-point days: enough for streak_3, not enough
    /// for streak_7, so exactly one grant is in play.
    Future<void> seedThreeDayStreak() async {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day).subtract(
        const Duration(days: 2),
      );
      for (var i = 0; i < 3; i++) {
        await seedDay(start.add(Duration(days: i)), netPoints: 10);
      }
    }

    test('concurrent sweeps leave exactly one row per achievement', () async {
      await seedThreeDayStreak();

      final results = await Future.wait([
        db.statsDao.checkAndGrantAchievements(),
        db.statsDao.checkAndGrantAchievements(),
      ]);

      expect(results.expand((r) => r).map((a) => a.type), contains('streak_3'));
      expect(await rowsOfType('streak_3'), hasLength(1));
    });

    test('the unique index rejects a second row for the same type', () async {
      await db.statsDao.addAchievement(
        type: 'streak_3',
        titleAr: 'x',
        descAr: 'y',
        emoji: '🌱',
      );

      // Not a DAO-level check — this is the database constraint that makes
      // the grant path correct even if a future caller forgets to look first.
      // Asserted by outcome rather than exception type: the native driver
      // surfaces a constraint violation as its own SqliteException class,
      // which isn't a declared dependency here.
      Object? rejected;
      try {
        await db
            .into(db.achievements)
            .insert(
              AchievementsCompanion(
                type: const Value('streak_3'),
                titleAr: const Value('other'),
                descAr: const Value('other'),
                emoji: const Value('🔥'),
                earnedAt: Value(DateTime.now()),
              ),
            );
      } catch (e) {
        rejected = e;
      }
      expect(rejected, isNotNull, reason: 'the second row must be rejected');
      expect(await rowsOfType('streak_3'), hasLength(1));
    });

    test('addAchievement is a no-op for a type that already exists', () async {
      for (var i = 0; i < 2; i++) {
        await db.statsDao.addAchievement(
          type: 'quran_juz',
          titleAr: 'x',
          descAr: 'y',
          emoji: '📖',
        );
      }
      expect(await rowsOfType('quran_juz'), hasLength(1));
    });
  });
}
