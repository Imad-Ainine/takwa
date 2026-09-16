// Regression tests for PrayerTimesService.calculate(), the app's only
// entry point into the `adhan` package. These lock in structural invariants
// that must hold regardless of the adhan package's internal math, so a
// package upgrade or a calc-method tweak can't silently break prayer
// scheduling without a test failing first.
//
// See the "Testing Strategy" section of the engineering audit for context.

import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/notifications/notifications_service.dart';

void main() {
  // A fixed reference date avoids any flakiness from "today".
  final summerSolstice = DateTime(2026, 6, 21);
  final winterSolstice = DateTime(2026, 12, 21);

  const mecca = (lat: 21.4225, lng: 39.8262);
  const london = (lat: 51.5074, lng: -0.1278);

  const methods = ['MWL', 'Algeria', 'Egypt', 'Karachi', 'UmmAlQura', 'ISNA'];

  for (final method in methods) {
    for (final madhab in ['shafi', 'hanafi']) {
      test(
        '$method/$madhab: prayers are strictly ordered fajr..isha (Mecca, summer)',
        () async {
          final prayers = await PrayerTimesService.calculate(
            latitude: mecca.lat,
            longitude: mecca.lng,
            madhab: madhab,
            method: method,
            date: summerSolstice,
          );
          _expectStrictlyOrdered(prayers);
        },
      );

      test(
        '$method/$madhab: prayers are strictly ordered fajr..isha (London, winter)',
        () async {
          final prayers = await PrayerTimesService.calculate(
            latitude: london.lat,
            longitude: london.lng,
            madhab: madhab,
            method: method,
            date: winterSolstice,
          );
          _expectStrictlyOrdered(prayers);
        },
      );
    }
  }

  test('hanafi Asr is never earlier than shafi Asr (same method/place/date)', () async {
    for (final method in methods) {
      final shafi = await PrayerTimesService.calculate(
        latitude: mecca.lat,
        longitude: mecca.lng,
        madhab: 'shafi',
        method: method,
        date: summerSolstice,
      );
      final hanafi = await PrayerTimesService.calculate(
        latitude: mecca.lat,
        longitude: mecca.lng,
        madhab: 'hanafi',
        method: method,
        date: summerSolstice,
      );

      final shafiAsr = shafi.firstWhere((p) => p.name == 'asr').time;
      final hanafiAsr = hanafi.firstWhere((p) => p.name == 'asr').time;

      // Hanafi uses a longer shadow-length factor, so its Asr threshold is
      // reached later in the day than Shafi's for the same location/date.
      expect(
        hanafiAsr.isAfter(shafiAsr) || hanafiAsr.isAtSameMomentAs(shafiAsr),
        isTrue,
        reason: '[$method] expected hanafi Asr ($hanafiAsr) >= shafi Asr ($shafiAsr)',
      );
    }
  });

  test('an unrecognized method string falls back to MWL, not a crash', () async {
    final prayers = await PrayerTimesService.calculate(
      latitude: mecca.lat,
      longitude: mecca.lng,
      madhab: 'shafi',
      method: 'not_a_real_method',
      date: summerSolstice,
    );
    _expectStrictlyOrdered(prayers);
    expect(prayers, hasLength(6));
  });

  group('formatTime', () {
    test('formats afternoon times with م (PM)', () {
      expect(PrayerTimesService.formatTime(DateTime(2026, 1, 1, 15, 5)), '3:05 م');
    });
    test('formats morning times with ص (AM)', () {
      expect(PrayerTimesService.formatTime(DateTime(2026, 1, 1, 6, 30)), '6:30 ص');
    });
    test('midnight (hour 0) renders as 12 ص', () {
      expect(PrayerTimesService.formatTime(DateTime(2026, 1, 1, 0, 0)), '12:00 ص');
    });
    test('noon (hour 12) renders as 12 م', () {
      expect(PrayerTimesService.formatTime(DateTime(2026, 1, 1, 12, 0)), '12:00 م');
    });
  });

  group('formatDuration', () {
    test('shows hours and minutes when >= 1 hour', () {
      expect(
        PrayerTimesService.formatDuration(const Duration(hours: 2, minutes: 5)),
        '2س 5د',
      );
    });
    test('shows minutes only when < 1 hour', () {
      expect(
        PrayerTimesService.formatDuration(const Duration(minutes: 45)),
        '45 دقيقة',
      );
    });
  });
}

void _expectStrictlyOrdered(List<PrayerTimeInfo> prayers) {
  expect(prayers.map((p) => p.name).toList(), [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ]);
  for (var i = 1; i < prayers.length; i++) {
    expect(
      prayers[i].time.isAfter(prayers[i - 1].time),
      isTrue,
      reason:
          '${prayers[i].name} (${prayers[i].time}) should be after '
          '${prayers[i - 1].name} (${prayers[i - 1].time})',
    );
  }
}
