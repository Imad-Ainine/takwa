import 'enums.dart';

/// One committed/attempted prohibition for a day, stripped down to just
/// what the points model needs.
class ProhibitionEntry {
  final bool committed;
  final int deductPoints;
  final int timesCount;

  const ProhibitionEntry({
    required this.committed,
    required this.deductPoints,
    required this.timesCount,
  });
}

/// One logged custom ibadah (positive or negative habit) for a day.
class CustomIbadahEntry {
  final bool done;
  final bool isPositive;
  final int points;
  final int count;

  const CustomIbadahEntry({
    required this.done,
    required this.isPositive,
    required this.points,
    required this.count,
  });
}

/// Every raw signal the Taqwa points model depends on for a single day.
/// Storage-agnostic — the caller is responsible for reading this out of
/// wherever the day's record actually lives (Drift row, Supabase JSON,
/// whatever).
class DailyPointsInput {
  final PrayerStatus fajrStatus;
  final PrayerStatus dhuhrStatus;
  final PrayerStatus asrStatus;
  final PrayerStatus maghribStatus;
  final PrayerStatus ishaStatus;
  final bool nightPrayer;
  final bool witr;
  final int rawatib;
  final int quranPages;
  final double quranJuzaa;
  final bool morningAdhkar;
  final bool eveningAdhkar;
  final bool afterPrayerAdhkar;
  final FastingType fastingType;
  final bool sadaqah;
  final bool ghadhBasar;
  final List<ProhibitionEntry> prohibitions;
  final List<CustomIbadahEntry> customIbadah;

  const DailyPointsInput({
    this.fajrStatus = PrayerStatus.notDue,
    this.dhuhrStatus = PrayerStatus.notDue,
    this.asrStatus = PrayerStatus.notDue,
    this.maghribStatus = PrayerStatus.notDue,
    this.ishaStatus = PrayerStatus.notDue,
    this.nightPrayer = false,
    this.witr = false,
    this.rawatib = 0,
    this.quranPages = 0,
    this.quranJuzaa = 0.0,
    this.morningAdhkar = false,
    this.eveningAdhkar = false,
    this.afterPrayerAdhkar = false,
    this.fastingType = FastingType.none,
    this.sadaqah = false,
    this.ghadhBasar = false,
    this.prohibitions = const [],
    this.customIbadah = const [],
  });
}

/// Result of [calculateDailyPoints] — earned and deducted are kept
/// separate (matching `daily_records.taqwa_points` /
/// `daily_records.deducted_points`) since the app displays both, not just
/// the net.
class DailyPointsResult {
  final int earnedPoints;
  final int deductedPoints;

  const DailyPointsResult({
    required this.earnedPoints,
    required this.deductedPoints,
  });

  int get netPoints => earnedPoints - deductedPoints;
}

int _prayerPoints(PrayerStatus status) => switch (status) {
  PrayerStatus.performed => 10,
  PrayerStatus.qadaa => 5,
  _ => 0,
};

/// The Taqwa points model. Pulled out of `DailyRecordDao.recalcPoints()`
/// so the scoring rules have exactly one home, are unit-testable without
/// a database, and are reusable outside the mobile app.
///
/// Point values (kept identical to the pre-extraction behavior):
/// prayer performed = 10, qadaa = 5; night prayer = 15; witr = 5;
/// rawatib = 2/unit; Quran page = 1; Quran juz = 10; morning/evening
/// adhkar = 5 each; after-prayer adhkar = 3; fard fast = 20; nafl fast =
/// 10; sadaqah = 10; ghadh al-basar = 10. Deductions: each committed
/// prohibition = its `deductPoints * timesCount`; each negative custom
/// ibadah = its `points * count` (absolute value).
DailyPointsResult calculateDailyPoints(DailyPointsInput input) {
  int points = 0;

  points += _prayerPoints(input.fajrStatus);
  points += _prayerPoints(input.dhuhrStatus);
  points += _prayerPoints(input.asrStatus);
  points += _prayerPoints(input.maghribStatus);
  points += _prayerPoints(input.ishaStatus);
  if (input.nightPrayer) points += 15;
  if (input.witr) points += 5;
  points += input.rawatib * 2;

  points += input.quranPages * 1;
  points += (input.quranJuzaa * 10).toInt();

  if (input.morningAdhkar) points += 5;
  if (input.eveningAdhkar) points += 5;
  if (input.afterPrayerAdhkar) points += 3;

  if (input.fastingType == FastingType.fard) points += 20;
  if (input.fastingType == FastingType.nafl) points += 10;

  if (input.sadaqah) points += 10;
  if (input.ghadhBasar) points += 10;

  int deducted = 0;
  for (final p in input.prohibitions) {
    if (p.committed) deducted += p.deductPoints * p.timesCount;
  }

  for (final c in input.customIbadah) {
    if (!c.done) continue;
    final pts = c.points * c.count;
    if (c.isPositive) {
      points += pts;
    } else {
      deducted += pts.abs();
    }
  }

  return DailyPointsResult(earnedPoints: points, deductedPoints: deducted);
}
