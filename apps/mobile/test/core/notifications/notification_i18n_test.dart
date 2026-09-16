// Regression test for the i18n audit's notification-text finding:
// NotificationsService used to build every scheduled title/body from
// hardcoded Arabic literals and PrayerTimeInfo.nameAr, so a user on the
// English UI still got Arabic prayer/adhkar notifications. The fix threads
// an AppLocalizations instance through the scheduling methods instead —
// this locks in that the ARB-backed strings actually resolve per locale,
// without needing to mock the notification plugin's platform channel just
// to exercise plain string building.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/utils/prayer_display.dart';
import 'package:takwa/l10n/app_localizations.dart';

void main() {
  final ar = lookupAppLocalizations(const Locale('ar'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('prayerLocalizedName follows locale instead of always Arabic', () {
    expect(prayerLocalizedName(ar, 'dhuhr'), 'الظهر');
    expect(prayerLocalizedName(en, 'dhuhr'), isNot('الظهر'));
    expect(prayerLocalizedName(en, 'dhuhr'), en.prayerDhuhr);
  });

  test('adhan/iqama notification text interpolates the localized name', () {
    final name = prayerLocalizedName(en, 'fajr');
    expect(en.notifAdhanTitle(name), contains(name));
    expect(en.notifAdhanTitle(name), isNot(contains('الفجر')));
    expect(en.notifPreAdhanBody(name), contains(name));
    expect(en.notifIqamaBody(name), contains(name));
  });

  test('white-days body carries both placeholders through', () {
    expect(
      en.notifWhiteDaysBody(13, 'Shaban'),
      'Tomorrow is day 13 of Shaban in the Hijri calendar — fasting the '
      'White Days is a confirmed Sunnah',
    );
  });

  test('achievement notification chrome is locale-aware', () {
    expect(en.notifAchievementNewPrefix('Streak 7'), contains('Streak 7'));
    expect(en.notifAchievementNewPrefix('Streak 7'), isNot(contains('إنجاز')));
    expect(en.notifAchievementPointsSuffix(20), contains('20'));
  });

  test('ar/en ship distinct strings for every new notification key', () {
    // A sanity check that these keys were actually translated, not just
    // copy-pasted from the Arabic template into app_en.arb.
    expect(ar.notifMuhasabaTitle, isNot(en.notifMuhasabaTitle));
    expect(ar.notifSuhoorBody, isNot(en.notifSuhoorBody));
    expect(ar.notifAdhkarActionRead, isNot(en.notifAdhkarActionRead));
  });
}
