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
  eidAlAdha(hijriMonth: 12, hijriDay: 10),
  islamicNewYear(hijriMonth: 1, hijriDay: 1),
  laylatAlQadr(hijriMonth: 9, hijriDay: 27),
  dayOfArafah(hijriMonth: 12, hijriDay: 9);

  final int hijriMonth;
  final int hijriDay;
  const IslamicOccasionKind({required this.hijriMonth, required this.hijriDay});

  /// Whether voluntary fasting is specifically recommended on this occasion.
  bool get isFastingRecommended => switch (this) {
    IslamicOccasionKind.ashura => true,
    IslamicOccasionKind.dayOfArafah => true,
    _ => false,
  };
}

/// A resolved occurrence: which Hijri year it falls in next, its Gregorian
/// date, and how many days from now.
class ResolvedOccasion {
  final IslamicOccasionKind kind;
  final DateTime gregorianDate;
  final int daysUntil;
  final bool isFastingRecommended;

  const ResolvedOccasion({
    required this.kind,
    required this.gregorianDate,
    required this.daysUntil,
    required this.isFastingRecommended,
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
        isFastingRecommended: kind.isFastingRecommended,
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
    isFastingRecommended: kind.isFastingRecommended,
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
  final bool isFastingRecommended; // always true for White Days

  const WhiteDay({
    required this.hijriDay,
    required this.gregorianDate,
    required this.daysUntil,
    this.isFastingRecommended = true,
  });
}

/// The upcoming Hijri month's three White Days (Ayyam al-Beed), each resolved
/// to its Gregorian date and days-until. Returns the current Hijri month's
/// White Days unless all three have already passed, in which case it rolls
/// forward to the next Hijri month.
List<WhiteDay> resolveWhiteDays({DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final hijriNow = HijriCalendar.now();

  List<WhiteDay> forMonth(int year, int month) => [13, 14, 15].map((day) {
    final hijri = HijriCalendar()
      ..hYear = year
      ..hMonth = month
      ..hDay = day;
    final g = _dateOnly(hijri.hijriToGregorian(year, month, day));
    return WhiteDay(
      hijriDay: day,
      gregorianDate: g,
      daysUntil: g.difference(today).inDays,
      isFastingRecommended: true,
    );
  }).toList();

  final current = forMonth(hijriNow.hYear, hijriNow.hMonth);
  // If all three White Days for this month have passed, show next month's.
  if (current.every((d) => d.daysUntil < 0)) {
    final nextYear = hijriNow.hMonth == 12 ? hijriNow.hYear + 1 : hijriNow.hYear;
    final nextMonth = hijriNow.hMonth == 12 ? 1 : hijriNow.hMonth + 1;
    return forMonth(nextYear, nextMonth);
  }
  return current;
}
