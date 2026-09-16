import 'package:hijri/hijri_calendar.dart';

/// Where a given moment sits relative to the current Hijri Ramadan —
/// computed the same way `statistics_screen.dart`'s `StatsPeriod.ramadan`
/// branch does (Hijri month 9), so the tracker entry point, the stats
/// "day X of 30" bar, and the Ramadan-completion achievement check in
/// `StatsDao.checkAndGrantAchievements()` never disagree about whether
/// it's Ramadan or which Gregorian dates it spans.
///
/// Lives in core/utils (not the ramadan feature) specifically so
/// `core/database/daos.dart` can depend on it without a features → core
/// layering violation.
class RamadanInfo {
  final bool isRamadan;
  final int hijriYear;
  final int dayNumber; // 1-based day of Ramadan
  final int totalDays; // 29 or 30, depending on the Hijri year
  final DateTime gregorianStart;
  final DateTime gregorianEnd;

  const RamadanInfo({
    required this.isRamadan,
    required this.hijriYear,
    required this.dayNumber,
    required this.totalDays,
    required this.gregorianStart,
    required this.gregorianEnd,
  });
}

RamadanInfo computeRamadanInfo([HijriCalendar? now]) {
  final hijri = now ?? HijriCalendar.now();
  final start = HijriCalendar()
    ..hYear = hijri.hYear
    ..hMonth = 9
    ..hDay = 1;
  final totalDays = start.getDaysInMonth(hijri.hYear, 9);
  final end = HijriCalendar()
    ..hYear = hijri.hYear
    ..hMonth = 9
    ..hDay = totalDays;

  final gStart = start.hijriToGregorian(start.hYear, start.hMonth, start.hDay);
  final gEnd = end.hijriToGregorian(end.hYear, end.hMonth, end.hDay);

  return RamadanInfo(
    isRamadan: hijri.hMonth == 9,
    hijriYear: hijri.hYear,
    dayNumber: hijri.hMonth == 9 ? hijri.hDay : 0,
    totalDays: totalDays,
    gregorianStart: DateTime(gStart.year, gStart.month, gStart.day),
    gregorianEnd: DateTime(gEnd.year, gEnd.month, gEnd.day),
  );
}
