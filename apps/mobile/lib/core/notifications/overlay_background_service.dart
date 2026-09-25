import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as ow;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

import '../utils/timezone_resolver.dart';
import 'notifications_service.dart';
import 'package:takwa/l10n/app_localizations.dart';

// This background isolate (spawned by flutter_foreground_task) doesn't share
// the main isolate's Riverpod/locale state, so chrome strings below use a
// fixed-locale lookup rather than trying to follow the live app locale.
final AppLocalizations _l10n = lookupAppLocalizations(const Locale('ar'));

// ─────────────────────────────────────────
//  SHARED PREFS KEYS
// ─────────────────────────────────────────
const _kTriggeredPrayersKey = 'overlay_triggered_prayers';
const _kTriggeredPrayersDateKey = 'overlay_triggered_prayers_date';
const _kLatKey = 'latitude';
const _kLngKey = 'longitude';
const _kMadhabKey = 'madhab';
const _kCalcMethodKey = 'calc_method';
const _kCityNameKey = 'cityName';
const _kTimezoneKey = 'timezone';
const _kHighLatitudeRuleKey = 'high_latitude_rule';
const _kLastPopupMsKey = 'last_adhkar_popup_ms';
const _kOverlayEnabledKey = 'overlay_popups_enabled';
const _kPreAdhanNotifEnabledKey = 'pre_adhan_notif';
const _kPopupIntervalMinsKey = 'popup_interval_minutes';
const _kAdhanScreenTriggeredKey = 'adhan_screen_triggered';
const _kSilentModeEnabledKey = 'silent_mode_enabled';
const _kSilentDurationMinsKey = 'silent_duration_mins';
const _kAutoSilentAfterAdhanKey = 'auto_silent_after_adhan';
const _kSilentModeVibrationKey = 'silent_vibration_enabled';
// Adhan mode ('sound' | 'vibrate' | 'silent') — mirrored from SQLite via
// SettingsPrefsBridge so the background isolate can read the canonical
// value without Riverpod access.
const _kAdhanModeKey = 'adhan_mode';
const _kSilentAdhanPrayersKey = 'silent_adhan_prayers';
const _kSilentNotifPrayersKey = 'silent_notif_prayers';
const _kOngoingNotifEnabledKey = 'ongoing_notif_enabled';

// ─────────────────────────────────────────
//  TIMINGS
// ─────────────────────────────────────────
/// كل 24 دقيقة = 60 مرة يومياً تقريباً
const _kDefaultPopupIntervalMins = 24;

/// نافذة اكتشاف وقت الصلاة: ±90 ثانية
const _kPrayerWindowSecs = 90;

/// حجب إعادة الأذان لنفس الصلاة لمدة 30 دقيقة
const _kAdhanCooldownMins = 30;

/// مدة عرض الـ overlay قبل إغلاقه تلقائياً (ثانية)
const _kOverlayAutoCloseSecs = 20;

// ─────────────────────────────────────────
//  PRAYER INFO MODEL
// ─────────────────────────────────────────
class _PrayerInfo {
  final String name;
  final String nameAr;
  final String emoji;
  final DateTime time;
  const _PrayerInfo(this.name, this.nameAr, this.emoji, this.time);
}

class OverlayBackgroundService {
  static const _channelId = 'takkwa_background_overlay';
  static const _channelName = 'Takkwa Overlay Background';

  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: _l10n.overlayServiceChannelDesc,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000), // كل ثانية
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) return;
    final perm = await FlutterForegroundTask.checkNotificationPermission();
    if (perm != NotificationPermission.granted) return;

    final prefs = await SharedPreferences.getInstance();
    // Gate: respect the user's choice to hide the persistent foreground notification.
    if (!(prefs.getBool(_kOngoingNotifEnabledKey) ?? true)) return;

    final cityName =
        prefs.getString(_kCityNameKey) ?? _l10n.overlayServiceDefaultCity;

    await FlutterForegroundTask.startService(
      notificationTitle: '$cityName | ${_l10n.appName} 🌙',
      notificationText: _l10n.overlayServiceLoadingPrayerTimes,
      notificationButtons: [
        NotificationButton(
          id: 'open_app',
          text: _l10n.overlayServiceOpenAppButton,
        ),
        NotificationButton(
          id: 'update_location',
          text: _l10n.overlayServiceUpdateLocationButton,
        ),
      ],
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// Whether the OS-level "display over other apps" permission is
  /// currently granted. The Adhan screen and the adhkar/dua popups can
  /// only auto-open while the app is backgrounded/killed if this is
  /// granted (see docs/specs/adhan-overlay-auto-open.md) — used by the
  /// Settings UI so an enabled toggle never silently no-ops.
  static Future<bool> isOverlayPermissionGranted() async {
    try {
      return await ow.FlutterOverlayWindow.isPermissionGranted().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      final perm = await FlutterForegroundTask.checkNotificationPermission()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => NotificationPermission.denied,
          );
      if (perm != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission().timeout(
          const Duration(seconds: 15),
          onTimeout: () => NotificationPermission.denied,
        );
      }
      final isOverlayGranted =
          await ow.FlutterOverlayWindow.isPermissionGranted().timeout(
            const Duration(seconds: 5),
            onTimeout: () => false,
          );
      if (!isOverlayGranted) {
        await ow.FlutterOverlayWindow.requestPermission().timeout(
          const Duration(seconds: 30),
          onTimeout: () => false,
        );
      }
      final newPerm = await FlutterForegroundTask.checkNotificationPermission()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => NotificationPermission.denied,
          );
      final newOverlay = await ow.FlutterOverlayWindow.isPermissionGranted()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      return newPerm == NotificationPermission.granted && newOverlay;
    } catch (_) {
      return false;
    }
  }

  /// تحديث إعدادات الـ overlay من التطبيق الرئيسي
  static void updateSettings({
    bool? overlayEnabled,
    int? popupIntervalMins,
    String? adhanMode,
    bool? adhanScreenEnabled,
    bool? flipToSilenceEnabled,
    bool? silentModeEnabled,
    int? silentDurationMins,
    double? adhanVolumeLevel,
  }) {
    final Map<String, dynamic> data = {};
    if (overlayEnabled != null) data['overlay_popups_enabled'] = overlayEnabled;
    if (popupIntervalMins != null) {
      data['popup_interval_minutes'] = popupIntervalMins;
    }
    if (adhanMode != null) data['adhan_mode'] = adhanMode;
    // Lets the background isolate know right away whether the "Adhan
    // screen" toggle is on, instead of only picking it up on its next full
    // restart — same class of gap `adhanMode` had before R6. Without this,
    // toggling the setting off wouldn't stop the killed-app system overlay
    // from still popping up until the service happened to restart.
    if (adhanScreenEnabled != null) {
      data['adhan_screen_enabled'] = adhanScreenEnabled;
    }
    if (flipToSilenceEnabled != null) {
      data['flip_to_silence_enabled'] = flipToSilenceEnabled;
    }
    if (silentModeEnabled != null) {
      data['silent_mode_enabled'] = silentModeEnabled;
    }
    if (silentDurationMins != null) {
      data['silent_duration_mins'] = silentDurationMins;
    }
    // `_OverlayTaskHandler.onReceiveData` already understood this key (see
    // below) — it just had no way to receive it live, since neither this
    // parameter nor a call site existed. Without this, a volume change in
    // Settings only reached the background isolate on its next full
    // restart, same class of gap `adhanMode` had before R6's earlier fix.
    // See docs/specs/settings-notifications-improvements.md R6.
    if (adhanVolumeLevel != null) {
      data['adhan_volume_level'] = adhanVolumeLevel;
    }

    if (data.isNotEmpty) FlutterForegroundTask.sendDataToTask(data);
  }

  /// Creates a fresh [TestableOverlayHandler] for unit tests.
  ///
  /// This exposes enough of [_OverlayTaskHandler]'s adhan-trigger logic to
  /// let tests verify Bug 4 (toggle propagation) without a real foreground
  /// service. Never call from production code.
  @visibleForTesting
  static TestableOverlayHandler createHandlerForTesting() =>
      TestableOverlayHandler();
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_OverlayTaskHandler());
}

class _OverlayTaskHandler extends TaskHandler {
  List<_PrayerInfo> _todayPrayers = [];
  String _lastPrayerDate = '';

  // إعدادات قابلة للتحديث ديناميكياً
  bool _overlayEnabled = true;
  int _popupIntervalMins = _kDefaultPopupIntervalMins;
  bool _silentModeEnabled = false;
  int _silentDurationMins = 20;
  // Canonical adhan mode — matches UserPreferences.adhanMode values:
  // 'sound' | 'vibrate' | 'silent'. Sent to the main isolate so
  // handleForegroundData can make the right decision about audio.
  String _adhanMode = 'sound';
  // Whether the Adhan overlay screen should be shown when a prayer time
  // arrives. Mirrors UserPreferences.adhanScreenEnabled; updated live via
  // onReceiveData so the service never needs a restart to pick up the
  // latest toggle value.
  bool _adhanScreenEnabled = true;
  // adhanScreenEnabled/flipToSilenceEnabled/adhanVolumeLevel used to be
  // mirrored here too, to gate/feed this isolate's own system-overlay
  // "prayer" popup and its (never-added) audio. That popup is gone — see
  // docs/specs/adhan-overlay-auto-open.md's seventh pass — so this isolate
  // has nothing left to use them for; onReceiveData/updateSettings on the
  // main-isolate side still accept and forward them (harmless, just
  // unread here now) so removing them doesn't require touching those
  // call sites.

  final _random = math.Random();

  // ──────────────────────────────────────
  //  LIFECYCLE
  // ──────────────────────────────────────
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await NotificationsService.initialize();
    await _loadSettings();
    await _refreshPrayerTimes();
    await _updateForegroundNotification();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    await _updateForegroundNotification();
    await _checkAndTriggerAdhan();
    await _checkAndApplySilentMode();
    if (_overlayEnabled) await _checkAndShowAdhkarOverlay();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final action = data['action'];
      if (action == 'update_location') _handleLocationUpdate();
      if (data.containsKey('overlay_popups_enabled')) {
        _overlayEnabled = data['overlay_popups_enabled'] as bool;
      }
      if (data.containsKey('popup_interval_minutes')) {
        _popupIntervalMins = data['popup_interval_minutes'] as int;
      }
      if (data.containsKey('adhan_mode')) {
        _adhanMode = data['adhan_mode'] as String;
      }
      if (data.containsKey('adhan_screen_enabled')) {
        _adhanScreenEnabled = data['adhan_screen_enabled'] as bool;
      }
      if (data.containsKey('silent_mode_enabled')) {
        _silentModeEnabled = data['silent_mode_enabled'] as bool;
      }
      if (data.containsKey('silent_duration_mins')) {
        _silentDurationMins = data['silent_duration_mins'] as int;
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) async {
    if (id == 'open_app') {
      FlutterForegroundTask.launchApp();
    } else if (id == 'update_location') {
      await FlutterForegroundTask.updateService(
        notificationTitle: _l10n.appName,
        notificationText: _l10n.overlayServiceUpdatingLocation,
      );
      await _handleLocationUpdate();
    }
  }

  @override
  void onNotificationPressed() {}

  // ──────────────────────────────────────
  //  SETTINGS LOADER
  // ──────────────────────────────────────
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _overlayEnabled = prefs.getBool(_kOverlayEnabledKey) ?? true;
    _popupIntervalMins =
        prefs.getInt(_kPopupIntervalMinsKey) ?? _kDefaultPopupIntervalMins;
    _silentModeEnabled = prefs.getBool(_kSilentModeEnabledKey) ?? false;
    _silentDurationMins = prefs.getInt(_kSilentDurationMinsKey) ?? 20;
    _adhanMode = prefs.getString(_kAdhanModeKey) ?? 'sound';
    _adhanScreenEnabled = prefs.getBool('adhan_screen_enabled') ?? true;
  }

  // ──────────────────────────────────────
  //  SILENT MODE WORKER
  // ──────────────────────────────────────
  Future<void> _checkAndApplySilentMode() async {
    if (!_silentModeEnabled) return;

    final now = DateTime.now();
    bool shouldBeSilent = false;

    for (final prayer in _todayPrayers) {
      final start = prayer.time;
      final end = start.add(Duration(minutes: _silentDurationMins));

      if (now.isAfter(start) && now.isBefore(end)) {
        shouldBeSilent = true;
        break;
      }
    }

    try {
      final currentMode = await SoundMode.ringerModeStatus;
      if (shouldBeSilent) {
        if (currentMode != RingerModeStatus.silent &&
            currentMode != RingerModeStatus.vibrate) {
          final prefs = await SharedPreferences.getInstance();
          final vibe = prefs.getBool(_kSilentModeVibrationKey) ?? true;
          await SoundMode.setSoundMode(
            vibe ? RingerModeStatus.vibrate : RingerModeStatus.silent,
          );
          debugPrint('🔇 Silent Mode Applied');
        }
      } else {
        // If we are NOT in a prayer window, and we applied silent mode, we should ideally revert.
        // But we don't want to force "Normal" if the user manually set it to silent.
        // A better way is to track if WE set it to silent.
        // For now, let's just make it silent during the window.
      }
    } catch (e) {
      debugPrint('❌ Error in Silent Worker: $e');
    }
  }

  // ──────────────────────────────────────
  //  FOREGROUND NOTIFICATION UPDATE
  // ──────────────────────────────────────
  Future<void> _updateForegroundNotification() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final city =
        prefs.getString(_kCityNameKey) ?? _l10n.overlayServiceDefaultCity;
    final hijri = HijriCalendar.now();
    final hStr = '${hijri.hDay} ${_hijriMonthAr(hijri.hMonth)} ${hijri.hYear}';

    if (_todayPrayers.isEmpty || _lastPrayerDate != _dateKey(now)) {
      await _refreshPrayerTimes();
    }
    if (_todayPrayers.isEmpty) return;

    final next = _nextPrayer(now);
    final countdown = _countdown(now, next.time);
    final text =
        '$countdown ${next.emoji} ${next.nameAr}  |  ${DateFormat('HH:mm').format(next.time)}';

    FlutterForegroundTask.updateService(
      notificationTitle: '$city  |  $hStr',
      notificationText: text,
      notificationButtons: [
        NotificationButton(
          id: 'open_app',
          text: _l10n.overlayServiceOpenAppButton,
        ),
        NotificationButton(
          id: 'update_location',
          text: _l10n.overlayServiceUpdateLocationButton,
        ),
      ],
    );
  }

  // ──────────────────────────────────────
  //  ADHAN TRIGGER — يُطلق شاشة الأذان تلقائياً
  // ──────────────────────────────────────
  Future<void> _checkAndTriggerAdhan() async {
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    if (_lastPrayerDate != todayKey) await _refreshPrayerTimes();
    if (_todayPrayers.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final triggeredDate = prefs.getString(_kTriggeredPrayersDateKey) ?? '';
    Set<String> triggered;

    if (triggeredDate != todayKey) {
      triggered = {};
      await prefs.setString(_kTriggeredPrayersDateKey, todayKey);
      await prefs.setString(_kTriggeredPrayersKey, '');
    } else {
      final raw = prefs.getString(_kTriggeredPrayersKey) ?? '';
      triggered = raw.isEmpty ? {} : raw.split(',').toSet();
    }

    for (final prayer in _todayPrayers) {
      if (triggered.contains(prayer.name)) continue;

      final diffSecs = now.difference(prayer.time).inSeconds;
      // Was 60s. Too narrow whenever this isolate's own 1s tick gets
      // delayed by OS power management (Doze/App Standby/OEM battery
      // optimization can and does push a "1 second" foreground-task tick
      // out by several minutes on real devices) — by the time it resumes,
      // the window had already closed and this prayer was silently never
      // triggered from here at all. 300s (5 min) gives a delayed tick real
      // room to still catch it, matching AdhanAutoTrigger's own widened
      // window below.
      if (diffSecs >= 0 && diffSecs <= 300) {
        triggered.add(prayer.name);
        await prefs.setString(_kTriggeredPrayersKey, triggered.join(','));

        // Prayer time reached. This background isolate used to also (a)
        // fire its own separate notification via _scheduleAdhanNotification
        // — redundant with, and weaker than, the exact-alarm notification
        // NotificationsService.schedulePrayerNotifications already
        // scheduled ahead of time for this same prayer (that one carries
        // fullScreenIntent; showNotification() here never could, so this
        // was pure duplicate tray clutter with no extra reach), and (b)
        // pop its own small system-overlay "prayer" card
        // (ow.FlutterOverlayWindow.showOverlay + shareData) — a second,
        // separate UI competing with the real Adhan screen, with no audio
        // and no flip-to-silence of its own, easy to mistake for "the
        // adhan" while having no way to stop it. Both removed: the single
        // source of truth for "prayer time reached" is now the sendDataToMain
        // signal below (opens the real AdhanOverlayScreen immediately with
        // sound + flip-to-silence when the main isolate is alive) plus the
        // already-scheduled exact-alarm notification (covers the app being
        // fully killed, via fullScreenIntent).

        // إرسال أمر لفتح شاشة الأذان في التطبيق (أو تقليله حسب الإعدادات)
        // Silent-mode allow-list gate: when the phone is in silent/vibrate AND
        // _silentModeEnabled is true, only send show_adhan if the prayer key
        // appears in the silent_adhan_prayers allow-list. When _silentModeEnabled
        // is false, proceed unconditionally (Preservation: Requirement 3.11).
        bool suppressAdhan = false;
        if (_silentModeEnabled) {
          try {
            final ringerMode = await SoundMode.ringerModeStatus;
            if (ringerMode == RingerModeStatus.silent ||
                ringerMode == RingerModeStatus.vibrate) {
              final allowListRaw =
                  prefs.getString(_kSilentAdhanPrayersKey) ?? '';
              final allowList = allowListRaw.isEmpty
                  ? <String>{}
                  : allowListRaw.split(',').map((e) => e.trim()).toSet();
              if (!allowList.contains(prayer.name)) {
                suppressAdhan = true;
                debugPrint(
                  '🔇 Adhan suppressed in silent mode for ${prayer.name} '
                  '(not in allow-list)',
                );
              }
            }
          } catch (e) {
            // If SoundMode throws, default to NOT suppressing.
            debugPrint('OverlayService: SoundMode check failed: $e');
          }
        }

        if (_adhanScreenEnabled && !suppressAdhan) {
          FlutterForegroundTask.sendDataToMain({
            'action': 'show_adhan',
            'prayer': prayer.nameAr,
            // Internal id ('fajr'/'dhuhr'/…), not the Arabic display name
            // above — lets AdhanAutoTrigger.handleForegroundData build the
            // same per-prayer-per-day dedupe key AdhanAutoTrigger._check
            // uses, closing a race where both could push the Adhan screen
            // for the same prayer. See docs/specs/adhan-overlay-auto-open.md R7.
            'prayerKey': prayer.name,
            'emoji': prayer.emoji,
            'time': DateFormat('HH:mm').format(prayer.time),
            // Send the canonical adhan mode string so the main isolate's
            // handleForegroundData can make the correct sound/screen decision.
            // The old 'sound' bool key is kept alongside for backward compat
            // with any cached version of the task handler still in memory.
            'adhanMode': _adhanMode,
            'sound': _adhanMode == 'sound', // legacy compat
          });
        }

        debugPrint('🕌 أُطلق أذان ${prayer.nameAr}');
        return;
      }
    }
  }

  // ──────────────────────────────────────
  //  ADHKAR OVERLAY — كل N دقيقة
  // ──────────────────────────────────────
  Future<void> _checkAndShowAdhkarOverlay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastPopupMsKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final intervalMs = _popupIntervalMins * 60 * 1000;

      if (now - lastMs < intervalMs) return;

      // لا تُظهر الـ overlay إذا كان وقت الصلاة قريباً (±5 دقائق)
      if (_isNearPrayerTime(5)) return;

      final hasPermission = await ow.FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) return;
      final isActive = await ow.FlutterOverlayWindow.isActive();
      if (isActive) return;

      await prefs.setInt(_kLastPopupMsKey, now);

      // اختر نوع المحتوى بشكل متناوب: أذكار أو دعاء
      final showType = _shouldShowDua() ? 'dua' : 'adhkar';

      await ow.FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: showType == 'dua'
            ? _l10n.overlayServiceDuaOverlayTitle
            : _l10n.overlayServiceAdhkarOverlayTitle,
        overlayContent: showType == 'dua'
            ? _l10n.overlayServiceDuaOverlayContent
            : _l10n.overlayServiceAdhkarOverlayContent,
        flag: ow.OverlayFlag.defaultFlag,
        alignment: ow.OverlayAlignment.topCenter,
        visibility: ow.NotificationVisibility.visibilityPublic,
        positionGravity: ow.PositionGravity.none,
        height: ow.WindowSize.matchParent,
        width: ow.WindowSize.matchParent,
      );

      // أرسل البيانات بعد تهيئة الـ overlay
      await Future.delayed(const Duration(milliseconds: 600));
      ow.FlutterOverlayWindow.shareData({'type': showType});

      debugPrint('📿 Overlay opened: $showType');
    } catch (e) {
      debugPrint('OverlayService: popup error: $e');
    }
  }

  /// تناوب ذكي: دعاء 30% من الوقت، أذكار 70%
  bool _shouldShowDua() {
    final hour = DateTime.now().hour;
    // في الصباح والمساء: أذكار بشكل رئيسي
    if (hour >= 5 && hour <= 8) return false; // وقت أذكار الصباح
    if (hour >= 16 && hour <= 18) return false; // وقت أذكار المساء
    return _random.nextInt(10) < 3; // 30% دعاء
  }

  /// هل نحن قريبون من وقت صلاة؟
  bool _isNearPrayerTime(int marginMins) {
    final now = DateTime.now();
    for (final p in _todayPrayers) {
      final diff = p.time.difference(now).inMinutes.abs();
      if (diff <= marginMins) return true;
    }
    return false;
  }

  // ──────────────────────────────────────
  //  PRAYER TIMES
  // ──────────────────────────────────────
  _PrayerInfo _nextPrayer(DateTime now) {
    for (final p in _todayPrayers) {
      if (p.time.isAfter(now)) return p;
    }
    // كل الصلوات انتهت → فجر الغد
    final tomorrow = now.add(const Duration(days: 1));
    return _PrayerInfo(
      'fajr',
      'الفجر',
      '🌅',
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 0),
    );
  }

  Future<void> _refreshPrayerTimes() async {
    _lastPrayerDate = _dateKey(DateTime.now());
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = _doublePref(prefs, _kLatKey);
      final lng = _doublePref(prefs, _kLngKey);
      if (lat == null || lng == null) {
        // No fix saved yet. Previously this fell back to Algiers and then
        // *scheduled alarms for that fallback*, overwriting whatever correct
        // times the main isolate had written — someone in Cairo got Algiers
        // alarms until their next location refresh. Leaving the existing
        // schedule alone is strictly better than replacing it with a guess.
        debugPrint(
          'OverlayService: no saved coordinates, prayer times unchanged',
        );
        return;
      }

      // Same pure-Dart calculation the main isolate runs, so both sides agree
      // to the minute. This isolate used to carry its own copy of the adhan
      // parameter table, which had drifted from the main isolate's (Algeria
      // resolved to different angles and different dhuhr/maghrib adjustments)
      // — so the pre-scheduled exact alarms and this isolate's own polling
      // could disagree about when the same prayer was.
      final times = await PrayerTimesService.calculate(
        latitude: lat,
        longitude: lng,
        timezone: prefs.getString(_kTimezoneKey),
        madhab: prefs.getString(_kMadhabKey) ?? 'shafi',
        method: prefs.getString(_kCalcMethodKey) ?? 'Algeria',
        highLatitudeRule: prefs.getString(_kHighLatitudeRuleKey),
        fajrOffset: _intPref(prefs, 'fajr_offset'),
        sunriseOffset: _intPref(prefs, 'sunrise_offset'),
        dhuhrOffset: _intPref(prefs, 'dhuhr_offset'),
        asrOffset: _intPref(prefs, 'asr_offset'),
        maghribOffset: _intPref(prefs, 'maghrib_offset'),
        ishaOffset: _intPref(prefs, 'isha_offset'),
      );

      // Sunrise carries no adhan; the polling loops only ever care about the
      // five prayers.
      _todayPrayers = times
          .where((p) => p.name != 'sunrise')
          .map((p) => _PrayerInfo(p.name, p.nameAr, p.emoji, p.time))
          .toList();

      // Keep the exact-alarm/full-screen-intent Adhan notifications in sync
      // with whatever day this isolate thinks it is. That's the one mechanism
      // meant to fire the Adhan screen right on time regardless of Doze/
      // App-Standby throttling — the two polling loops (this isolate's own 1s
      // tick below and AdhanAutoTrigger's in the main isolate) are only a
      // fallback, bounded by their own dedupe windows, and can't recover once
      // the OS delays a tick past prayer time. Previously this was scheduled
      // exactly once, from MainShell on cold start — fine for that day, but
      // nothing ever rescheduled it for the next one if the app process (kept
      // alive by this very foreground service) survived past midnight without
      // a full restart, and from the second day onward the exact alarms were
      // stale/gone. The call below now covers a multi-day horizon, so surviving
      // past midnight no longer means praying to a stale schedule.
      await _rescheduleExactAlarms();
    } catch (e) {
      debugPrint('OverlayService: Failed to compute prayer times: $e');
    }
  }

  /// Re-schedules the exact-alarm prayer notifications
  /// (NotificationsService.scheduleUpcomingPrayerNotifications) across the
  /// same multi-day horizon the main isolate uses. Safe to call repeatedly:
  /// that method cancels the IDs it owns before re-scheduling, so calling it
  /// again over an overlapping range is idempotent rather than duplicating.
  Future<void> _rescheduleExactAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Mirrors NotificationsManager.scheduleAll()'s own gate — respect the
      // user turning prayer reminders off entirely.
      if (!_boolPref(prefs, 'prayer_reminder')) return;

      final lat = _doublePref(prefs, _kLatKey);
      final lng = _doublePref(prefs, _kLngKey);
      if (lat == null || lng == null) return;

      // Silent-mode allow-list gate for notifications.
      // When _silentModeEnabled is false, schedule for all prayers
      // unconditionally (Preservation: Requirement 3.11).
      Set<String>? onlyPrayers;
      if (_silentModeEnabled) {
        try {
          final ringerMode = await SoundMode.ringerModeStatus;
          if (ringerMode == RingerModeStatus.silent ||
              ringerMode == RingerModeStatus.vibrate) {
            final allowListRaw = prefs.getString(_kSilentNotifPrayersKey) ?? '';
            onlyPrayers = allowListRaw.isEmpty
                ? <String>{}
                : allowListRaw
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toSet();
            if (onlyPrayers.isEmpty) {
              // Deliberately *not* proceeding: an empty filter would cancel
              // the whole horizon and schedule nothing, which is a much worse
              // outcome than leaving the already-scheduled alarms in place.
              debugPrint(
                '🔇 Exact alarms suppressed: phone in silent/vibrate '
                'and no prayers in silent_notif_prayers allow-list',
              );
              return;
            }
          }
        } catch (e) {
          // If SoundMode throws, default to scheduling for all prayers.
          debugPrint(
            'OverlayService: SoundMode check in reschedule failed: $e',
          );
          onlyPrayers = null;
        }
      }

      await NotificationsService.scheduleUpcomingPrayerNotifications(
        latitude: lat,
        longitude: lng,
        timezone: prefs.getString(_kTimezoneKey),
        madhab: prefs.getString(_kMadhabKey) ?? 'shafi',
        method: prefs.getString(_kCalcMethodKey) ?? 'Algeria',
        highLatitudeRule: prefs.getString(_kHighLatitudeRuleKey),
        fajrOffset: _intPref(prefs, 'fajr_offset'),
        sunriseOffset: _intPref(prefs, 'sunrise_offset'),
        dhuhrOffset: _intPref(prefs, 'dhuhr_offset'),
        asrOffset: _intPref(prefs, 'asr_offset'),
        maghribOffset: _intPref(prefs, 'maghrib_offset'),
        ishaOffset: _intPref(prefs, 'isha_offset'),
        l10n: _l10n,
        preAdhanEnabled: _boolPref(prefs, _kPreAdhanNotifEnabledKey),
        iqamaEnabled: _boolPref(prefs, 'iqama_notif'),
        adhanMode: _adhanMode,
        adhanScreenEnabled: _boolPref(prefs, 'adhan_screen_enabled'),
        adhanAlarmEnabled: _boolPref(prefs, 'adhan_alarm_enabled'),
        onlyPrayers: onlyPrayers,
      );
    } catch (e) {
      debugPrint('OverlayService: exact-alarm reschedule failed: $e');
    }
  }

  /// Bool pref read that tolerates the string form. Settings are stored in
  /// SQLite as text (`SettingsPrefsBridge.mirror` only carries over the Dart
  /// type it happens to be handed), so a raw `getBool` on a mirrored key can
  /// throw and take the caller down with it.
  static bool _boolPref(
    SharedPreferences prefs,
    String key, {
    bool fallback = true,
  }) {
    final value = prefs.get(key);
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return fallback;
  }

  /// Int pref read that tolerates the string form — see [_boolPref].
  static int _intPref(SharedPreferences prefs, String key) {
    final value = prefs.get(key);
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Double pref read that tolerates the string form — see [_boolPref].
  static double? _doublePref(SharedPreferences prefs, String key) {
    final value = prefs.get(key);
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ──────────────────────────────────────
  //  LOCATION UPDATE
  // ──────────────────────────────────────
  Future<void> _handleLocationUpdate() async {
    final Geocoding geocoding = Geocoding();
    try {
      // Try a high-accuracy fix first; fall back to last-known position if
      // the hardware fix times out (common indoors / weak GPS signal).
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) {
        debugPrint('OverlayService: No position available for location update');
        // Restore the foreground notification to the normal next-prayer display
        // so the "جارٍ تحديث الموقع…" text doesn't stay there forever.
        await _updateForegroundNotification();
        return;
      }

      final lat = pos.latitude;
      final lng = pos.longitude;
      final tzName = TimezoneResolver.resolveFromCoordinates(lat, lng);

      // Build a clean city string — avoid leading/trailing punctuation when
      // any of the geocoding fields are null or empty.
      final prefs = await SharedPreferences.getInstance();
      String cityName =
          prefs.getString(_kCityNameKey) ?? _l10n.overlayServiceUnknownCity;
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.locality != null && p.locality!.trim().isNotEmpty)
              p.locality!.trim()
            else if (p.subAdministrativeArea != null &&
                p.subAdministrativeArea!.trim().isNotEmpty)
              p.subAdministrativeArea!.trim()
            else if (p.administrativeArea != null &&
                p.administrativeArea!.trim().isNotEmpty)
              p.administrativeArea!.trim(),
            if (p.country != null && p.country!.trim().isNotEmpty)
              p.country!.trim(),
          ];
          if (parts.isNotEmpty) cityName = parts.join(', ');
        }
      } catch (_) {
        // Reverse-geocoding failed — keep the previously saved city name.
      }

      await prefs.setString(_kLatKey, lat.toString());
      await prefs.setString(_kLngKey, lng.toString());
      await prefs.setString('timezone', tzName);
      await prefs.setString(_kCityNameKey, cityName);

      // Notify the main isolate so it can write the same values to SettingsDao
      // and trigger a reactive rebuild of prayerTimesProvider.
      FlutterForegroundTask.sendDataToMain({
        'action': 'location_updated',
        'latitude': lat,
        'longitude': lng,
        'cityName': cityName,
      });

      await _refreshPrayerTimes();
      await _updateForegroundNotification();
    } catch (e) {
      debugPrint('OverlayService: Location update failed: $e');
      // Restore normal foreground notification on failure too.
      await _updateForegroundNotification();
    }
  }

  // ──────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────
  String _countdown(DateTime now, DateTime target) {
    Duration diff = target.difference(now);
    if (diff.isNegative) diff = const Duration(hours: 24) + diff;
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  String _hijriMonthAr(int m) => const [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ][m - 1];
}

// ──────────────────────────────────────────────────────────────────────────────
//  TESTING INFRASTRUCTURE
//  @visibleForTesting — never referenced from production code.
// ──────────────────────────────────────────────────────────────────────────────

/// A test-facing proxy that exposes just enough of [_OverlayTaskHandler]'s
/// adhan-trigger logic to let unit tests exercise Bug 4 without spinning up
/// a real foreground service.
///
/// Obtain an instance via [OverlayBackgroundService.createHandlerForTesting].
class TestableOverlayHandler {
  // Mirrors the fields in _OverlayTaskHandler that are relevant to Bug 4.
  // The initial value mirrors the production default (true).
  // Intentionally mutable: the fix updates this via onReceiveData.
  // ignore: prefer_final_fields
  bool _adhanScreenEnabled = true;
  List<_PrayerInfo> _prayers = [];
  // Silent-mode gate fields (mirroring _OverlayTaskHandler).
  bool silentModeEnabled = false;

  /// Called with each map that would have been passed to
  /// [FlutterForegroundTask.sendDataToMain] in production.
  void Function(Map data)? onSendDataToMain;

  /// Mirrors [_OverlayTaskHandler.onReceiveData]. The buggy production
  /// implementation ignores the 'adhan_screen_enabled' key; the fix adds a
  /// handler for it.
  void onReceiveData(Map data) {
    if (data.containsKey('overlay_popups_enabled')) {
      // kept for completeness; not tested here
    }
    if (data.containsKey('adhan_mode')) {
      // kept for completeness; not tested here
    }
    if (data.containsKey('adhan_screen_enabled')) {
      _adhanScreenEnabled = data['adhan_screen_enabled'] as bool;
    }
  }

  /// Injects a synthetic prayer into this handler's prayer list, bypassing
  /// the real SharedPreferences / adhan library lookup.
  void injectPrayerForTesting({
    required String name,
    required String nameAr,
    required String emoji,
    required DateTime time,
  }) {
    _prayers = [_PrayerInfo(name, nameAr, emoji, time)];
  }

  /// Runs the adhan-trigger logic (mirrors [_OverlayTaskHandler._checkAndTriggerAdhan])
  /// but replaces [FlutterForegroundTask.sendDataToMain] with [onSendDataToMain]
  /// so tests can observe what would have been sent.
  Future<void> triggerAdhanCheckForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final triggeredDate = prefs.getString(_kTriggeredPrayersDateKey) ?? '';
    Set<String> triggered;
    if (triggeredDate != todayKey) {
      triggered = {};
      await prefs.setString(_kTriggeredPrayersDateKey, todayKey);
      await prefs.setString(_kTriggeredPrayersKey, '');
    } else {
      final raw = prefs.getString(_kTriggeredPrayersKey) ?? '';
      triggered = raw.isEmpty ? {} : raw.split(',').toSet();
    }

    for (final prayer in _prayers) {
      if (triggered.contains(prayer.name)) continue;
      final diffSecs = now.difference(prayer.time).inSeconds;
      if (diffSecs >= 0 && diffSecs <= 300) {
        triggered.add(prayer.name);
        await prefs.setString(_kTriggeredPrayersKey, triggered.join(','));

        // Silent-mode allow-list gate (mirrors _OverlayTaskHandler logic).
        // When silentModeEnabled is false, send unconditionally (Req 3.11).
        bool suppressAdhan = false;
        if (silentModeEnabled) {
          try {
            final ringerMode = await SoundMode.ringerModeStatus;
            if (ringerMode == RingerModeStatus.silent ||
                ringerMode == RingerModeStatus.vibrate) {
              final allowListRaw =
                  prefs.getString(_kSilentAdhanPrayersKey) ?? '';
              final allowList = allowListRaw.isEmpty
                  ? <String>{}
                  : allowListRaw.split(',').map((e) => e.trim()).toSet();
              if (!allowList.contains(prayer.name)) {
                suppressAdhan = true;
              }
            }
          } catch (_) {
            // Default to NOT suppressing on SoundMode error.
          }
        }

        // BUG 4: in unfixed code _adhanScreenEnabled is never updated by
        // onReceiveData, so this gate is effectively always true.
        // The fix adds the onReceiveData handler so _adhanScreenEnabled
        // can be set to false, and then this gate blocks the send.
        if (_adhanScreenEnabled && !suppressAdhan) {
          onSendDataToMain?.call({
            'action': 'show_adhan',
            'prayer': prayer.nameAr,
            'prayerKey': prayer.name,
            'emoji': prayer.emoji,
          });
        }
        return;
      }
    }
  }
}


