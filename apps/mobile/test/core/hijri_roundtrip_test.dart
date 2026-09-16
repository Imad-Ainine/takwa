// Regression tests for the app's use of package:hijri. Rather than hardcode
// "known" Gregorian<->Hijri pairs from memory (tabular-vs-Umm-al-Qura
// conventions can legitimately disagree by a day, which would make such a
// test flaky-by-construction), these check the conversion's own internal
// consistency: Gregorian -> Hijri -> Gregorian must round-trip, and walking
// forward day by day must never skip or repeat a Hijri day.
//
// See the "Testing Strategy" section of the engineering audit for context.

import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  test('Gregorian -> Hijri -> Gregorian round-trips exactly', () {
    // A spread of fixed dates across different months/years, deliberately
    // avoiding "today" so the test is not date-dependent.
    final fixtures = [
      DateTime(2024, 1, 1),
      DateTime(2025, 3, 15),
      DateTime(2026, 6, 21),
      DateTime(2026, 12, 21),
      DateTime(2030, 8, 9),
    ];

    for (final gregorian in fixtures) {
      final hijri = HijriCalendar.fromDate(gregorian);
      final roundTripped = HijriCalendar().hijriToGregorian(
        hijri.hYear,
        hijri.hMonth,
        hijri.hDay,
      );

      expect(
        _dateOnly(roundTripped),
        _dateOnly(gregorian),
        reason: '$gregorian -> Hijri ${hijri.hYear}-${hijri.hMonth}-${hijri.hDay} '
            '-> $roundTripped did not round-trip',
      );
    }
  });

  test('Hijri month/day fields always stay within valid ranges', () {
    final fixtures = [
      DateTime(2024, 1, 1),
      DateTime(2025, 3, 15),
      DateTime(2026, 6, 21),
      DateTime(2026, 12, 21),
    ];
    for (final gregorian in fixtures) {
      final hijri = HijriCalendar.fromDate(gregorian);
      expect(hijri.hMonth, inInclusiveRange(1, 12));
      expect(hijri.hDay, inInclusiveRange(1, 30));
    }
  });

  test('walking forward day by day advances the Hijri date monotonically', () {
    // 40 consecutive days guarantees crossing at least one Hijri month
    // boundary (a Hijri month is 29-30 days).
    var cursor = DateTime(2026, 6, 1);
    var prev = HijriCalendar.fromDate(cursor);

    for (var i = 0; i < 40; i++) {
      cursor = cursor.add(const Duration(days: 1));
      final next = HijriCalendar.fromDate(cursor);

      final advancedOneDay =
          (next.hMonth == prev.hMonth && next.hDay == prev.hDay + 1) ||
          // month rollover: day resets to 1 and month advances by one
          // (wrapping from 12 to 1 at year end)
          (next.hDay == 1 &&
              (next.hMonth == prev.hMonth + 1 ||
                  (prev.hMonth == 12 && next.hMonth == 1)));

      expect(
        advancedOneDay,
        isTrue,
        reason:
            'expected Hijri date to advance by exactly one day: '
            '${prev.hYear}-${prev.hMonth}-${prev.hDay} -> '
            '${next.hYear}-${next.hMonth}-${next.hDay}',
      );
      prev = next;
    }
  });
}
