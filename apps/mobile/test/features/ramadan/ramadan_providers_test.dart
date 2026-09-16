// Regression tests for computeRamadanInfo(), the pure Hijri-date math behind
// the Ramadan tracker's entry point, day badge and 30-day strip. Keeping
// this logic pure (takes a HijriCalendar, no `HijriCalendar.now()` inside)
// is what makes it testable without mocking the system clock.

import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:takwa/features/ramadan/providers/ramadan_providers.dart';

void main() {
  test('mid-Ramadan date reports isRamadan and the correct day number', () {
    final hijri = HijriCalendar()
      ..hYear = 1446
      ..hMonth = 9
      ..hDay = 15;

    final info = computeRamadanInfo(hijri);

    expect(info.isRamadan, isTrue);
    expect(info.hijriYear, 1446);
    expect(info.dayNumber, 15);
    expect(info.totalDays, anyOf(29, 30));
    expect(
      info.gregorianEnd.isAfter(info.gregorianStart),
      isTrue,
      reason: 'Ramadan end must come after its start',
    );
    expect(
      info.gregorianEnd.difference(info.gregorianStart).inDays,
      info.totalDays - 1,
    );
  });

  test('a date outside Ramadan reports isRamadan false and day 0', () {
    final hijri = HijriCalendar()
      ..hYear = 1446
      ..hMonth = 10 // Shawwal
      ..hDay = 5;

    final info = computeRamadanInfo(hijri);

    expect(info.isRamadan, isFalse);
    expect(info.dayNumber, 0);
    // Still resolves *that year's* Ramadan range, not garbage — the strip
    // provider only reads gregorianStart/End when isRamadan is true, but
    // this guards against them silently going nonsensical.
    expect(info.gregorianEnd.isAfter(info.gregorianStart), isTrue);
  });

  test('day 1 of Ramadan', () {
    final hijri = HijriCalendar()
      ..hYear = 1445
      ..hMonth = 9
      ..hDay = 1;

    final info = computeRamadanInfo(hijri);

    expect(info.isRamadan, isTrue);
    expect(info.dayNumber, 1);
    expect(info.gregorianStart, equals(DateTime(info.gregorianStart.year, info.gregorianStart.month, info.gregorianStart.day)));
  });
}
