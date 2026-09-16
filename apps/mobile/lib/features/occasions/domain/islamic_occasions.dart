import 'package:hijri/hijri_calendar.dart';

/// A recurring Islamic occasion, identified by its fixed Hijri month/day.
/// See docs/specs/islamic-occasions.md — informational/cultural, not a
/// fiqh ruling on which occasions should be observed.
enum IslamicOccasionKind {
  ashura(hijriMonth: 1, hijriDay: 10),
  isra1Miraj(hijriMonth: 7, hijriDay: 27),
  ramadanStart(hijriMonth: 9, hijriDay: 1),
  eidAlFitr(hijriMonth: 10, hijriDay: 1),
  mawlid(hijriMonth: 3, hijriDay: 12),
  eidAlAdha(hijriMonth: 12, hijriDay: 10);

  final int hijriMonth;
  final int hijriDay;
  const IslamicOccasionKind({required this.hijriMonth, required this.hijriDay});
}

/// A resolved occurrence: which Hijri year it falls in next, its Gregorian
/// date, and how many days from now.
class ResolvedOccasion {
  final IslamicOccasionKind kind;
  final DateTime gregorianDate;
  final int daysUntil;

  const ResolvedOccasion({
    required this.kind,
    required this.gregorianDate,
    required this.daysUntil,
  });
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Resolves the *next* occurrence of [kind] on or after [now] — tries the
/// current Hijri year first, and rolls to next Hijri year if that date
/// already passed.
ResolvedOccasion resolveNextOccurrence(
  IslamicOccasionKind kind, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final currentHijriYear = HijriCalendar.now().hYear;

  for (final year in [currentHijriYear, currentHijriYear + 1]) {
    final hijri = HijriCalendar()
      ..hYear = year
      ..hMonth = kind.hijriMonth
      ..hDay = kind.hijriDay;
    final g = hijri.hijriToGregorian(year, kind.hijriMonth, kind.hijriDay);
    final gDate = _dateOnly(g);
    if (!gDate.isBefore(today)) {
      return ResolvedOccasion(
        kind: kind,
        gregorianDate: gDate,
        daysUntil: gDate.difference(today).inDays,
      );
    }
  }
  // Unreachable in practice (the +1 year branch always resolves to a future
  // date), but keeps the function total rather than throwing.
  final fallback = HijriCalendar()
    ..hYear = currentHijriYear + 1
    ..hMonth = kind.hijriMonth
    ..hDay = kind.hijriDay;
  final g = _dateOnly(
    fallback.hijriToGregorian(
      currentHijriYear + 1,
      kind.hijriMonth,
      kind.hijriDay,
    ),
  );
  return ResolvedOccasion(
    kind: kind,
    gregorianDate: g,
    daysUntil: g.difference(today).inDays,
  );
}

List<ResolvedOccasion> resolveAllOccasions({DateTime? now}) {
  return IslamicOccasionKind.values
      .map((k) => resolveNextOccurrence(k, now: now))
      .toList()
    ..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
}

/// One of the current Hijri month's three White Days (13th/14th/15th) —
/// deliberately not a [ResolvedOccasion] (there's no [IslamicOccasionKind]
/// for it, since White Days recur monthly rather than yearly).
class WhiteDay {
  final int hijriDay; // 13, 14, or 15
  final DateTime gregorianDate;
  final int daysUntil;

  const WhiteDay({
    required this.hijriDay,
    required this.gregorianDate,
    required this.daysUntil,
  });
}

/// The current Hijri month's three White Days (Ayyam al-Beed), each resolved
/// to its Gregorian date and days-until. These are within the *current*
/// Hijri month only — "next month's White Days" isn't computed here, since
/// the screen only ever needs "how soon is the next one this cycle."
List<WhiteDay> resolveWhiteDays({DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final hijriNow = HijriCalendar.now();

  return [13, 14, 15].map((day) {
    final hijri = HijriCalendar()
      ..hYear = hijriNow.hYear
      ..hMonth = hijriNow.hMonth
      ..hDay = day;
    final g = _dateOnly(
      hijri.hijriToGregorian(hijriNow.hYear, hijriNow.hMonth, day),
    );
    return WhiteDay(
      hijriDay: day,
      gregorianDate: g,
      daysUntil: g.difference(today).inDays,
    );
  }).toList();
}
