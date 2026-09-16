import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math' as math;
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

// Legacy SharedPreference providers removed since we now use UserPreferences.
class AdhkarNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _morningId = 310;
  static const _eveningId = 311;
  static const _afterFajrId = 312;
  static const _afterAsrId = 313;
  static const _sleepId = 314;
  static const _dhikrId = 315;

  static Future<void> rescheduleAll(
    UserPreferences prefs, {
    required AppLocalizations l10n,
  }) async {
    await cancelAll();

    if (prefs.adhkarNotifEnabled) {
      if (prefs.morningAdhkarReminder) {
        await scheduleMorning(prefs.morningAdhkarTime, l10n: l10n);
      }
      if (prefs.eveningAdhkarReminder) {
        await scheduleEvening(prefs.eveningAdhkarTime, l10n: l10n);
      }
      // Assuming sleep reminders are global if adhkarNotifEnabled is true
      await _scheduleSleep(prefs.sleepAdhkarTime, l10n: l10n);
    }
  }

  static Future<void> _scheduleSleep(
    TimeOfDay time, {
    required AppLocalizations l10n,
  }) async {
    await _cancelId(_sleepId);
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final dhikr = _randomDhikr(AdhkarCategory.sleep);
    await _safeZonedSchedule(
      _sleepId,
      '🌙 ${l10n.notifAdhkarSleepTitle}',
      dhikr.arabic
          .replaceAll('\n', ' ')
          .substring(0, dhikr.arabic.length > 80 ? 80 : dhikr.arabic.length),
      tz.TZDateTime.from(scheduled, tz.local),
      _buildDetails(
        channelId: 'adhkar_sleep',
        channelName: l10n.notifAdhkarSleepChannelName,
        channelDesc: l10n.notifAdhkarChannelDesc,
        actions: [
          AndroidNotificationAction(
            'read_sleep',
            l10n.notifAdhkarActionRead,
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'adhkar:sleep',
    );
  }

  static Future<void> scheduleMorning(
    TimeOfDay time, {
    required AppLocalizations l10n,
  }) async {
    await _cancelId(_morningId);

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final dhikr = _randomDhikr(AdhkarCategory.morning);

    await _safeZonedSchedule(
      _morningId,
      '🌅 ${l10n.notifAdhkarMorningTitle}',
      dhikr.arabic
          .replaceAll('\n', ' ')
          .substring(0, dhikr.arabic.length > 80 ? 80 : dhikr.arabic.length),
      tz.TZDateTime.from(scheduled, tz.local),
      _buildDetails(
        channelId: 'adhkar_morning',
        channelName: l10n.notifAdhkarMorningChannelName,
        channelDesc: l10n.notifAdhkarChannelDesc,
        actions: [
          AndroidNotificationAction(
            'read_morning',
            l10n.notifAdhkarActionRead,
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'open_morning',
            l10n.notifAdhkarActionOpen,
            showsUserInterface: true,
            cancelNotification: false,
          ),
        ],
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'adhkar:morning',
    );
  }

  static Future<void> scheduleEvening(
    TimeOfDay time, {
    required AppLocalizations l10n,
  }) async {
    await _cancelId(_eveningId);

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final dhikr = _randomDhikr(AdhkarCategory.evening);

    await _safeZonedSchedule(
      _eveningId,
      '🌆 ${l10n.notifAdhkarEveningTitle}',
      dhikr.arabic
          .replaceAll('\n', ' ')
          .substring(0, dhikr.arabic.length > 80 ? 80 : dhikr.arabic.length),
      tz.TZDateTime.from(scheduled, tz.local),
      _buildDetails(
        channelId: 'adhkar_evening',
        channelName: l10n.notifAdhkarEveningChannelName,
        channelDesc: l10n.notifAdhkarChannelDesc,
        actions: [
          AndroidNotificationAction(
            'read_evening',
            l10n.notifAdhkarActionRead,
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'open_evening',
            l10n.notifAdhkarActionOpen,
            showsUserInterface: true,
            cancelNotification: false,
          ),
        ],
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'adhkar:evening',
    );
  }

  static Future<void> scheduleDailyDhikr({
    required TimeOfDay time,
    AdhkarCategory category = AdhkarCategory.misc,
  }) async {
    await _cancelId(_dhikrId);

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final dhikr = _randomDhikr(category);
    final arabic = dhikr.arabic.replaceAll('\n', ' ');
    final preview = arabic.length > 100
        ? '${arabic.substring(0, 100)}...'
        : arabic;

    await _safeZonedSchedule(
      _dhikrId,
      '📿 ذكر اليوم',
      preview,
      tz.TZDateTime.from(scheduled, tz.local),
      _buildDetails(
        channelId: 'adhkar_daily',
        channelName: 'ذكر اليوم',
        bigText: arabic + (dhikr.fadl != null ? '\n\n✨ ${dhikr.fadl}' : ''),
        actions: [
          AndroidNotificationAction(
            'read_dhikr_${dhikr.id}',
            'قرأت الذكر ✓',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'share_dhikr',
            'مشاركة',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'dhikr:${dhikr.id}',
    );
  }

  static Future<void> showDhikrNow(DhikrItem dhikr) async {
    final arabic = dhikr.arabic.replaceAll('\n', ' ');

    await _plugin.show(
      _dhikrId + dhikr.id,
      '📿 ${_categoryName(dhikr.category)}',
      arabic.length > 80 ? '${arabic.substring(0, 80)}...' : arabic,
      _buildDetails(
        channelId: 'adhkar_instant',
        channelName: 'أذكار فورية',
        bigText:
            arabic +
            (dhikr.fadl != null ? '\n\n✨ الفضل: ${dhikr.fadl}' : '') +
            (dhikr.source != null ? '\n— ${dhikr.source}' : ''),
        actions: [
          AndroidNotificationAction(
            'read_done_${dhikr.id}',
            'قرأت الذكر ✓',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'repeat_${dhikr.id}',
            'أعد لاحقاً 🔁',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
      ),
      payload: 'instant_dhikr:${dhikr.id}',
    );
  }

  static Future<void> cancelAll() async {
    for (final id in [
      _morningId,
      _eveningId,
      _afterFajrId,
      _afterAsrId,
      _sleepId,
      _dhikrId,
    ]) {
      await _plugin.cancel(id);
    }
  }

  static Future<void> _cancelId(int id) => _plugin.cancel(id);

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
    // Defaults to the old hardcoded Arabic description for
    // scheduleDailyDhikr()/showDhikrNow(), which aren't called from
    // anywhere in the app today (dead code) and so weren't threaded a
    // locale — see the i18n audit note on this class.
    String channelDesc = 'أذكار وأدعية من حصن المسلم',
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

  static DhikrItem _randomDhikr(AdhkarCategory cat) {
    final list = kAdhkarData[cat] ?? kAdhkarData[AdhkarCategory.misc]!;
    final rng = math.Random(DateTime.now().dayOfYear);
    return list[rng.nextInt(list.length)];
  }

  // تم تحديث الدالة لتدعم التصنيفات الجديدة ✅
  static String _categoryName(AdhkarCategory cat) => switch (cat) {
    AdhkarCategory.wakingUp => 'أذكار الاستيقاظ',
    AdhkarCategory.morning => 'أذكار الصباح',
    AdhkarCategory.evening => 'أذكار المساء',
    AdhkarCategory.afterPrayer => 'أذكار بعد الصلاة',
    AdhkarCategory.sleep => 'أذكار النوم',
    AdhkarCategory.food => 'أذكار الطعام',
    AdhkarCategory.misc => 'أذكار متنوعة',
  };
}

extension on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays + 1;
  }
}
