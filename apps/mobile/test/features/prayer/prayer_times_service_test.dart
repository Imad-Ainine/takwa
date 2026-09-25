// Regression tests for PrayerTimesService.calculate(), the app's only
// entry point into the `adhan` package. These lock in structural invariants
// that must hold regardless of the adhan package's internal math, so a
// package upgrade or a calc-method tweak can't silently break prayer
// scheduling without a test failing first.
//
// Also covers nextPrayer/nextPrayerOrTomorrow — the single countdown
// resolution shared by the Adhan screen and the foreground-service
// notification — including prayer transitions, the after-Isha midnight
// roll-over, timezone handling and the Europe/London DST boundary.
//
// See the "Testing Strategy" section of the engineering audit for context.

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:takwa/core/notifications/notifications_service.dart';

PrayerTimeInfo _prayer(String name, DateTime time) => PrayerTimeInfo(
  name: name,
  nameAr: name,
  emoji: '',
  time: time,
  notifId: 0,
);

/// A full day of fixed wall-clock times, ordered fajr..isha.
List<PrayerTimeInfo> _day(DateTime d, {int shiftDays = 0}) {
  DateTime at(int h, int m) =>
      DateTime(d.year, d.month, d.day + shiftDays, h, m);
  return [
    _prayer('fajr', at(4, 30)),
    _prayer('sunrise', at(6, 0)),
    _prayer('dhuhr', at(12, 15)),
    _prayer('asr', at(15, 30)),
    _prayer('maghrib', at(18, 0)),
    _prayer('isha', at(19, 30)),
  ];
}

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

  group('nextPrayer (shared countdown resolution)', () {
    final today = DateTime(2026, 9, 25);
    final prayers = _day(today);

    test('returns the first future prayer of the day', () {
      final next = PrayerTimesService.nextPrayer(
        prayers,
        now: DateTime(2026, 9, 25, 0, 0),
      );
      expect(next!.name, 'fajr');
    });

    test('skips sunrise — it is not a prayer and carries no adhan', () {
      final next = PrayerTimesService.nextPrayer(
        prayers,
        now: DateTime(2026, 9, 25, 5, 0),
      );
      expect(next!.name, 'dhuhr');
    });

    test('a prayer exactly at [now] counts as passed (transition boundary)',
        () {
      final next = PrayerTimesService.nextPrayer(
        prayers,
        now: DateTime(2026, 9, 25, 18, 0),
      );
      expect(next!.name, 'isha');
    });

    test('returns null once isha has passed', () {
      expect(
        PrayerTimesService.nextPrayer(
          prayers,
          now: DateTime(2026, 9, 25, 23, 59),
        ),
        isNull,
      );
    });
  });

  group('nextPrayerOrTomorrow (after-Isha roll-over)', () {
    final today = DateTime(2026, 9, 25);
    final prayers = _day(today);
    final tomorrow = _day(today, shiftDays: 1);

    test('prefers a remaining prayer of today', () {
      final next = PrayerTimesService.nextPrayerOrTomorrow(
        prayers,
        tomorrow,
        now: DateTime(2026, 9, 25, 13, 0),
      );
      expect(next!.name, 'asr');
      expect(next.time.day, 25);
    });

    test('rolls into tomorrow\'s real Fajr after Isha', () {
      final now = DateTime(2026, 9, 25, 22, 0);
      final next = PrayerTimesService.nextPrayerOrTomorrow(
        prayers,
        tomorrow,
        now: now,
      );
      expect(next!.name, 'fajr');
      expect(next.time.day, 26);
      // The countdown target must always be in the future — the old
      // background fallback guessed 05:00 and could count down to a
      // time that had already happened.
      expect(next.time.difference(now).isNegative, isFalse);
    });

    test('returns null when both day lists are empty', () {
      expect(
        PrayerTimesService.nextPrayerOrTomorrow(
          const [],
          const [],
          now: DateTime(2026, 9, 25, 22, 0),
        ),
        isNull,
      );
    });

    test('screen and notification agree: same inputs give same target', () {
      // Both displays now go through this one function; resolving twice
      // with the same day lists and instant must never diverge.
      final now = DateTime(2026, 9, 25, 23, 30);
      final a = PrayerTimesService.nextPrayerOrTomorrow(prayers, tomorrow, now: now);
      final b = PrayerTimesService.nextPrayerOrTomorrow(prayers, tomorrow, now: now);
      expect(a!.time, b!.time);
    });
  });

  group('calculate: timezone, location and day-boundary handling', () {
    const zalda = (lat: 36.5744, lng: 3.1146);

    test('the same inputs produce identical times on repeated calls',
        () async {
      // The main isolate and the background isolate call this one function
      // with the mirrored settings; determinism is what keeps the screen
      // and the ongoing notification showing the same Maghrib.
      final first = await PrayerTimesService.calculate(
        latitude: zalda.lat,
        longitude: zalda.lng,
        madhab: 'shafi',
        method: 'MWL',
        date: summerSolstice,
        timezone: 'Africa/Algiers',
      );
      final second = await PrayerTimesService.calculate(
        latitude: zalda.lat,
        longitude: zalda.lng,
        madhab: 'shafi',
        method: 'MWL',
        date: summerSolstice,
        timezone: 'Africa/Algiers',
      );
      for (var i = 0; i < first.length; i++) {
        expect(first[i].time, second[i].time);
      }
    });

    test('a differing calc method changes Maghrib, matching the +5 Algeria adjustment',
        () async {
      final mwl = await PrayerTimesService.calculate(
        latitude: zalda.lat,
        longitude: zalda.lng,
        madhab: 'shafi',
        method: 'MWL',
        date: summerSolstice,
        timezone: 'Africa/Algiers',
      );
      final algeria = await PrayerTimesService.calculate(
        latitude: zalda.lat,
        longitude: zalda.lng,
        madhab: 'shafi',
        method: 'Algeria',
        date: summerSolstice,
        timezone: 'Africa/Algiers',
      );
      final mwlMaghrib = mwl.firstWhere((p) => p.name == 'maghrib').time;
      final algeriaMaghrib = algeria.firstWhere((p) => p.name == 'maghrib').time;
      // The Algeria method applies a +5 min maghrib methodAdjustment on top
      // of its angles — the exact gap the diverging defaults used to create
      // between the screen (MWL) and the notification (Algeria fallback).
      expect(algeriaMaghrib.isAfter(mwlMaghrib), isTrue);
      expect(
        algeriaMaghrib.difference(mwlMaghrib).inMinutes,
        lessThanOrEqualTo(10),
      );
    });

    test('timezone only changes the wall-clock view, not the instants',
        () async {
      final algiers = await PrayerTimesService.calculate(
        latitude: zalda.lat,
        longitude: zalda.lng,
        madhab: 'shafi',
        method: 'MWL',
        date: summerSolstice,
        timezone: 'Africa/Algiers',
      );
      final utc = await PrayerTimesService.calculate(
        latitude: zalda.lat,
        longitude: zalda.lng,
        madhab: 'shafi',
        method: 'MWL',
        date: summerSolstice,
        timezone: 'UTC',
      );
      for (var i = 0; i < algiers.length; i++) {
        expect(
          algiers[i].time.toUtc(),
          utc[i].time.toUtc(),
          reason: algiers[i].name,
        );
      }
      expect(algiers.first.time, isA<tz.TZDateTime>());
    });

    test('DST transition: London prayers keep sane local times and shift their UTC offset',
        () async {
      const london = (lat: 51.5074, lng: -0.1278);
      // UK summer time begins 29 March 2026 — bracket the switch.
      final beforeDst = await PrayerTimesService.calculate(
        latitude: london.lat,
        longitude: london.lng,
        madhab: 'shafi',
        method: 'MWL',
        date: DateTime(2026, 3, 28),
        timezone: 'Europe/London',
      );
      final afterDst = await PrayerTimesService.calculate(
        latitude: london.lat,
        longitude: london.lng,
        madhab: 'shafi',
        method: 'MWL',
        date: DateTime(2026, 3, 30),
        timezone: 'Europe/London',
      );

      _expectStrictlyOrdered(beforeDst);
      _expectStrictlyOrdered(afterDst);

      final beforeDhuhr = beforeDst.firstWhere((p) => p.name == 'dhuhr').time;
      final afterDhuhr = afterDst.firstWhere((p) => p.name == 'dhuhr').time;
      // Wall-clock dhuhr stays near solar noon across the switch — the
      // TZDateTime conversion must absorb the DST hour, not shift it.
      expect(beforeDhuhr.hour, inInclusiveRange(11, 13));
      expect(afterDhuhr.hour, inInclusiveRange(11, 13));

      // And the offset itself proves the DST rule was applied per-day.
      expect((beforeDhuhr as tz.TZDateTime).timeZoneOffset, Duration.zero);
      expect((afterDhuhr as tz.TZDateTime).timeZoneOffset, const Duration(hours: 1));
    });

    test('roll-over across midnight uses tomorrow\'s computed Fajr, not a guess',
        () async {
      const london = (lat: 51.5074, lng: -0.1278);
      Future<List<PrayerTimeInfo>> forDay(DateTime d) =>
          PrayerTimesService.calculate(
            latitude: london.lat,
            longitude: london.lng,
            madhab: 'shafi',
            method: 'MWL',
            date: d,
            timezone: 'Europe/London',
          );
      final today = await forDay(DateTime(2026, 12, 31));
      final tomorrow = await forDay(DateTime(2027, 1, 1));

      final now = DateTime(2026, 12, 31, 23, 30);
      final next = PrayerTimesService.nextPrayerOrTomorrow(
        today,
        tomorrow,
        now: now,
      );
      expect(next!.name, 'fajr');
      expect(next.time.isAfter(now), isTrue);
      // New Year's Fajr is on the 1st of the next month/year — the day
      // arithmetic in the roll-over must not clamp to the old month.
      expect(next.time.day, 1);
      expect(next.time.month, 1);
      expect(next.time.year, 2027);
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
