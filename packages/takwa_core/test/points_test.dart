import 'package:takwa_core/takwa_core.dart';
import 'package:test/test.dart';

void main() {
  group('calculateDailyPoints', () {
    test('an empty day earns and deducts nothing', () {
      final result = calculateDailyPoints(const DailyPointsInput());
      expect(result.earnedPoints, 0);
      expect(result.deductedPoints, 0);
      expect(result.netPoints, 0);
    });

    test('performed prayers award 10 points each, qadaa awards 5', () {
      final result = calculateDailyPoints(
        const DailyPointsInput(
          fajrStatus: PrayerStatus.performed,
          dhuhrStatus: PrayerStatus.qadaa,
          asrStatus: PrayerStatus.notDue,
          maghribStatus: PrayerStatus.missed,
          ishaStatus: PrayerStatus.pending,
        ),
      );
      expect(result.earnedPoints, 15); // 10 + 5, the rest score 0
    });

    test('night prayer, witr and rawatib add their documented weights', () {
      final result = calculateDailyPoints(
        const DailyPointsInput(nightPrayer: true, witr: true, rawatib: 3),
      );
      expect(result.earnedPoints, 15 + 5 + 3 * 2);
    });

    test('quran pages and juz contribute 1pt/page and 10pt/juz', () {
      final result = calculateDailyPoints(
        const DailyPointsInput(quranPages: 4, quranJuzaa: 0.5),
      );
      expect(result.earnedPoints, 4 * 1 + 5); // 0.5 juz * 10 = 5
    });

    test('adhkar: morning/evening = 5 each, after-prayer = 3', () {
      final result = calculateDailyPoints(
        const DailyPointsInput(
          morningAdhkar: true,
          eveningAdhkar: true,
          afterPrayerAdhkar: true,
        ),
      );
      expect(result.earnedPoints, 5 + 5 + 3);
    });

    test('fasting: fard awards 20, nafl awards 10, none awards 0', () {
      expect(
        calculateDailyPoints(
          const DailyPointsInput(fastingType: FastingType.fard),
        ).earnedPoints,
        20,
      );
      expect(
        calculateDailyPoints(
          const DailyPointsInput(fastingType: FastingType.nafl),
        ).earnedPoints,
        10,
      );
      expect(
        calculateDailyPoints(
          const DailyPointsInput(fastingType: FastingType.none),
        ).earnedPoints,
        0,
      );
    });

    test('sadaqah and ghadh al-basar each award 10 points', () {
      final result = calculateDailyPoints(
        const DailyPointsInput(sadaqah: true, ghadhBasar: true),
      );
      expect(result.earnedPoints, 20);
    });

    test('a committed prohibition deducts deductPoints * timesCount', () {
      final result = calculateDailyPoints(
        const DailyPointsInput(
          prohibitions: [
            ProhibitionEntry(committed: true, deductPoints: 10, timesCount: 3),
            // Not committed — must not count.
            ProhibitionEntry(committed: false, deductPoints: 50, timesCount: 5),
          ],
        ),
      );
      expect(result.deductedPoints, 30);
    });

    test('positive custom ibadah adds, negative deducts, by points*count', () {
      final result = calculateDailyPoints(
        const DailyPointsInput(
          customIbadah: [
            CustomIbadahEntry(done: true, isPositive: true, points: 5, count: 2),
            CustomIbadahEntry(done: true, isPositive: false, points: -10, count: 1),
            // Not done — must not count either way.
            CustomIbadahEntry(done: false, isPositive: true, points: 100, count: 1),
          ],
        ),
      );
      expect(result.earnedPoints, 10); // 5 * 2
      expect(result.deductedPoints, 10); // |-10 * 1|
    });

    test('netPoints is earned minus deducted, and can go negative', () {
      final result = calculateDailyPoints(
        const DailyPointsInput(
          fajrStatus: PrayerStatus.performed, // +10
          prohibitions: [
            ProhibitionEntry(committed: true, deductPoints: 50, timesCount: 1),
          ],
        ),
      );
      expect(result.earnedPoints, 10);
      expect(result.deductedPoints, 50);
      expect(result.netPoints, -40);
    });
  });

  group('taqwaLevelFor', () {
    test('boundaries match the documented thresholds', () {
      expect(taqwaLevelFor(0), TaqwaLevel.mubtadi);
      expect(taqwaLevelFor(99), TaqwaLevel.mubtadi);
      expect(taqwaLevelFor(100), TaqwaLevel.salik);
      expect(taqwaLevelFor(299), TaqwaLevel.salik);
      expect(taqwaLevelFor(300), TaqwaLevel.mujahid);
      expect(taqwaLevelFor(599), TaqwaLevel.mujahid);
      expect(taqwaLevelFor(600), TaqwaLevel.mutaqi);
      expect(taqwaLevelFor(10000), TaqwaLevel.mutaqi);
    });

    test('negative points still resolve to mubtadi, not a crash', () {
      expect(taqwaLevelFor(-50), TaqwaLevel.mubtadi);
    });
  });
}
