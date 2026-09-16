import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/database_providers.dart';

/// Where "today" sits relative to the current Hijri Ramadan — computed the
/// same way `statistics_screen.dart`'s `StatsPeriod.ramadan` branch does
/// (Hijri month 9), so the tracker entry point and the stats "day X of 30"
/// bar never disagree about whether it's Ramadan.
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

/// Not a StreamProvider — the underlying value only changes once a day (at
/// most), so recomputing it once per screen visit is enough; there is no
/// Hijri-calendar "ticker" to watch.
final ramadanInfoProvider = Provider<RamadanInfo>((ref) => computeRamadanInfo());

/// Live `RamadanProgress` row (currently just `iHyaLayl`) for today's Hijri
/// Ramadan day.
final ramadanTodayProgressProvider = StreamProvider.autoDispose<RamadanProgressData?>((
  ref,
) {
  final info = ref.watch(ramadanInfoProvider);
  if (!info.isRamadan) return Stream.value(null);
  return ref
      .watch(ramadanProgressDaoProvider)
      .watchProgress(info.hijriYear, info.dayNumber);
});

/// `DailyRecords` for every day in the current Ramadan range, for the
/// tracker's 30-day fasting strip.
final ramadanMonthRecordsProvider =
    StreamProvider.autoDispose<List<DailyRecord>>((ref) {
      final info = ref.watch(ramadanInfoProvider);
      if (!info.isRamadan) return Stream.value(const <DailyRecord>[]);
      return ref
          .watch(ramadanProgressDaoProvider)
          .watchRecordsForRange(info.gregorianStart, info.gregorianEnd);
    });
