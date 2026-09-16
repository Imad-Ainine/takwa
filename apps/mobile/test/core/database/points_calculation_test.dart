// Regression tests for DailyRecordDao.recalcPoints(), which encodes the
// entire Taqwa points model. These exist so a future refactor of the
// scoring rules changes user-visible behavior on purpose, not by accident.
//
// See the "Testing Strategy" section of the engineering audit for context.

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

  test('a fresh day starts at zero net points', () async {
    final record = await db.dailyRecordDao.getOrCreateToday();
    expect(record.netPoints, 0);
    expect(record.taqwaPoints, 0);
    expect(record.deductedPoints, 0);
  });

  test('performed prayers award 10 points each, qadaa awards 5', () async {
    final record = await db.dailyRecordDao.getOrCreateToday();

    await db.dailyRecordDao.updatePrayerStatus(
      recordId: record.id,
      prayerName: 'fajr',
      status: PrayerStatus.performed,
    );
    await db.dailyRecordDao.updatePrayerStatus(
      recordId: record.id,
      prayerName: 'dhuhr',
      status: PrayerStatus.qadaa,
    );

    final updated = await db.dailyRecordDao.getRecordByDate(record.date);
    expect(updated!.netPoints, 15); // 10 (performed) + 5 (qadaa)
  });

  test('night prayer, witr and rawatib add their documented weights', () async {
    final record = await db.dailyRecordDao.getOrCreateToday();

    await db.dailyRecordDao.toggleNightPrayer(record.id, true); // +15
    await (db.update(db.dailyRecords)
          ..where((r) => r.id.equals(record.id)))
        .write(const DailyRecordsCompanion(witr: Value(true), rawatib: Value(2)));
    await db.dailyRecordDao.recalcPoints(record.id); // +5 witr, +2*2 rawatib

    final updated = await db.dailyRecordDao.getRecordByDate(record.date);
    expect(updated!.netPoints, 15 + 5 + 4);
  });

  test('quran pages and juz contribute 1pt/page and 10pt/juz', () async {
    final record = await db.dailyRecordDao.getOrCreateToday();

    await db.dailyRecordDao.updateQuran(recordId: record.id, pages: 4);
    await db.dailyRecordDao.updateQuran(recordId: record.id, juzaa: 0.5);

    final updated = await db.dailyRecordDao.getRecordByDate(record.date);
    expect(updated!.netPoints, 4 + 5); // 4 pages*1 + 0.5 juz*10
  });

  test('fasting: fard awards 20, nafl awards 10', () async {
    final record = await db.dailyRecordDao.getOrCreateToday();

    await db.dailyRecordDao.updateFasting(record.id, FastingType.fard);
    var updated = await db.dailyRecordDao.getRecordByDate(record.date);
    expect(updated!.netPoints, 20);

    await db.dailyRecordDao.updateFasting(record.id, FastingType.nafl);
    updated = await db.dailyRecordDao.getRecordByDate(record.date);
    expect(updated!.netPoints, 10);
  });

  test('sadaqah and ghadh al-basar each award 10 points', () async {
    final record = await db.dailyRecordDao.getOrCreateToday();

    await db.dailyRecordDao.toggleSadaqah(record.id, true);
    await db.dailyRecordDao.toggleGhadhBasar(record.id, true);

    final updated = await db.dailyRecordDao.getRecordByDate(record.date);
    expect(updated!.netPoints, 20);
  });

  test('a committed prohibition deducts points*timesCount from the total',
      () async {
    final record = await db.dailyRecordDao.getOrCreateToday();
    await db.dailyRecordDao.updatePrayerStatus(
      recordId: record.id,
      prayerName: 'fajr',
      status: PrayerStatus.performed,
    ); // +10

    await db.dailyRecordDao.logProhibition(
      recordId: record.id,
      category: ProhibitionCategory.gheeba,
      committed: true,
      timesCount: 2,
      deductPoints: 10,
    ); // -20

    final updated = await db.dailyRecordDao.getRecordByDate(record.date);
    expect(updated!.taqwaPoints, 10);
    expect(updated.deductedPoints, 20);
    expect(updated.netPoints, -10);
  });

  test(
    'custom ibadah logs add points when positive and deduct when negative',
    () async {
      final record = await db.dailyRecordDao.getOrCreateToday();

      final goodId = await db.customIbadahDao.addIbadah(
        const CustomIbadahCompanion(
          nameAr: Value('صلة الرحم'),
          isPositive: Value(true),
          points: Value(10),
        ),
      );
      final badId = await db.customIbadahDao.addIbadah(
        const CustomIbadahCompanion(
          nameAr: Value('الغيبة'),
          isPositive: Value(false),
          points: Value(-10),
        ),
      );

      await db.customIbadahDao.logIbadah(goodId, record.date, true, 1); // +10
      await db.customIbadahDao.logIbadah(badId, record.date, true, 1); // -10

      final updated = await db.dailyRecordDao.getRecordByDate(record.date);
      expect(updated!.taqwaPoints, 10);
      expect(updated.deductedPoints, 10);
      expect(updated.netPoints, 0);
    },
  );
}
