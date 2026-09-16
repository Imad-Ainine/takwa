import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:hijri/hijri_calendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../notifications/notifications_service.dart';
import '../utils/hijri_display.dart';
import '../utils/prayer_display.dart';
import 'home_widget_ids.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Keeps the home-screen prayer-times widget (Android `PrayerWidgetProvider`
/// / iOS `PrayerWidget`) in sync.
///
/// Neither native side computes a single prayer time itself — they only
/// render whatever JSON blob this class last wrote. Call [update] any time
/// `prayerTimesProvider` produces new data or the app locale changes (see
/// the `ref.listen`s in `main.dart`'s `_TakwaAppState.build`).
class PrayerHomeWidgetService {
  PrayerHomeWidgetService._();

  /// Must match the Android `<receiver android:name="...">` in
  /// AndroidManifest.xml (see PrayerWidgetProvider.kt).
  static const androidWidgetName = 'PrayerWidgetProvider';

  /// The 4×3 "large" size variant (PrayerWidgetLargeProvider.kt) — a
  /// separate picker entry, but it reads the exact same `_dataKey` payload,
  /// so every push here has to reach it too, not just [androidWidgetName].
  static const androidLargeWidgetName = 'PrayerWidgetLargeProvider';

  /// Must match the `kind:` the iOS extension registers its Widget under
  /// (see ios/PrayerWidget/PrayerWidget.swift).
  static const iOSWidgetName = 'PrayerWidget';

  /// Shared storage container the iOS app target and every widget
  /// extension both read/write. See [HomeWidgetIds.iOSAppGroupId].
  static const iOSAppGroupId = HomeWidgetIds.iOSAppGroupId;

  static const _dataKey = 'prayer_widget_data';

  /// Prayer keys shown on the widget, in chronological order. `sunrise` is
  /// part of [PrayerTimeInfo] (used elsewhere for the "no more prayers
  /// today" countdown) but isn't a prayer, so it's left out here — same as
  /// the reference widget this mirrors.
  static const _displayOrder = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  /// One-time setup — call once at app start, before the first [update].
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(iOSAppGroupId);
    } catch (e) {
      debugPrint('[PrayerHomeWidgetService] init failed: $e');
    }
  }

  /// Pushes today's prayer times to the widget and asks the platform to
  /// redraw it.
  ///
  /// Also arms Android's own alarm-based schedule (via
  /// [HomeWidget.scheduleWidgetUpdates]) for the remaining prayer times
  /// today, so the "next prayer" highlight moves on even while the app is
  /// closed. iOS needs no equivalent call: WidgetKit derives that from the
  /// per-prayer `date`s this writes into the timeline data instead.
  static Future<void> update({
    required List<PrayerTimeInfo> prayers,
    required Locale locale,
  }) async {
    if (prayers.isEmpty) return;
    try {
      final byKey = {for (final p in prayers) p.name: p};
      final ordered = _displayOrder
          .map((key) => byKey[key])
          .whereType<PrayerTimeInfo>()
          .toList();
      if (ordered.isEmpty) return;

      final l10n = lookupAppLocalizations(locale);
      final isArabic = locale.languageCode == 'ar';
      final now = DateTime.now();
      final hijri = HijriCalendar.now();
      final next = PrayerTimesService.nextPrayer(prayers);

      final payload = {
        'isRtl': isArabic,
        'weekday': DateFormat('EEEE', isArabic ? 'ar' : 'en').format(now),
        'hijri': '${hijri.hDay} ${hijriMonthName(l10n, hijri.hMonth)}',
        'gregorian': DateFormat(
          'd MMMM',
          isArabic ? 'ar' : 'en',
        ).format(now),
        'nextKey': next?.name,
        'prayers': [
          for (final p in ordered)
            {
              'key': p.name,
              'label': prayerLocalizedName(l10n, p.name),
              'time': _formatTime(p.time),
              'timestampMs': p.time.millisecondsSinceEpoch,
            },
        ],
      };

      await HomeWidget.saveWidgetData<String>(_dataKey, jsonEncode(payload));
      // Both size variants read this same payload but are registered as
      // two separate AppWidgetProviders, so each needs its own
      // updateWidget()/scheduleWidgetUpdates() call — home_widget has no
      // "these names share one push" shorthand.
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
      await HomeWidget.updateWidget(androidName: androidLargeWidgetName);

      final upcoming = ordered
          .map((p) => p.time)
          .where((t) => t.isAfter(now))
          .toList();
      if (upcoming.isNotEmpty) {
        await HomeWidget.scheduleWidgetUpdates(
          upcoming,
          androidName: androidWidgetName,
        );
        await HomeWidget.scheduleWidgetUpdates(
          upcoming,
          androidName: androidLargeWidgetName,
        );
      }
    } catch (e) {
      // Best-effort: a widget that fails to refresh must never crash the
      // app — worst case it shows stale times until the next successful
      // update.
      debugPrint('[PrayerHomeWidgetService] update failed: $e');
    }
  }

  static String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
