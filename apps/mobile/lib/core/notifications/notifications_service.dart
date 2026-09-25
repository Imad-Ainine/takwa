import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart' as adhan;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:takwa/features/duas/data/duas_data.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/providers/locale_provider.dart';
import 'package:takwa/core/providers/shared_preferences_provider.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/providers/adhkar_providers.dart';
import 'package:takwa/core/utils/prayer_display.dart';
import 'package:takwa/core/utils/timezone_resolver.dart';
import 'package:takwa/features/settings/data/user_preferences.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';
import 'package:takwa/app/main_shell.dart' show currentTabProvider;
import 'package:takwa/l10n/app_localizations.dart';

// ─────────────────────────────────────────
//  NOTIFICATION IDs
// ─────────────────────────────────────────
class NotifIds {
  // الصلوات الخمس
  static const fajr = 100;
  static const dhuhr = 101;
  static const asr = 102;
  static const maghrib = 103;
  static const isha = 104;

  // تنبيهات قبل الأذان بـ 15 دقيقة
  static const preFajr = 110;
  static const preDhuhr = 111;
  static const preAsr = 112;
  static const preMaghrib = 113;
  static const preIsha = 114;

  // تنبيهات الإقامة
  static const iqamaFajr = 120;
  static const iqamaDhuhr = 121;
  static const iqamaAsr = 122;
  static const iqamaMaghrib = 123;
  static const iqamaIsha = 124;

  // محاسبة مسائية
  static const eveningMuhasaba = 200;

  // أذكار — the ids AdhkarNotificationService schedules under; its
  // prayer-anchored one-shots use the 4000/4100 blocks further below.
  static const adhkarMorning = 310;
  static const adhkarEvening = 311;
  static const adhkarSleep = 314;

  // أدعية
  static const dailyDua = 404;

  /// Superseded by [dailyDua] — kept so `cancelDailyDuas()` can clear alarms
  /// a user scheduled under an older build.
  static const dailyDuaMorning = 401;
  static const dailyDuaEvening = 402;
  static const distressDua = 403;

  // تذكيرات خاصة
  static const fridayKahf = 500;
  static const fridaySalawat = 501;
  static const fastingMonday = 502;
  static const fastingThursday = 503;
  static const fastingWhiteDays = 504;

  // إنجازات
  static const achievement = 600;

  // رمضان
  static const ramadanSuhoor = 700;
  static const ramadanIftar = 701;

  // تنبيهات الاستيقاظ
  static const wakeUpAlarm = 800;

  // تحديثات التطبيق
  static const appUpdate = 900;

  // ── تنبيهات الصلاة على مدى عدة أيام ──
  // The five ids above (100–124) are single-day slots: whoever schedules last
  // overwrites them. They're kept for the cancel paths, but the horizon below
  // is what actually gets written now.

  /// Internal prayer ids in canonical order. A prayer's index here is the
  /// ones digit of its horizon alert id — see [_prayerAlertId].
  static const prayerOrder = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  /// Prayer-alert id bases, one block per alert kind, placed far above the
  /// single-shot ids so nothing collides.
  static const _adhanIdBase = 1000;
  static const _preAdhanIdBase = 2000;
  static const _iqamaIdBase = 3000;

  /// `<base> + dayOffset * 10 + prayerIndex` — one id per prayer, per alert
  /// kind, per day of the horizon. Names outside [prayerOrder] (sunrise) get
  /// no id at all, which is how they're kept out of the alert schedule.
  ///
  /// Deterministic on purpose: the main isolate and the background-service
  /// isolate both schedule the same horizon, and identical ids mean the later
  /// writer replaces the earlier one instead of leaving two alarms racing to
  /// announce the same prayer.
  static int? _prayerAlertId(int base, int dayOffset, String prayerName) {
    final index = prayerOrder.indexOf(prayerName);
    if (index < 0) return null;
    return base + dayOffset * 10 + index;
  }

  static int? adhanId(int dayOffset, String prayerName) =>
      _prayerAlertId(_adhanIdBase, dayOffset, prayerName);

  static int? preAdhanId(int dayOffset, String prayerName) =>
      _prayerAlertId(_preAdhanIdBase, dayOffset, prayerName);

  static int? iqamaId(int dayOffset, String prayerName) =>
      _prayerAlertId(_iqamaIdBase, dayOffset, prayerName);

  /// Ids 100–124 — what builds up to 1.6.x scheduled for a single day.
  /// Nothing writes them any more, but a phone upgrading to this version can
  /// still have them pending, so they're cancelled alongside the horizon.
  static const legacyPrayerAlertIds = <int>{
    100,
    101,
    102,
    103,
    104,
    110,
    111,
    112,
    113,
    114,
    120,
    121,
    122,
    123,
    124,
  };

  // ── أذكار مرتبطة بوقت الصلاة على مدى عدة أيام ──
  // After-Fajr and after-Asr adhkar can't repeat on a fixed clock the way the
  // morning/evening/sleep reminders do: Fajr moves through the year, so a
  // hardcoded time drifts onto the wrong side of the prayer. They are
  // therefore one-shot per day across the same horizon as the prayer alerts,
  // which needs a distinct id per reminder per day.

  static const _afterFajrAdhkarIdBase = 4000;
  static const _afterAsrAdhkarIdBase = 4100;

  static int afterFajrAdhkarId(int dayOffset) =>
      _afterFajrAdhkarIdBase + dayOffset;

  static int afterAsrAdhkarId(int dayOffset) =>
      _afterAsrAdhkarIdBase + dayOffset;
}

/// How many days of prayer alerts are kept scheduled ahead of time.
///
/// The point is that alarms exist *before* the app is next opened: a
/// single-day schedule — the previous behaviour — left nothing pending the
/// moment the day rolled over, so a phone that went a day without Takwa being
/// launched stopped announcing prayers entirely, no matter what the user had
/// configured. 7 days is well inside Android's per-app alarm budget.
const int kPrayerScheduleDays = 7;

// ─────────────────────────────────────────
//  NOTIFICATION CHANNELS (Android)
// ─────────────────────────────────────────
class NotifChannels {
  // Deliberately still hardcoded to Arabic, unlike the scheduled
  // notification title/body text below (see NotificationsManager /
  // AdhkarNotificationService) — these channel names/descriptions are
  // baked into an Android notification channel at creation time via
  // initialize(), and Android ignores a channel's display name being
  // changed after that: a locale-aware rewrite here would need a
  // channel-ID bump to actually take effect, which would need its own
  // migration so users don't lose their per-channel sound/vibration
  // overrides. Scoped out of this pass; see the i18n audit for the
  // full reasoning.
  static final AppLocalizations _l10n = lookupAppLocalizations(
    const Locale('ar'),
  );

  /// قناة تنبيه وقت الصلاة — أعلى أولوية مع نغمة الإشعار القياسية (بدون تشغيل صوت الأذان)
  static final AndroidNotificationChannel prayerSound =
      AndroidNotificationChannel(
        'prayer_time_alert',
        _l10n.notifChannelPrayerSoundName,
        description: _l10n.notifChannelPrayerSoundDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFFC8A96E),
      );

  /// قناة الأذان — اهتزاز فقط
  static final AndroidNotificationChannel prayerVibrate =
      AndroidNotificationChannel(
        'prayer_adhan_vibrate',
        _l10n.notifChannelPrayerVibrateName,
        description: _l10n.notifChannelPrayerVibrateDesc,
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFFC8A96E),
      );

  /// قناة الأذان — صامت
  static final AndroidNotificationChannel prayerSilent =
      AndroidNotificationChannel(
        'prayer_adhan_silent',
        _l10n.notifChannelPrayerSilentName,
        description: _l10n.notifChannelPrayerSilentDesc,
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        enableLights: true,
        ledColor: const Color(0xFFC8A96E),
      );

  /// تنبيهات قبل الأذان والإقامة
  static final AndroidNotificationChannel alert = AndroidNotificationChannel(
    'prayer_alerts',
    _l10n.notifChannelAlertName,
    description: _l10n.notifChannelAlertDesc,
    importance: Importance.high,
    sound: const RawResourceAndroidNotificationSound('notification'),
    playSound: true,
    enableVibration: true,
  );

  /// قناة المحاسبة
  static final AndroidNotificationChannel muhasaba = AndroidNotificationChannel(
    'muhasaba',
    _l10n.notifChannelMuhasabaName,
    description: _l10n.notifChannelMuhasabaDesc,
    importance: Importance.defaultImportance,
    enableVibration: false,
  );

  /// قناة الأذكار
  static final AndroidNotificationChannel adhkar = AndroidNotificationChannel(
    'adhkar_channel',
    _l10n.notifChannelAdhkarName,
    description: _l10n.notifChannelAdhkarDesc,
    importance: Importance.defaultImportance,
    playSound: false,
    enableVibration: false,
  );

  /// One channel per litanies category that can be reminded about, so the
  /// system notification settings let a user silence أذكار النوم without
  /// silencing أذكار الصباح. The ids must match the `adhkar_<category>` ids
  /// AdhkarNotificationService posts to: Android drops a notification whose
  /// channel was never created, and it does so silently — which is how the
  /// adhkar reminders could be scheduled correctly and still never appear.
  static List<AndroidNotificationChannel> get adhkarCategories => [
    AndroidNotificationChannel(
      'adhkar_morning',
      _l10n.notifAdhkarMorningChannelName,
      description: _l10n.notifAdhkarChannelDesc,
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    ),
    AndroidNotificationChannel(
      'adhkar_evening',
      _l10n.notifAdhkarEveningChannelName,
      description: _l10n.notifAdhkarChannelDesc,
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    ),
    AndroidNotificationChannel(
      'adhkar_sleep',
      _l10n.notifAdhkarSleepChannelName,
      description: _l10n.notifAdhkarChannelDesc,
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    ),
  ];

  /// قناة الأدعية
  static final AndroidNotificationChannel duas = AndroidNotificationChannel(
    'duas_channel',
    _l10n.notifChannelDuasName,
    description: _l10n.notifChannelDuasDesc,
    importance: Importance.defaultImportance,
    playSound: false,
    enableVibration: false,
  );

  /// قناة الإنجازات
  static final AndroidNotificationChannel achievement =
      AndroidNotificationChannel(
        'achievement_channel',
        _l10n.notifChannelAchievementName,
        description: _l10n.notifChannelAchievementDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  /// قناة التذكيرات الخاصة
  static final AndroidNotificationChannel reminders =
      AndroidNotificationChannel(
        'special_reminders',
        _l10n.notifChannelRemindersName,
        description: _l10n.notifChannelRemindersDesc,
        importance: Importance.defaultImportance,
        enableVibration: false,
      );

  /// قناة رمضان
  static final AndroidNotificationChannel ramadan = AndroidNotificationChannel(
    'ramadan_channel',
    _l10n.notifChannelRamadanName,
    description: _l10n.notifChannelRamadanDesc,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// قناة تحديثات التطبيق — إشعار عند توفر إصدار جديد. See
  /// docs/specs/release-push-notifications.md.
  static final AndroidNotificationChannel appUpdates =
      AndroidNotificationChannel(
        'app_updates_channel',
        _l10n.notifChannelAppUpdatesName,
        description: _l10n.notifChannelAppUpdatesDesc,
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: false,
      );

  /// قناة منبه الاستيقاظ
  static final AndroidNotificationChannel wakeUpAlarm =
      AndroidNotificationChannel(
        'wakeup_alarm_channel',
        _l10n.notifChannelWakeUpAlarmName,
        description: _l10n.notifChannelWakeUpAlarmDesc,
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('adhan'),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFFC8A96E),
      );

  static List<AndroidNotificationChannel> get all => [
    prayerSound,
    prayerVibrate,
    prayerSilent,
    alert,
    muhasaba,
    adhkar,
    ...adhkarCategories,
    duas,
    achievement,
    reminders,
    ramadan,
    appUpdates,
    wakeUpAlarm,
  ];
}

// ─────────────────────────────────────────
//  PRAYER TIME INFO MODEL
// ─────────────────────────────────────────
class PrayerTimeInfo {
  final String name;
  final String nameAr;
  final String emoji;
  final DateTime time;
  final int notifId;
  const PrayerTimeInfo({
    required this.name,
    required this.nameAr,
    required this.emoji,
    required this.time,
    required this.notifId,
  });
}

class NotificationsService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── تهيئة الخدمة ──
  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotifTap,
      onDidReceiveBackgroundNotificationResponse: _onNotifTap,
    );

    // إنشاء القنوات على Android
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      try {
        await androidPlugin?.deleteNotificationChannel('prayer_adhan_sound');
      } catch (_) {}
      for (final channel in NotifChannels.all) {
        await androidPlugin?.createNotificationChannel(channel);
      }
    }

    _initialized = true;
  }

  /// فحص إذا تم فتح التطبيق عبر النقر على إشعار عند الإقلاع
  static Future<NotificationResponse?> getLaunchNotificationResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      return details.notificationResponse;
    }
    return null;
  }

  // ── طلب الأذون ──
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
      // Android 12+ يحتاج إذن التنبيه الدقيق
      final exact = await Permission.scheduleExactAlarm.request();
      // Android 14+ ينزع USE_FULL_SCREEN_INTENT تلقائياً من التطبيقات التي
      // لا يصنّفها متجر Play كتطبيقات منبّه — يُطلب هنا ضمن نفس مسار
      // الأذونات حتى لا يبقى الإذن ناقصاً بصمت (R8). لا يؤثر على القيمة
      // المُعادة: `checkPermissions()` يبقى مقياس "هل يمكن جدولة الإشعار
      // أصلاً".
      await ensureFullScreenIntentPermission();
      return exact.isGranted;
    }
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return true;
  }

  static Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      if (!await Permission.notification.isGranted) return false;
      // منح الإشعار على مستوى التطبيق لا يعني أنها مفعّلة فعلاً: يمكن
      // للمستخدم (أو نظام تصنيف القنوات) إسكات إشعارات التطبيق من إعدادات
      // النظام، فيبقى `Permission.notification` ممنوحاً بينما لا يظهر أي
      // إشعار — وهذا بالضبط عرَض "لا شيء يحدث حتى أفتح تقوى". الفحص
      // الفعلي أدق من فحص الإذن وحده.
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      if (enabled == false) return false;
      return await Permission.scheduleExactAlarm.isGranted;
    }
    return await Permission.notification.isGranted;
  }

  /// Android 14+ (API 34) ينزع `USE_FULL_SCREEN_INTENT` عن التطبيقات التي
  /// لا يصنّفها متجر Play كتطبيق منبّه أو اتصال. حينها يظهر إشعار وقت
  /// الصلاة عادياً (بانر علوي) لكن النظام يتجاهل علم `fullScreenIntent`،
  /// فلا تُفتح شاشة الأذان تلقائياً فوق التطبيقات ولا فوق شاشة القفل —
  /// وهو سبب مباشر لشكوى "لا تظهر الشاشة إلا إذا فتحت التطبيق".
  ///
  /// لا توفّر حزمة flutter_local_notifications 18 استعلاماً عن حالة هذا
  /// الإذن، بل الطلب فقط — لذلك هذا "تأكيد" لا "فحص": إن كان الإذن ممنوحاً
  /// (أو كان الإصدار أقدم من 14) تُرجع الدالة true فوراً دون فتح أي شاشة،
  /// وتفتح صفحة إعدادات النظام فقط عندما يكون ناقصاً فعلاً.
  static Future<bool> ensureFullScreenIntentPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestFullScreenIntentPermission();
      // `null` تعني أن الحزمة لا تدعم الاستدعاء (إصدار نظام أقدم) — نعتبره
      // ممنوحاً بدل إظهار تحذير لا يمكن للمستخدم إصلاحه.
      return granted ?? true;
    } catch (e) {
      debugPrint('NotificationsService: FSI permission request failed: $e');
      return true;
    }
  }

  /// هل النظام معفى من تحسين البطارية (Doze / App Standby)؟ المنبهات الدقيقة
  /// تُطلق أثناء Doze بفضل `exactAllowWhileIdle`، لكن الإشعارات عالية
  /// الأولوية وشاشة الأذان على هاتف نائم تتأخران أو تُحجَبان حين يقيّد
  /// النظام التطبيق — وهي الحالة الثالثة التي طلبها المستخدم ("الهاتف نائم").
  static Future<bool> isBatteryOptimizationExempt() async {
    if (!Platform.isAndroid) return true;
    return Permission.ignoreBatteryOptimizations.isGranted;
  }

  static Future<bool> requestBackgroundPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.ignoreBatteryOptimizations
          .request()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => PermissionStatus.denied,
          );
      return status.isGranted;
    }
    return true;
  }

  /// Cancels every prayer alert this service can have scheduled: the legacy
  /// single-day ids (100–124) *and* the whole [days]-day horizon.
  ///
  /// Both are needed. The legacy ids because an upgrade leaves them pending;
  /// the horizon because it rolls — a run that scheduled 7 days starting
  /// yesterday leaves a 7th day that this run won't overwrite, and it would
  /// fire an alarm computed from stale times.
  static Future<void> cancelPrayerNotifications({
    int days = kPrayerScheduleDays,
  }) async {
    final targets = <int>{...NotifIds.legacyPrayerAlertIds};
    for (int dayOffset = 0; dayOffset < days; dayOffset++) {
      for (final name in NotifIds.prayerOrder) {
        // Non-null: prayerOrder only ever holds ids these helpers know.
        targets.add(NotifIds.adhanId(dayOffset, name)!);
        targets.add(NotifIds.preAdhanId(dayOffset, name)!);
        targets.add(NotifIds.iqamaId(dayOffset, name)!);
      }
    }
    for (final id in targets) {
      await _plugin.cancel(id);
    }
  }

  /// Schedules the rolling prayer-alert horizon — [days] days starting today.
  ///
  /// This computes each day's times itself rather than taking one day's list
  /// from the caller, because that is the entire point: the alarms have to be
  /// in the OS queue before the user next opens the app.
  ///
  /// [onlyPrayers] restricts the horizon to a set of internal prayer ids
  /// ('fajr'…'isha'); the background service uses it to honour the
  /// silent-mode allow-list. Passing an *empty* set is treated as "suppress
  /// everything" and returns without touching the existing schedule — a
  /// partial or empty filter must never be able to wipe alarms that are the
  /// user's only remaining way of hearing about a prayer.
  static Future<void> scheduleUpcomingPrayerNotifications({
    required double latitude,
    required double longitude,
    required String madhab,
    required String method,
    required AppLocalizations l10n,
    String? highLatitudeRule,
    String? timezone,
    int days = kPrayerScheduleDays,
    int fajrOffset = 0,
    int sunriseOffset = 0,
    int dhuhrOffset = 0,
    int asrOffset = 0,
    int maghribOffset = 0,
    int ishaOffset = 0,
    bool preAdhanEnabled = true,
    bool iqamaEnabled = true,
    String adhanMode = 'sound',
    bool adhanScreenEnabled = true,
    bool adhanAlarmEnabled = true,
    Set<String>? onlyPrayers,
  }) async {
    if (onlyPrayers != null && onlyPrayers.isEmpty) {
      debugPrint(
        '[NotificationsService] horizon not scheduled: empty prayer filter',
      );
      return;
    }

    // iOS caps an app at 64 pending local notifications, and the oldest beyond
    // that are dropped silently. A 7-day horizon is up to 105 entries, which
    // would leave the tail unannounced; 3 days (45 entries) leaves room for
    // the other alarms the same scheduleAll() writes — the adhkar reminders
    // (up to 3 repeating + 4 anchored) and the daily dua.
    final effectiveDays = Platform.isIOS ? min(days, 3) : days;

    await cancelPrayerNotifications(days: effectiveDays);

    final today = DateTime.now();
    for (int dayOffset = 0; dayOffset < effectiveDays; dayOffset++) {
      final date = DateTime(today.year, today.month, today.day + dayOffset);
      List<PrayerTimeInfo> prayers;
      try {
        prayers = await PrayerTimesService.calculate(
          latitude: latitude,
          longitude: longitude,
          madhab: madhab,
          method: method,
          highLatitudeRule: highLatitudeRule,
          fajrOffset: fajrOffset,
          sunriseOffset: sunriseOffset,
          dhuhrOffset: dhuhrOffset,
          asrOffset: asrOffset,
          maghribOffset: maghribOffset,
          ishaOffset: ishaOffset,
          date: date,
          timezone: timezone,
        );
      } catch (e) {
        // One bad day (a malformed timezone rule, a date edge case) must not
        // cost the user the other six.
        debugPrint(
          '[NotificationsService] horizon day $dayOffset calculation failed: $e',
        );
        continue;
      }

      if (onlyPrayers != null) {
        prayers = prayers.where((p) => onlyPrayers.contains(p.name)).toList();
      }

      await schedulePrayerNotifications(
        prayers: prayers,
        l10n: l10n,
        dayOffset: dayOffset,
        preAdhanEnabled: preAdhanEnabled,
        iqamaEnabled: iqamaEnabled,
        adhanMode: adhanMode,
        adhanScreenEnabled: adhanScreenEnabled,
        adhanAlarmEnabled: adhanAlarmEnabled,
      );
    }
  }

  // ── جدولة إشعارات الصلاة ليوم واحد ──
  /// Schedules one day's alerts — pre-adhan, adhan, and iqama — using the ids
  /// for [dayOffset] days from today (0 = today).
  ///
  /// Only ever adds to the pending queue; cancelling is
  /// [scheduleUpcomingPrayerNotifications]'s job so a 7-day pass doesn't
  /// cancel its own first six days. Times already in the past are skipped by
  /// [_scheduleExact], which is also what keeps re-running for today safe.
  static Future<void> schedulePrayerNotifications({
    required List<PrayerTimeInfo> prayers,
    required AppLocalizations l10n,
    int dayOffset = 0,
    bool preAdhanEnabled = true,
    bool iqamaEnabled = true,
    String adhanMode = 'sound',
    bool adhanScreenEnabled = true,
    bool adhanAlarmEnabled = true,
  }) async {
    final iqamaOffsets = {
      'fajr': 20,
      'dhuhr': 15,
      'asr': 15,
      'maghrib': 5,
      'isha': 15,
    };

    final now = DateTime.now();

    for (final prayer in prayers) {
      // null for anything outside NotifIds.prayerOrder — i.e. sunrise, which
      // gets no alerts of any kind.
      final adhanId = NotifIds.adhanId(dayOffset, prayer.name);
      if (adhanId == null) continue;

      final prayerName = prayerLocalizedName(l10n, prayer.name);

      // 1. تنبيه قبل الأذان بـ 15 دقيقة
      if (preAdhanEnabled) {
        final preTime = prayer.time.subtract(const Duration(minutes: 15));
        if (preTime.isAfter(now)) {
          await _scheduleExact(
            id: NotifIds.preAdhanId(dayOffset, prayer.name)!,
            title: l10n.notifPreAdhanTitle(prayerName),
            body: l10n.notifPreAdhanBody(prayerName),
            scheduledTime: preTime,
            channelId: NotifChannels.alert.id,
            payload: 'pre_prayer:${prayer.name}',
          );
        }
      }

      // 2. إشعار دخول وقت الصلاة — صامت دائماً (بدون أي صوت من الإشعار نفسه):
      // صوت الأذان الفعلي (بحسب adhanMode) لا يتم تشغيله إلا حصراً من داخل
      // شاشة الأذان (AdhanAudioPlayer)، وليس من قناة الإشعار — هذا يمنع
      // ازدواجية الصوت (نغمة إشعار + صوت أذان معاً) ويجعل الإشعار مجرد
      // وسيلة موثوقة لفتح شاشة الأذان تلقائياً (fullScreenIntent) حتى لو
      // كان التطبيق مغلقاً تماماً. الاهتزاز وحده لا يزال يتبع adhanMode.
      if (prayer.time.isAfter(now)) {
        final selectedChannel = adhanMode == 'vibrate'
            ? NotifChannels.prayerVibrate
            : NotifChannels.prayerSilent;

        await _scheduleExact(
          id: adhanId,
          title: '${prayer.emoji} ${l10n.notifAdhanTitle(prayerName)}',
          // The Takbir/call-to-prayer phrase itself stays as-is in both
          // languages (transliterated for English) — it's the Adhan's own
          // wording, not app chrome, so it isn't a straight translation.
          body: l10n.notifAdhanBody,
          scheduledTime: prayer.time,
          channelId: selectedChannel.id,
          sound:
              null, // لا نغمة أذان في الإشعار، الصوت يتم تشغيله حصراً في شاشة الأذان
          payload: 'prayer:${prayer.name}',
          // مرتبط بإعداد "شاشة الأذان" (adhanScreenEnabled) وليس بنمط الصوت
          // (adhanMode) — سابقاً كان مرتبطاً بـ `adhanMode != 'silent'`، مما
          // كان يمنع فتح الشاشة تلقائياً كلياً عندما يختار المستخدم النمط
          // الصامت، رغم أنه قد يريد رؤية شاشة الأذان بدون صوت. fullScreenIntent
          // هو ما يجعل أندرويد يفتح التطبيق تلقائياً على شاشة الأذان حتى مع
          // إغلاق التطبيق أو قفل الشاشة (ضمن حدود النظام والأذونات الممنوحة).
          // adhanAlarmEnabled gates the full-screen-intent channel entirely —
          // when false, the notification is still posted (so the user sees a
          // heads-up at prayer time) but without the fullScreenIntent flag,
          // preventing the alarm-style screen takeover.
          fullScreenIntent: adhanScreenEnabled && adhanAlarmEnabled,
        );
      }

      // 3. تنبيه الإقامة
      if (iqamaEnabled) {
        final offset = iqamaOffsets[prayer.name] ?? 15;
        final iqamaTime = prayer.time.add(Duration(minutes: offset));
        if (iqamaTime.isAfter(now)) {
          await _scheduleExact(
            id: NotifIds.iqamaId(dayOffset, prayer.name)!,
            title: l10n.notifIqamaTitle(prayerName),
            body: l10n.notifIqamaBody(prayerName),
            scheduledTime: iqamaTime,
            channelId: NotifChannels.alert.id,
            payload: 'iqama:${prayer.name}',
          );
        }
      }
    }
  }

  // ── جدولة محاسبة مسائية يومية ──
  static Future<void> scheduleEveningMuhasaba({
    required TimeOfDay time,
    required AppLocalizations l10n,
  }) async {
    await _plugin.cancel(NotifIds.eveningMuhasaba);

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

    final eveningMessages = _eveningMessages(l10n);
    final msg = eveningMessages[now.weekday % eveningMessages.length];

    await _safeZonedSchedule(
      NotifIds.eveningMuhasaba,
      '📝 ${l10n.notifMuhasabaTitle}',
      msg,
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotifChannels.muhasaba.id,
          NotifChannels.muhasaba.name,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(msg),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'muhasaba:evening',
    );
  }

  // ── جدولة دعاء اليوم ──
  //
  // One reminder a day, at the time the user chose, drawing from the category
  // that fits that hour: a 6 AM ping brings أدعية الصباح and a 10 PM one
  // brings أدعية النوم. It used to post three fixed clocks (09:00, 12:00 and
  // 21:00) regardless of the chosen time, and nothing cancelled them when
  // `dailyDuasOn` was switched off — so the alarms stayed queued.
  static Future<void> scheduleDailyDuas({
    required UserPreferences prefs,
    required AppLocalizations l10n,
  }) async {
    await cancelDailyDuas();
    final time = prefs.duaReminderTime;
    final now = DateTime.now();
    var fireAt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!fireAt.isAfter(now)) fireAt = fireAt.add(const Duration(days: 1));

    final dua = duaForHour(time.hour, fireAt);
    if (dua == null) return;

    await _scheduleDailyAt(
      id: NotifIds.dailyDua,
      title: '${dua.emoji} ${l10n.notifDuaTodayTitle}',
      body: _truncate(dua.arabic, 150),
      time: time,
      channelId: NotifChannels.duas.id,
      payload: 'dua:${dua.id}',
    );
  }

  static Future<void> cancelDailyDuas() async {
    for (final id in [
      NotifIds.dailyDua,
      NotifIds.dailyDuaMorning,
      NotifIds.dailyDuaEvening,
      NotifIds.distressDua,
    ]) {
      await _plugin.cancel(id);
    }
  }

  // ── جدولة تذكيرات الجمعة والصيام ──
  static Future<void> scheduleSpecialReminders({
    required bool fridayReminders,
    required bool fastingReminders,
    required AppLocalizations l10n,
  }) async {
    final ids = [
      NotifIds.fridayKahf,
      NotifIds.fridaySalawat,
      NotifIds.fastingMonday,
      NotifIds.fastingThursday,
    ];
    for (final id in ids) {
      await _plugin.cancel(id);
    }

    if (fridayReminders) {
      await _scheduleWeekly(
        id: NotifIds.fridayKahf,
        title: '📖 ${l10n.notifFridayKahfTitle}',
        body: l10n.notifFridayKahfBody,
        day: DateTime.friday,
        hour: 9,
        minute: 0,
        payload: 'reminder:kahf',
      );
      await _scheduleWeekly(
        id: NotifIds.fridaySalawat,
        title: '💛 ${l10n.notifFridaySalawatTitle}',
        body: l10n.notifFridaySalawatBody,
        day: DateTime.friday,
        hour: 13,
        minute: 0,
        payload: 'reminder:salawat',
      );
    }

    if (fastingReminders) {
      await _scheduleWeekly(
        id: NotifIds.fastingMonday,
        title: '🥘 ${l10n.notifFastingMondayTitle}',
        body: l10n.notifFastingMondayBody,
        day: DateTime.sunday,
        hour: 21,
        minute: 0,
        payload: 'reminder:fasting_monday',
      );
      await _scheduleWeekly(
        id: NotifIds.fastingThursday,
        title: '🥘 ${l10n.notifFastingThursdayTitle}',
        body: l10n.notifFastingThursdayBody,
        day: DateTime.wednesday,
        hour: 21,
        minute: 0,
        payload: 'reminder:fasting_thursday',
      );

      // الأيام البيض
      await _scheduleWhiteDays(l10n);
    }
  }

  // ── جدولة رمضان (السحور والإفطار) ──
  // Also not called from anywhere yet (no Ramadan-mode screen wires it
  // up today) — localized anyway since it was a small addition while
  // already in this file, so it's ready the day something does call it.
  static Future<void> scheduleRamadanNotifications({
    required DateTime suhoorTime,
    required DateTime iftarTime,
    required AppLocalizations l10n,
  }) async {
    await _plugin.cancel(NotifIds.ramadanSuhoor);
    await _plugin.cancel(NotifIds.ramadanIftar);

    final now = DateTime.now();
    final suhoorAlert = suhoorTime.subtract(const Duration(minutes: 30));
    if (suhoorAlert.isAfter(now)) {
      await _scheduleExact(
        id: NotifIds.ramadanSuhoor,
        title: '🌙 ${l10n.notifSuhoorTitle}',
        body: l10n.notifSuhoorBody,
        scheduledTime: suhoorAlert,
        channelId: NotifChannels.ramadan.id,
        payload: 'ramadan:suhoor',
      );
    }
    if (iftarTime.isAfter(now)) {
      await _scheduleExact(
        id: NotifIds.ramadanIftar,
        title: '🌅 ${l10n.notifIftarTitle}',
        body: l10n.notifIftarBody,
        scheduledTime: iftarTime,
        channelId: NotifChannels.ramadan.id,
        sound: 'adhan',
        payload: 'ramadan:iftar',
      );
    }
  }

  // ── المنبه / الاستيقاظ ──
  static Future<void> scheduleWakeUpAlarm({
    required TimeOfDay time,
    required AppLocalizations l10n,
  }) async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(NotifIds.wakeUpAlarm + i);
    }

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      var scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      ).add(Duration(days: i));

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }

      await _scheduleExact(
        id: NotifIds.wakeUpAlarm + i,
        title: '🌙 ${l10n.notifWakeUpTitle}',
        body: l10n.notifWakeUpBody,
        scheduledTime: scheduled,
        channelId: NotifChannels.wakeUpAlarm.id,
        sound: 'adhan',
        payload: 'wakeup:fajr',
        fullScreenIntent: true,
      );
    }
  }

  static Future<void> scheduleSnooze({
    required int minutes,
    required AppLocalizations l10n,
  }) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    await _scheduleExact(
      id: NotifIds.wakeUpAlarm,
      title: '🌙 ${l10n.notifWakeUpSnoozeTitle}',
      body: l10n.notifWakeUpBody,
      scheduledTime: snoozeTime,
      channelId: NotifChannels.wakeUpAlarm.id,
      sound: 'adhan',
      payload: 'wakeup:fajr',
      fullScreenIntent: true,
    );
  }

  // ── إشعار إنجاز فوري ──
  static Future<void> showAchievementNotif({
    required String title,
    required String body,
    required String emoji,
    required int points,
    required AppLocalizations l10n,
  }) async {
    await _plugin.show(
      NotifIds.achievement,
      '$emoji ${l10n.notifAchievementNewPrefix(title)}',
      '$body — ${l10n.notifAchievementPointsSuffix(points)}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotifChannels.achievement.id,
          NotifChannels.achievement.name,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            '$body\n✨ ${l10n.notifAchievementPointsShort(points)}',
          ),
          color: const Color(0xFFC8A96E),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      payload: 'achievement:new',
    );
  }

  // ── عرض إشعار فوري ──
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required AndroidNotificationChannel channel,
    String? bigText,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(bigText ?? body),
          color: const Color(0xFFC8A96E),
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
      payload: payload,
    );
  }

  // ── إلغاء الإشعارات ──
  static Future<void> cancel(int id) => _plugin.cancel(id);
  static Future<void> cancelAll() => _plugin.cancelAll();
  static Future<List<PendingNotificationRequest>> getPending() =>
      _plugin.pendingNotificationRequests();

  // ─────────────────── PRIVATE ───────────────────

  /// جدولة آمنة تدعم التراجع التلقائي إلى inexactAllowWhileIdle في حال عدم توفر
  /// إذن التنبيه الدقيق (SCHEDULE_EXACT_ALARM) على أندرويد 12+، وتمنع انهيار التطبيق.
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
        debugPrint(
          '[NotificationsService] exact alarms not permitted, falling back to inexact for id $id',
        );
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
        } catch (fallbackErr) {
          debugPrint(
            '[NotificationsService] fallback scheduling failed for id $id: $fallbackErr',
          );
        }
      } else {
        debugPrint(
          '[NotificationsService] PlatformException scheduling id $id: $e',
        );
      }
    } catch (e, st) {
      debugPrint(
        '[NotificationsService] failed to schedule notification id $id: $e\n$st',
      );
    }
  }

  static Future<void> _scheduleExact({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    String? sound,
    String? payload,
    bool fullScreenIntent = false,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final isSilent = channelId == NotifChannels.prayerSilent.id;
    final isVibrateOnly = channelId == NotifChannels.prayerVibrate.id;
    final shouldPlaySound = !isSilent && !isVibrateOnly;

    await _safeZonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: Importance.max,
          priority: Priority.high,
          sound: sound != null
              ? RawResourceAndroidNotificationSound(sound)
              : null,
          playSound: shouldPlaySound,
          enableVibration: !isSilent,
          fullScreenIntent: fullScreenIntent,
          category: fullScreenIntent ? AndroidNotificationCategory.alarm : null,
          audioAttributesUsage: fullScreenIntent
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(body),
          color: const Color(0xFFC8A96E),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: shouldPlaySound,
          sound: sound != null ? '$sound.aiff' : null,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> _scheduleDailyAt({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String channelId,
    String? payload,
    String? sound,
    bool fullScreenIntent = false,
  }) async {
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

    await _safeZonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: sound != null
              ? Importance.max
              : Importance.defaultImportance,
          priority: sound != null ? Priority.high : Priority.defaultPriority,
          sound: sound != null
              ? RawResourceAndroidNotificationSound(sound)
              : null,
          playSound: sound != null,
          enableVibration: true,
          fullScreenIntent: fullScreenIntent,
          category: fullScreenIntent ? AndroidNotificationCategory.alarm : null,
          audioAttributesUsage: fullScreenIntent
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(body),
          color: const Color(0xFFC8A96E),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: sound != null,
          sound: sound != null ? 'adhan.aiff' : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  static Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int day,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (date.weekday != day || date.isBefore(now)) {
      date = date.add(const Duration(days: 1));
    }

    await _safeZonedSchedule(
      id,
      title,
      body,
      date,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotifChannels.reminders.id,
          NotifChannels.reminders.name,
          importance: Importance.defaultImportance,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  static Future<void> _scheduleWhiteDays(AppLocalizations l10n) async {
    for (int monthOffset = 0; monthOffset <= 1; monthOffset++) {
      final h = HijriCalendar.now();
      if (monthOffset > 0) {
        h.hMonth++;
        if (h.hMonth > 12) {
          h.hMonth = 1;
          h.hYear++;
        }
      }
      for (int day in [12, 13, 14]) {
        h.hDay = day;
        final solar = h.hijriToGregorian(h.hYear, h.hMonth, h.hDay);
        final notify = DateTime(solar.year, solar.month, solar.day, 20, 30);
        if (notify.isAfter(DateTime.now())) {
          await _scheduleExact(
            id: NotifIds.fastingWhiteDays + (monthOffset * 3) + (day - 12),
            title: '⚪ ${l10n.notifWhiteDaysTitle}',
            // getLongMonthName() already follows HijriCalendar.language,
            // which locale_provider.dart keeps in sync with the app locale.
            body: l10n.notifWhiteDaysBody(day + 1, h.getLongMonthName()),
            scheduledTime: notify,
            channelId: NotifChannels.reminders.id,
            payload: 'reminder:white_days',
          );
        }
      }
    }
  }

  // ── helpers ──
  /// The dua categories that fit a wall-clock hour: أدعية الصباح in the
  /// morning, الاستغفار والرزق around midday, أدعية المساء from Asr onwards,
  /// أدعية النوم at bedtime, and جوامع الدعاء for the last part of the night.
  static List<DuaCategory> duaCategoriesForHour(int hour) {
    if (hour >= 3 && hour < 11) {
      return [DuaCategory.morning, DuaCategory.guidance];
    }
    if (hour >= 11 && hour < 16) {
      return [DuaCategory.forgiveness, DuaCategory.rizq];
    }
    if (hour >= 16 && hour < 20) {
      return [DuaCategory.evening, DuaCategory.distress];
    }
    if (hour >= 20) return [DuaCategory.sleep, DuaCategory.general];
    // 0–2، آخر الليل: مناجاة عامة ودعاء الكرب.
    return [DuaCategory.general, DuaCategory.distress];
  }

  /// Rotated by day rather than shuffled, so re-running a schedule for the
  /// same day cannot change the text under an alarm that is already queued.
  static DuaItem? duaForHour(int hour, DateTime date) {
    final pool = [
      for (final cat in duaCategoriesForHour(hour)) ...?kDuasData[cat],
    ];
    if (pool.isEmpty) return null;
    return pool[date.dayOfYear % pool.length];
  }

  /// Shortened at a word boundary — the plain `substring` this replaces cut
  /// Arabic words in half mid-sentence.
  static String _truncate(String text, int maxLen) {
    final clean = text.replaceAll('\n', ' ').trim();
    if (clean.length <= maxLen) return clean;
    var cut = clean.substring(0, maxLen);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace > maxLen * 3 ~/ 4) cut = cut.substring(0, lastSpace);
    return '$cut…';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'ص' : 'م';
    return '$h:$m $ap';
  }

  static void _onNotifTap(NotificationResponse response) {
    NotificationRouter.route(response.payload ?? '');
  }

  static List<String> _eveningMessages(AppLocalizations l10n) => [
    l10n.notifMuhasabaMsg1,
    l10n.notifMuhasabaMsg2,
    l10n.notifMuhasabaMsg3,
    l10n.notifMuhasabaMsg4,
    l10n.notifMuhasabaMsg5,
    l10n.notifMuhasabaMsg6,
    l10n.notifMuhasabaMsg7,
  ];
}

class PrayerTimesService {
  static Future<List<PrayerTimeInfo>> calculate({
    required double latitude,
    required double longitude,
    required String madhab,
    required String method,
    String? highLatitudeRule,
    int fajrOffset = 0,
    int sunriseOffset = 0,
    int dhuhrOffset = 0,
    int asrOffset = 0,
    int maghribOffset = 0,
    int ishaOffset = 0,
    DateTime? date,
    String? timezone,
  }) async {
    TimezoneResolver.ensureInitialized();
    if (timezone != null && timezone.isNotEmpty) {
      TimezoneResolver.setLocalTimezone(timezone);
    }

    final localNow = tz.TZDateTime.now(tz.local);
    final targetDate = date != null
        ? tz.TZDateTime(tz.local, date.year, date.month, date.day)
        : localNow;

    final coords = adhan.Coordinates(latitude, longitude);
    final params = _calcParams(
      method,
      madhab,
      highLatitudeRule: highLatitudeRule,
      fajrOffset: fajrOffset,
      sunriseOffset: sunriseOffset,
      dhuhrOffset: dhuhrOffset,
      asrOffset: asrOffset,
      maghribOffset: maghribOffset,
      ishaOffset: ishaOffset,
    );
    final dc = adhan.DateComponents(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final times = adhan.PrayerTimes(coords, dc, params);

    DateTime toLocal(DateTime utcTime) {
      return tz.TZDateTime.from(utcTime, tz.local);
    }

    return [
      PrayerTimeInfo(
        name: 'fajr',
        nameAr: 'الفجر',
        emoji: '🌙',
        time: toLocal(times.fajr),
        notifId: NotifIds.fajr,
      ),
      PrayerTimeInfo(
        name: 'sunrise',
        nameAr: 'الشروق',
        emoji: '🌅',
        time: toLocal(times.sunrise),
        notifId: -1, // لا يوجد إشعار للشروق حالياً
      ),
      PrayerTimeInfo(
        name: 'dhuhr',
        nameAr: 'الظهر',
        emoji: '☀️',
        time: toLocal(times.dhuhr),
        notifId: NotifIds.dhuhr,
      ),
      PrayerTimeInfo(
        name: 'asr',
        nameAr: 'العصر',
        emoji: '🌤',
        time: toLocal(times.asr),
        notifId: NotifIds.asr,
      ),
      PrayerTimeInfo(
        name: 'maghrib',
        nameAr: 'المغرب',
        emoji: '🌆',
        time: toLocal(times.maghrib),
        notifId: NotifIds.maghrib,
      ),
      PrayerTimeInfo(
        name: 'isha',
        nameAr: 'العشاء',
        emoji: '🌃',
        time: toLocal(times.isha),
        notifId: NotifIds.isha,
      ),
    ];
  }

  static Future<Position?> getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }
    if (perm == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }

  static PrayerTimeInfo? nextPrayer(List<PrayerTimeInfo> prayers) {
    final now = DateTime.now();
    for (final p in prayers) {
      if (p.time.isAfter(now)) return p;
    }
    return null;
  }

  static Duration? timeUntilNext(List<PrayerTimeInfo> prayers) =>
      nextPrayer(prayers)?.time.difference(DateTime.now());

  static String formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'ص' : 'م';
    return '$h:$m $ap';
  }

  static String formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}س ${d.inMinutes % 60}د';
    return '${d.inMinutes} دقيقة';
  }

  static adhan.CalculationParameters _calcParams(
    String method,
    String madhab, {
    String? highLatitudeRule,
    int fajrOffset = 0,
    int sunriseOffset = 0,
    int dhuhrOffset = 0,
    int asrOffset = 0,
    int maghribOffset = 0,
    int ishaOffset = 0,
  }) {
    adhan.CalculationParameters p;
    switch (method) {
      case 'Algeria':
        // وزارة الشؤون الدينية والأوقاف - الجزائر
        // تعتمد زوايا قريبة من المصري (19.5/17.5) مع تعديلات طفيفة
        p = adhan.CalculationMethod.egyptian.getParameters();
        p.fajrAngle = 18.0;
        p.ishaAngle = 17.0;
        // تعديلات دقيقة لتطابق تطبيق صلاتك والرزنامة الرسمية
        p.methodAdjustments.fajr = 0;
        p.methodAdjustments.dhuhr = 0;
        p.methodAdjustments.asr = 1;
        p.methodAdjustments.maghrib = 5;
        p.methodAdjustments.isha = 0;
        break;
      case 'Egypt':
        p = adhan.CalculationMethod.egyptian.getParameters();
        break;
      case 'Karachi':
        p = adhan.CalculationMethod.karachi.getParameters();
        break;
      case 'UmmAlQura':
        p = adhan.CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'Dubai':
        p = adhan.CalculationMethod.dubai.getParameters();
        break;
      case 'Kuwait':
        p = adhan.CalculationMethod.kuwait.getParameters();
        break;
      case 'Qatar':
        p = adhan.CalculationMethod.qatar.getParameters();
        break;
      case 'Singapore':
        p = adhan.CalculationMethod.singapore.getParameters();
        break;
      case 'Turkey':
        p = adhan.CalculationMethod.turkey.getParameters();
        break;
      case 'Tehran':
        p = adhan.CalculationMethod.tehran.getParameters();
        break;
      case 'ISNA':
        p = adhan.CalculationMethod.north_america.getParameters();
        break;
      case 'MWL':
      default:
        p = adhan.CalculationMethod.muslim_world_league.getParameters();
        p.fajrAngle = 18.0;
        p.ishaAngle = 17.0;
    }
    p.madhab = madhab == 'hanafi' ? adhan.Madhab.hanafi : adhan.Madhab.shafi;

    // تطبيق قاعدة خطوط العرض العالية
    if (highLatitudeRule == 'seventh_of_the_night') {
      p.highLatitudeRule = adhan.HighLatitudeRule.seventh_of_the_night;
    } else if (highLatitudeRule == 'twilight_angle') {
      p.highLatitudeRule = adhan.HighLatitudeRule.twilight_angle;
    } else {
      p.highLatitudeRule = adhan.HighLatitudeRule.middle_of_the_night;
    }

    // تطبيق الفروق اليدوية بالدقائق
    p.adjustments.fajr += fajrOffset;
    p.adjustments.sunrise += sunriseOffset;
    p.adjustments.dhuhr += dhuhrOffset;
    p.adjustments.asr += asrOffset;
    p.adjustments.maghrib += maghribOffset;
    p.adjustments.isha += ishaOffset;

    return p;
  }
}

class NotificationRouter {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Which prayer last opened the Adhan screen, and when.
  ///
  /// Three independent paths can open that screen for the same prayer: this
  /// router (a notification tap, or the full-screen-intent launch — the only
  /// ones that fire while the app is backgrounded or killed), and
  /// AdhanAutoTrigger's two triggers in the main isolate. Each path has its
  /// own guard, but none of them covered this one, so a prayer arriving while
  /// the app was backgrounded could stack a second Adhan screen on top of the
  /// one the background signal had just opened: two audio players racing, the
  /// top screen hiding the other, and dismissing it doesn't stop the rest.
  /// All three now claim this same slot.
  static String? _lastAdhanClaim;
  static DateTime? _lastAdhanClaimAt;

  /// Claims the Adhan screen on behalf of the caller for [prayerKey].
  ///
  /// Returns false when the same prayer already claimed the slot within
  /// [_adhanClaimWindow] — i.e. an Adhan screen for it is already showing or
  /// on its way, and the caller must not open a second one.
  static bool claimAdhanRoute(String prayerKey, {DateTime? now}) {
    final at = now ?? DateTime.now();
    if (prayerKey == _lastAdhanClaim &&
        _lastAdhanClaimAt != null &&
        at.difference(_lastAdhanClaimAt!) < _adhanClaimWindow) {
      return false;
    }
    _lastAdhanClaim = prayerKey;
    _lastAdhanClaimAt = at;
    return true;
  }

  /// How long a claim is honoured. Long enough to outlast the other paths'
  /// navigator-ready waits (8s each, on top of their own polling), short
  /// enough that deliberately re-tapping the Adhan notification a few minutes
  /// later still reopens the screen.
  static const _adhanClaimWindow = Duration(minutes: 2);

  /// Whether an Adhan screen is already on the navigator stack.
  static bool _adhanAlreadyOnStack() {
    var visible = false;
    _navigatorKey.currentState?.popUntil((route) {
      if (route.settings.name == Routes.adhan) visible = true;
      return true; // never actually pop anything
    });
    return visible;
  }

  static Future<void> route(String payload) async {
    if (payload.isEmpty) return;
    final parts = payload.split(':');
    final type = parts.isNotEmpty ? parts[0] : '';
    final param = parts.length > 1 ? parts[1] : '';

    // Used to bail out immediately if the navigator wasn't ready at this
    // exact instant — reliably the case right after a cold launch (the app
    // was fully killed and this tap/full-screen-intent just started it),
    // since the widget tree isn't built that fast. That silently dropped
    // the navigation entirely, no retry — worst for `'prayer'`, where it
    // meant the Adhan screen just never opened. Poll instead of a single
    // snapshot, same fix as AdhanAutoTrigger._waitForNavigatorReady.
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (_navigatorKey.currentContext == null) {
      if (DateTime.now().isAfter(deadline)) return;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;
    // The above polling loop awaited, so the analyzer can no longer prove
    // `ctx` is still attached to the tree by the time we use it below
    // (even though it was fetched fresh right after the last await) —
    // this is the same guard `State.mounted` gives after an await, applied
    // to a BuildContext obtained via a GlobalKey instead of `this.context`.
    if (!ctx.mounted) return;

    switch (type) {
      case 'prayer':
        // A second Adhan screen for the same prayer is never wanted: the
        // background isolate's signal or the in-app polling loop has usually
        // opened one already (this path fires at the same instant — the
        // full-screen intent launches the activity while the signal is being
        // delivered), and the two would each play the Adhan. See
        // [claimAdhanRoute].
        if (param.isNotEmpty && !claimAdhanRoute(param)) {
          debugPrint('NotificationRouter: adhan already claimed for $param');
          break;
        }
        if (_adhanAlreadyOnStack()) {
          debugPrint('NotificationRouter: adhan screen already open');
          break;
        }
        Navigator.pushNamed(ctx, Routes.adhan, arguments: _prayerNameAr(param));
        break;
      case 'wakeup':
        Navigator.pushNamed(ctx, Routes.wakeUpOverlay);
        break;
      case 'pre_prayer':
      case 'iqama':
        Navigator.pushNamed(ctx, Routes.prayer);
        break;
      case 'muhasaba':
        _goToShellTab(ctx, 2); // المحاسبة
        break;
      case 'adhkar':
        // `adhkar:<category>` (see AdhkarNotificationService) — land on the
        // tab the reminder was about, not always the first one.
        final catIndex = AdhkarCategory.values.indexWhere(
          (c) => c.name == param,
        );
        Navigator.pushNamed(
          ctx,
          Routes.adhkar,
          arguments: catIndex >= 0 ? catIndex : null,
        );
        break;
      case 'dua':
        Navigator.pushNamed(ctx, Routes.duas);
        break;
      case 'achievement':
        _goToShellTab(ctx, 3); // إحصائيات
        break;
      case 'reminder':
        _goToShellTab(ctx, 0); // الرئيسية
        break;
      case 'ramadan':
        Navigator.pushNamed(ctx, Routes.prayer);
        break;
      case 'release_update':
        // The URL itself contains colons (scheme + query), so it can't use
        // the shared `param` above (a naive split(':') on
        // "https://example.com/#x" fragments the URL) — reconstruct
        // everything after the first colon instead. See
        // docs/specs/release-push-notifications.md.
        final url = payload.substring(payload.indexOf(':') + 1);
        if (url.isNotEmpty) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        break;
    }
  }

  /// Switches to a tab on the already-mounted [MainShell] instead of
  /// pushing a brand-new one on top of it. `Routes.checklist` /
  /// `.statistics` / `.home` all resolve to `MainShell(initialIndex: ...)`,
  /// so pushing them by name (as this used to do) stacked a second, fully
  /// independent shell — with its own bottom nav — on every notification
  /// tap while the app was already open, leaving the back button landing
  /// on a confusing duplicate screen instead of just switching tabs.
  static void _goToShellTab(BuildContext ctx, int tabIndex) {
    final navigator = Navigator.of(ctx);
    try {
      ProviderScope.containerOf(
        ctx,
        listen: false,
      ).read(currentTabProvider.notifier).state = tabIndex;
    } catch (_) {
      // No ProviderScope above this context (shouldn't happen once the
      // shell is mounted) — fall back to a plain named push below.
    }
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    } else {
      Navigator.pushNamed(ctx, Routes.home);
    }
  }

  static String _prayerNameAr(String key) => switch (key) {
    'fajr' => 'الفجر',
    'dhuhr' => 'الظهر',
    'asr' => 'العصر',
    'maghrib' => 'المغرب',
    'isha' => 'العشاء',
    _ => key.isNotEmpty ? key : 'الصلاة',
  };
}

final prayerTimesProvider = FutureProvider<List<PrayerTimeInfo>>((ref) async {
  final prefs = await ref.watch(userPreferencesProvider.future);
  final settings = ref.watch(settingsDaoProvider);

  // مراقبة الموقع بشكل تفاعلي
  final savedLat =
      ref.watch(settingStreamProvider('latitude')).value ??
      await settings.get('latitude');
  final savedLng =
      ref.watch(settingStreamProvider('longitude')).value ??
      await settings.get('longitude');
  final savedTz =
      ref.watch(settingStreamProvider('timezone')).value ??
      await settings.get('timezone');

  double lat, lng;
  if (savedLat != null && savedLng != null) {
    lat = double.tryParse(savedLat) ?? 36.7;
    lng = double.tryParse(savedLng) ?? 3.0;
  } else {
    final pos = await PrayerTimesService.getLocation();
    lat = pos?.latitude ?? 36.7;
    lng = pos?.longitude ?? 3.0;
    if (pos != null) {
      await settings.set('latitude', lat.toString());
      await settings.set('longitude', lng.toString());
      // Mirrored too, for the same reason location_prayer_update persists
      // both: the background-service isolate reads coordinates off
      // SharedPreferences, not out of the Drift store.
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('latitude', lat.toString());
      await prefs.setString('longitude', lng.toString());
    }
  }

  final tzName = savedTz ?? TimezoneResolver.resolveFromCoordinates(lat, lng);

  return PrayerTimesService.calculate(
    latitude: lat,
    longitude: lng,
    madhab: prefs.madhab,
    method: prefs.calcMethod,
    highLatitudeRule: prefs.highLatitudeRule,
    fajrOffset: prefs.fajrOffset,
    sunriseOffset: prefs.sunriseOffset,
    dhuhrOffset: prefs.dhuhrOffset,
    asrOffset: prefs.asrOffset,
    maghribOffset: prefs.maghribOffset,
    ishaOffset: prefs.ishaOffset,
    timezone: tzName,
  );
});

final nextPrayerProvider = Provider<AsyncValue<PrayerTimeInfo?>>(
  (ref) => ref
      .watch(prayerTimesProvider)
      .whenData((p) => PrayerTimesService.nextPrayer(p)),
);

final notificationsManagerProvider = Provider<NotificationsManager>((ref) {
  return NotificationsManager(ref);
});

class NotificationsManager {
  final Ref _ref;
  NotificationsManager(this._ref);

  /// Resolved once per scheduling pass rather than per-notification — every
  /// method below that builds notification text takes this instead of
  /// reaching for a hardcoded locale, so scheduled titles/bodies actually
  /// follow the app's current language instead of always being Arabic
  /// (the i18n audit's notification-text finding).
  AppLocalizations _currentL10n() =>
      lookupAppLocalizations(_ref.read(localeProvider));

  Future<void> scheduleAll() async {
    if (!await NotificationsService.checkPermissions()) return;

    final prefs = await _ref.read(userPreferencesProvider.future);
    final l10n = _currentL10n();

    // أوقات الصلاة
    if (prefs.prayerReminder) {
      await _scheduleUpcomingPrayers(prefs, l10n);
    }

    // تنبيه اليقظة قبل الفجر
    if (prefs.wakeUpBeforeFajr) {
      await NotificationsService.scheduleWakeUpAlarm(
        time: prefs.wakeUpTime,
        l10n: l10n,
      );
    } else {
      await NotificationsService.cancel(NotifIds.wakeUpAlarm);
    }

    // المحاسبة
    if (prefs.muhasabaReminder) {
      await NotificationsService.scheduleEveningMuhasaba(
        time: prefs.muhasabaTime,
        l10n: l10n,
      );
    }

    // الأذكار
    await _scheduleAdhkar(prefs, l10n);

    // الأدعية
    if (prefs.dailyDuasOn) {
      await NotificationsService.scheduleDailyDuas(prefs: prefs, l10n: l10n);
    } else {
      await NotificationsService.cancelDailyDuas();
    }

    // التذكيرات الخاصة
    await NotificationsService.scheduleSpecialReminders(
      fridayReminders: prefs.specialRemindersOn,
      fastingReminders: prefs.fastingRemindersOn,
      l10n: l10n,
    );
  }

  Future<void> reschedule([
    NotificationCategory category = NotificationCategory.all,
  ]) async {
    switch (category) {
      case NotificationCategory.prayer:
        await _reschedulePrayers();
        break;
      case NotificationCategory.adhkar:
        await _rescheduleAdhkar();
        break;
      case NotificationCategory.reminders:
        await _rescheduleReminders();
        break;
      case NotificationCategory.all:
        await NotificationsService.cancelAll();
        await scheduleAll();
        break;
      case NotificationCategory.none:
        break;
    }
  }

  /// Schedules the rolling multi-day prayer-alert horizon from the stored
  /// location and calculation settings.
  ///
  /// This is the main isolate's replacement for scheduling "today's remaining
  /// prayers". Everything about it exists so the alarms are already in the OS
  /// queue when the user's next prayer arrives — including the case where they
  /// haven't opened the app since yesterday.
  Future<void> _scheduleUpcomingPrayers(
    UserPreferences prefs,
    AppLocalizations l10n,
  ) async {
    // Resolving today's times first guarantees a location exists before the
    // horizon is built: when none is stored yet, prayerTimesProvider is what
    // acquires one and writes it back to settings, so reading the coordinates
    // afterwards can't silently fall through to the default city.
    await _ref.read(prayerTimesProvider.future);

    final settings = _ref.read(settingsDaoProvider);
    final latitude = double.tryParse(await settings.get('latitude') ?? '');
    final longitude = double.tryParse(await settings.get('longitude') ?? '');
    if (latitude == null || longitude == null) return;

    await NotificationsService.scheduleUpcomingPrayerNotifications(
      latitude: latitude,
      longitude: longitude,
      timezone: await settings.get('timezone'),
      madhab: prefs.madhab,
      method: prefs.calcMethod,
      highLatitudeRule: prefs.highLatitudeRule,
      fajrOffset: prefs.fajrOffset,
      sunriseOffset: prefs.sunriseOffset,
      dhuhrOffset: prefs.dhuhrOffset,
      asrOffset: prefs.asrOffset,
      maghribOffset: prefs.maghribOffset,
      ishaOffset: prefs.ishaOffset,
      l10n: l10n,
      preAdhanEnabled: prefs.preAdhanNotif,
      iqamaEnabled: prefs.iqamaNotif,
      adhanMode: prefs.adhanMode,
      adhanScreenEnabled: prefs.adhanScreenEnabled,
      adhanAlarmEnabled: prefs.adhanAlarmEnabled,
    );
  }

  Future<void> _reschedulePrayers() async {
    // Cancels the legacy single-day ids and the whole rolling horizon —
    // including the day that fell off the end of the previous run, which
    // nothing else would ever overwrite.
    await NotificationsService.cancelPrayerNotifications();
    await NotificationsService.cancel(NotifIds.wakeUpAlarm);

    final prefs = await _ref.read(userPreferencesProvider.future);
    final l10n = _currentL10n();

    if (prefs.prayerReminder) {
      await _scheduleUpcomingPrayers(prefs, l10n);
    }

    if (prefs.wakeUpBeforeFajr) {
      await NotificationsService.scheduleWakeUpAlarm(
        time: prefs.wakeUpTime,
        l10n: l10n,
      );
    }
  }

  /// Hands the adhkar reminders their location, so the after-Fajr and
  /// after-Asr ones can be anchored to the real prayer times instead of a
  /// clock. Resolving today's prayer times first is what writes a first-run
  /// user's coordinates back to settings (see [_scheduleUpcomingPrayers]);
  /// if that fails the reminders still go out on their clock times, which
  /// needs no location at all.
  Future<void> _scheduleAdhkar(
    UserPreferences prefs,
    AppLocalizations l10n,
  ) async {
    double? latitude;
    double? longitude;
    String? timezone;
    try {
      await _ref.read(prayerTimesProvider.future);
      final settings = _ref.read(settingsDaoProvider);
      latitude = double.tryParse(await settings.get('latitude') ?? '');
      longitude = double.tryParse(await settings.get('longitude') ?? '');
      timezone = await settings.get('timezone');
    } catch (e) {
      debugPrint('NotificationsManager: location unavailable for adhkar: $e');
    }
    await AdhkarNotificationService.rescheduleAll(
      prefs,
      l10n: l10n,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
    );
  }

  Future<void> _rescheduleAdhkar() async {
    // Adhkar ids are handled internally by AdhkarNotificationService.rescheduleAll
    final prefs = await _ref.read(userPreferencesProvider.future);
    await _scheduleAdhkar(prefs, _currentL10n());
  }

  Future<void> _rescheduleReminders() async {
    final ids = [
      NotifIds.eveningMuhasaba,
      NotifIds.fastingWhiteDays,
      NotifIds.fastingMonday,
      NotifIds.fastingThursday,
      NotifIds.fridayKahf,
      NotifIds.fridaySalawat,
    ];

    for (final id in ids) {
      await NotificationsService.cancel(id);
    }

    final prefs = await _ref.read(userPreferencesProvider.future);
    final l10n = _currentL10n();

    if (prefs.muhasabaReminder) {
      await NotificationsService.scheduleEveningMuhasaba(
        time: prefs.muhasabaTime,
        l10n: l10n,
      );
    }

    if (prefs.dailyDuasOn) {
      await NotificationsService.scheduleDailyDuas(prefs: prefs, l10n: l10n);
    } else {
      await NotificationsService.cancelDailyDuas();
    }

    await NotificationsService.scheduleSpecialReminders(
      fridayReminders: prefs.specialRemindersOn,
      fastingReminders: prefs.fastingRemindersOn,
      l10n: l10n,
    );
  }
}

// Helper extension
extension on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays + 1;
  }
}
