// Regression tests for the Sadaqah amount tracking (DailyRecordDao) and the
// Qada' lifetime prayer-backlog counters (QadaDao) added alongside the
// mobile spec batch — see docs/specs/sadaqah-tracker.md and
// docs/specs/qada-prayer-tracker.md.

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

  group('Sadaqah amount tracking', () {
    test('updateSadaqahAmount persists the amount', () async {
      final record = await db.dailyRecordDao.getOrCreateToday();
      await db.dailyRecordDao.toggleSadaqah(record.id, true);
      await db.dailyRecordDao.updateSadaqahAmount(record.id, 50.0);

      final updated = await db.dailyRecordDao.getTodayRecord();
      expect(updated!.sadaqah, isTrue);
      expect(updated.sadaqahAmount, 50.0);
    });

    test('turning the Sadaqah toggle off clears any entered amount', () async {
      final record = await db.dailyRecordDao.getOrCreateToday();
      await db.dailyRecordDao.toggleSadaqah(record.id, true);
      await db.dailyRecordDao.updateSadaqahAmount(record.id, 50.0);

      await db.dailyRecordDao.toggleSadaqah(record.id, false);

      final updated = await db.dailyRecordDao.getTodayRecord();
      expect(updated!.sadaqah, isFalse);
      expect(updated.sadaqahAmount, 0);
    });

    test('getSadaqahTotal sums only Sadaqah-logged days', () async {
      final today = await db.dailyRecordDao.getOrCreateToday();
      await db.dailyRecordDao.toggleSadaqah(today.id, true);
      await db.dailyRecordDao.updateSadaqahAmount(today.id, 30.0);

      // A day with no Sadaqah logged shouldn't contribute, even if it
      // somehow had a stray amount value.
      final yesterday = await db.into(db.dailyRecords).insertReturning(
        DailyRecordsCompanion.insert(
          date: DateTime.now().subtract(const Duration(days: 1)),
          sadaqah: const Value(false),
          sadaqahAmount: const Value(999),
        ),
      );

      final total = await db.dailyRecordDao.getSadaqahTotal();
      expect(total, 30.0);
      expect(yesterday.sadaqah, isFalse); // sanity check on the seeded row
    });
  });

  group('Qada prayer counters', () {
    test('setOwed persists an owed count for a prayer', () async {
      await db.qadaDao.setOwed('fajr', 40);
      final rows = await db.qadaDao.watchAll().first;
      final fajr = rows.firstWhere((r) => r.prayerName == 'fajr');
      expect(fajr.owedCount, 40);
      expect(fajr.completedCount, 0);
    });

    test('markOneCompleted decrements owed and increments completed', () async {
      await db.qadaDao.setOwed('dhuhr', 3);
      await db.qadaDao.markOneCompleted('dhuhr');

      final rows = await db.qadaDao.watchAll().first;
      final dhuhr = rows.firstWhere((r) => r.prayerName == 'dhuhr');
      expect(dhuhr.owedCount, 2);
      expect(dhuhr.completedCount, 1);
    });

    test('markOneCompleted never takes owedCount below zero', () async {
      // No setOwed call — starts at the implicit zero.
      await db.qadaDao.markOneCompleted('asr');

      final rows = await db.qadaDao.watchAll().first;
      expect(rows.where((r) => r.prayerName == 'asr'), isEmpty);
    });
  });
}
