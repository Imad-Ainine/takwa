import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/notifications/notifications_service.dart';
import '../../features/settings/data/user_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'adhkar_progress_repository.dart';
import 'shared_preferences_provider.dart';
import '../../features/adhkar/data/adhkar_data.dart';
export '../../features/adhkar/data/adhkar_data.dart';

final adhkarProgressRepositoryProvider = Provider<AdhkarProgressRepository>((
  ref,
) {
  return AdhkarProgressRepository(ref.watch(sharedPreferencesProvider));
});

// ── حالة تقدم كل تصنيف (index → count) ──
class AdhkarProgressNotifier extends StateNotifier<Map<int, int>> {
  final AdhkarCategory category;
  final AdhkarProgressRepository _repo;

  AdhkarProgressNotifier(this.category, this._repo)
    : super(_repo.getProgress(category.name));

  void increment(int index, int maxCount) {
    final current = state[index] ?? 0;
    if (current >= maxCount) return;
    state = {...state, index: current + 1};
    _repo.setProgress(category.name, state);
  }

  void reset() {
    state = {};
    _repo.setProgress(category.name, state);
  }
}

final adhkarProgressProvider =
    StateNotifierProvider.family<
      AdhkarProgressNotifier,
      Map<int, int>,
      AdhkarCategory
    >(
      (ref, cat) => AdhkarProgressNotifier(
        cat,
        ref.watch(adhkarProgressRepositoryProvider),
      ),
    );

/// The one place that puts adhkar and dua reminders on the OS alarm queue.
///
/// It used to be two: this class scheduled the morning/evening/sleep
/// reminders while the background-service isolate posted an extra adhkar and
/// an extra dua every 15 minutes (~96 a day, ~14 of them after midnight),
/// ignoring every toggle in the settings sheet — so the reminders a user
/// switched off kept arriving, and the ones they switched on
/// (بعد الفجر / بعد العصر) never did.
///
/// Reminders come in two kinds, and the difference is why both exist:
///
/// * **Clock-timed** — أذكار النوم at a bedtime the user picks. One
///   daily-repeating alarm.
/// * **Prayer-anchored** — أذكار الصباح after Fajr, أذكار المساء after Asr.
///   These cannot sit on a fixed clock: Fajr drifts by around half an hour
///   between the solstices, so a hardcoded 05:15 spends part of the year
///   announcing the morning litany before the prayer it belongs to. They are
///   scheduled as one-shot alarms across the same rolling horizon as the
///   prayer alerts, from the same calculation.
///
/// A category is anchored *instead of* clock-timed, never both — otherwise the
/// user is pinged twice for the same adhkar. When no location is stored yet
/// the anchored reminders fall back to the clock time rather than silently
/// vanishing.
class AdhkarNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Daily-repeating reminders — one id each, replaced by the next reschedule.
  static const _morningId = NotifIds.adhkarMorning;
  static const _eveningId = NotifIds.adhkarEvening;
  static const _sleepId = NotifIds.adhkarSleep;

  static const _repeatingIds = [_morningId, _eveningId, _sleepId];

  /// Length of the collapsed notification body. The full dhikr, its
  /// repetition count, virtue and source go in the expanded big text.
  static const _previewChars = 110;

  static Future<void> rescheduleAll(
    UserPreferences prefs, {
    required AppLocalizations l10n,
    double? latitude,
    double? longitude,
    String? timezone,
    int days = kPrayerScheduleDays,
  }) async {
    await cancelAll();
    if (!prefs.adhkarNotifEnabled) return;

    final anchored = latitude != null && longitude != null;
    final morningAtFajr = anchored && prefs.afterFajrAdhkar;
    final eveningAtAsr = anchored && prefs.afterAsrAdhkar;

    if (prefs.morningAdhkarReminder && !morningAtFajr) {
      await _scheduleDaily(
        category: AdhkarCategory.morning,
        id: _morningId,
        time: prefs.morningAdhkarTime,
        title: l10n.notifAdhkarMorningTitle,
        channelName: l10n.notifAdhkarMorningChannelName,
        l10n: l10n,
      );
    }

    if (prefs.eveningAdhkarReminder && !eveningAtAsr) {
      await _scheduleDaily(
        category: AdhkarCategory.evening,
        id: _eveningId,
        time: prefs.eveningAdhkarTime,
        title: l10n.notifAdhkarEveningTitle,
        channelName: l10n.notifAdhkarEveningChannelName,
        l10n: l10n,
      );
    }

    if (prefs.sleepAdhkarReminder) {
      await _scheduleDaily(
        category: AdhkarCategory.sleep,
        id: _sleepId,
        time: prefs.sleepAdhkarTime,
        title: l10n.notifAdhkarSleepTitle,
        channelName: l10n.notifAdhkarSleepChannelName,
        l10n: l10n,
      );
    }

    final anchors = <_PrayerAnchor>[
      if (prefs.morningAdhkarReminder && morningAtFajr)
        _PrayerAnchor(
          prayer: 'fajr',
          category: AdhkarCategory.morning,
          title: l10n.notifAdhkarAfterFajrTitle,
          channelName: l10n.notifAdhkarMorningChannelName,
          id: NotifIds.afterFajrAdhkarId,
        ),
      if (prefs.eveningAdhkarReminder && eveningAtAsr)
        _PrayerAnchor(
          prayer: 'asr',
          category: AdhkarCategory.evening,
          title: l10n.notifAdhkarAfterAsrTitle,
          channelName: l10n.notifAdhkarEveningChannelName,
          id: NotifIds.afterAsrAdhkarId,
        ),
    ];
    if (anchors.isEmpty) return;

    // iOS keeps at most 64 pending local notifications and the prayer horizon
    // already claims most of that budget, so two anchored days is what is
    // left; Android's queue is unbounded and keeps the full horizon.
    final anchoredDays = Platform.isIOS && days > 2 ? 2 : days;

    await _schedulePrayerAnchored(
      anchors: anchors,
      prefs: prefs,
      l10n: l10n,
      latitude: latitude!,
      longitude: longitude!,
      timezone: timezone,
      days: anchoredDays,
    );
  }

  /// One daily-repeating alarm at a wall-clock time.
  static Future<void> _scheduleDaily({
    required AdhkarCategory category,
    required int id,
    required TimeOfDay time,
    required String title,
    required String channelName,
    required AppLocalizations l10n,
  }) async {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _fire(
      id: id,
      category: category,
      title: title,
      when: next,
      channelName: channelName,
      l10n: l10n,
      repeatDaily: true,
    );
  }

  static Future<void> _schedulePrayerAnchored({
    required List<_PrayerAnchor> anchors,
    required UserPreferences prefs,
    required AppLocalizations l10n,
    required double latitude,
    required double longitude,
    required String? timezone,
    required int days,
  }) async {
    final today = DateTime.now();
    for (var dayOffset = 0; dayOffset < days; dayOffset++) {
      final date = DateTime(today.year, today.month, today.day + dayOffset);
      final List<PrayerTimeInfo> prayers;
      try {
        prayers = await PrayerTimesService.calculate(
          latitude: latitude,
          longitude: longitude,
          madhab: prefs.madhab,
          method: prefs.calcMethod,
          highLatitudeRule: prefs.highLatitudeRule,
          fajrOffset: prefs.fajrOffset,
          sunriseOffset: prefs.sunriseOffset,
          dhuhrOffset: prefs.dhuhrOffset,
          asrOffset: prefs.asrOffset,
          maghribOffset: prefs.maghribOffset,
          ishaOffset: prefs.ishaOffset,
          date: date,
          timezone: timezone,
        );
      } catch (e) {
        // One uncomputable day (a weird timezone rule, a date edge case) must
        // not cost the user the rest of the horizon.
        debugPrint('[AdhkarNotificationService] day $dayOffset skipped: $e');
        continue;
      }

      for (final anchor in anchors) {
        final matches = prayers.where((p) => p.name == anchor.prayer).toList();
        if (matches.isEmpty) continue;
        await _fire(
          id: anchor.id(dayOffset),
          category: anchor.category,
          title: anchor.title,
          when: matches.first.time.add(
            Duration(minutes: prefs.adhkarAfterPrayerMinutes),
          ),
          channelName: anchor.channelName,
          l10n: l10n,
        );
      }
    }
  }

  static Future<void> _fire({
    required int id,
    required AdhkarCategory category,
    required String title,
    required DateTime when,
    required String channelName,
    required AppLocalizations l10n,
    bool repeatDaily = false,
  }) async {
    final dhikr = _dhikrFor(category, when);
    if (dhikr == null) return;

    await _safeZonedSchedule(
      id,
      '${category.emoji} $title',
      _preview(dhikr.arabic),
      tz.TZDateTime.from(when, tz.local),
      _buildDetails(
        channelId: 'adhkar_${category.name}',
        channelName: channelName,
        channelDesc: l10n.notifAdhkarChannelDesc,
        bigText: _fullText(dhikr),
        actions: [
          AndroidNotificationAction(
            'read_${category.name}',
            l10n.notifAdhkarActionRead,
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'open_${category.name}',
            l10n.notifAdhkarActionOpen,
            showsUserInterface: true,
            cancelNotification: false,
          ),
        ],
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      // `adhkar:<category>` — the router opens that category's tab, so the
      // tap lands on what the reminder was about instead of the first tab.
      payload: 'adhkar:${category.name}',
    );
  }

  static Future<void> cancelAll() async {
    for (final id in _repeatingIds) {
      await _plugin.cancel(id);
    }
    for (var day = 0; day < kPrayerScheduleDays; day++) {
      await _plugin.cancel(NotifIds.afterFajrAdhkarId(day));
      await _plugin.cancel(NotifIds.afterAsrAdhkarId(day));
    }
  }

  static Future<void> _safeZonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation
    uiLocalNotificationDateInterpretation,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: androidScheduleMode,
        uiLocalNotificationDateInterpretation:
            uiLocalNotificationDateInterpretation,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted' ||
          (e.message?.contains('exact_alarms_not_permitted') ?? false)) {
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                uiLocalNotificationDateInterpretation,
            matchDateTimeComponents: matchDateTimeComponents,
            payload: payload,
          );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[AdhkarNotificationService] _safeZonedSchedule error: $e');
    }
  }

  static NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
    required String channelDesc,
    String? bigText,
    List<AndroidNotificationAction>? actions,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFFC8A96E),
        styleInformation: bigText != null
            ? BigTextStyleInformation(
                bigText,
                contentTitle: channelName,
                htmlFormatBigText: false,
              )
            : null,
        actions: actions,
        groupKey: 'adhkar_group',
        playSound: false,
        enableVibration: false,
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'adhkar_category',
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );
  }

  /// The dhikr a reminder shows for [category] on [date].
  ///
  /// Rotated by day-of-year rather than shuffled: coverage is even, and the
  /// same day always yields the same dhikr, so a reschedule that re-runs for
  /// today cannot swap the text under an alarm that is already queued.
  static DhikrItem? _dhikrFor(AdhkarCategory category, DateTime date) {
    final list = kAdhkarData[category];
    if (list == null || list.isEmpty) return null;
    return list[date.dayOfYear % list.length];
  }

  /// Short form for the collapsed body, cut at a word boundary.
  ///
  /// The `.substring(0, 80)` this replaces chopped Arabic words in half
  /// mid-sentence — visible on every reminder of a long dhikr like آية الكرسي.
  static String _preview(String text) {
    final clean = _oneLine(text);
    if (clean.length <= _previewChars) return clean;
    var cut = clean.substring(0, _previewChars);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace > _previewChars * 3 ~/ 4) cut = cut.substring(0, lastSpace);
    return '$cut…';
  }

  /// The expanded body: the whole dhikr, then how often it is repeated, its
  /// virtue and its source — so the reminder is readable on its own without
  /// opening the app.
  static String _fullText(DhikrItem dhikr) {
    return [
      _oneLine(dhikr.arabic),
      if (dhikr.count > 1) '🔁 ×${dhikr.count}',
      if (dhikr.fadl != null && dhikr.fadl!.isNotEmpty) '✨ ${dhikr.fadl}',
      if (dhikr.source != null && dhikr.source!.isNotEmpty) '— ${dhikr.source}',
    ].join('\n\n');
  }

  static String _oneLine(String text) =>
      text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// An adhkar reminder that follows a prayer instead of a clock: which prayer,
/// which litany it draws from, where its per-day alarm ids live, and how it is
/// labelled.
class _PrayerAnchor {
  final String prayer;
  final AdhkarCategory category;
  final String title;
  final String channelName;
  final int Function(int dayOffset) id;

  const _PrayerAnchor({
    required this.prayer,
    required this.category,
    required this.title,
    required this.channelName,
    required this.id,
  });
}

extension on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return DateTime(year, month, day).difference(start).inDays + 1;
  }
}
