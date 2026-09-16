// Regression tests for the pure Hijri-date math behind the Islamic
// Occasions screen — resolving the next occurrence of a yearly occasion,
// and the current month's White Days.

import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:takwa/features/occasions/domain/islamic_occasions.dart';

void main() {
  test('resolveNextOccurrence never returns a date in the past', () {
    for (final kind in IslamicOccasionKind.values) {
      final resolved = resolveNextOccurrence(kind);
      expect(
        resolved.daysUntil,
        greaterThanOrEqualTo(0),
        reason: '${kind.name} resolved to a past date',
      );
    }
  });

  test('resolveNextOccurrence resolves to the correct Hijri day/month', () {
    final resolved = resolveNextOccurrence(IslamicOccasionKind.ashura);
    final backToHijri = HijriCalendar.fromDate(resolved.gregorianDate);
    expect(backToHijri.hMonth, IslamicOccasionKind.ashura.hijriMonth);
    expect(backToHijri.hDay, IslamicOccasionKind.ashura.hijriDay);
  });

  test('resolveAllOccasions returns all six occasions sorted by daysUntil', () {
    final all = resolveAllOccasions();
    expect(all.length, IslamicOccasionKind.values.length);
    for (var i = 1; i < all.length; i++) {
      expect(all[i].daysUntil, greaterThanOrEqualTo(all[i - 1].daysUntil));
    }
  });

  test('resolveWhiteDays returns exactly the 13th, 14th and 15th', () {
    final days = resolveWhiteDays();
    expect(days.map((d) => d.hijriDay).toList(), [13, 14, 15]);
    for (final d in days) {
      final backToHijri = HijriCalendar.fromDate(d.gregorianDate);
      expect(backToHijri.hDay, d.hijriDay);
    }
  });
}
