// P1 #7 guard: PrayerScheduleParams is the single source for the iqama
// offsets and the pre-adhan lead. Before this, the offset map existed
// twice (prayer_screen's _kIqamaOffsets + a private literal inside
// NotificationsService.schedulePrayerNotifications), so an edit to one
// silently desynced the on-screen iqama countdown from the scheduled
// notification. These tests pin the values and the unknown-key fallback
// every call site relies on.

import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/utils/prayer_schedule_params.dart';

void main() {
  test('known prayers keep their documented iqama offsets', () {
    expect(PrayerScheduleParams.iqamaOffsets, {
      'fajr': 20,
      'dhuhr': 15,
      'asr': 15,
      'maghrib': 5,
      'isha': 15,
    });
  });

  test('unknown prayer names fall back to 15 minutes', () {
    expect(PrayerScheduleParams.iqamaOffsetMinutes('sunrise'), 15);
    expect(PrayerScheduleParams.iqamaOffset('jumuah'), const Duration(minutes: 15));
  });

  test('pre-adhan lead is 15 minutes', () {
    expect(PrayerScheduleParams.preAdhanLead, const Duration(minutes: 15));
  });
}
