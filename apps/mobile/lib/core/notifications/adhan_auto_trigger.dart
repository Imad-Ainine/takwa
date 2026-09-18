import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

import '../routes/app_routes.dart';
import 'notifications_service.dart';
import '../../features/settings/providers/user_preferences_provider.dart';
import '../../features/settings/data/user_preferences.dart';

class AdhanAudioPlayer {
  static AudioPlayer? _player;
  static bool _isPlaying = false;

  // Flip-to-silence used to live entirely inside AdhanOverlayScreen's
  // State, so it only ever worked when that widget actually got mounted.
  // But playback here is started independently by AdhanAutoTrigger
  // (_check()/handleForegroundData()) *before* — and sometimes instead of
  // — the screen route lands (see the navigator-ready retry below): if
  // the push silently failed to land (the old flat 300ms delay, a
  // backgrounded app, a cold-launch race), audio would play with no
  // sensor listener anywhere, so flipping the phone did nothing. Owning
  // the accelerometer here ties "can the user silence it by flipping"
  // directly to "is Adhan audio playing" — the actual contract of the
  // feature — instead of to whether a particular screen happened to build.
  static StreamSubscription<AccelerometerEvent>? _flipSub;

  /// Whether to also switch the phone to silent mode when a flip is detected.
  /// Stored here (set by [play]/[ensureFlipArmed]) so [_silenceViaFlip] can
  /// act on it without needing a BuildContext or Riverpod ref.
  static bool _flipSilencePhone = false;

  /// True once flip-to-silence has fired for the currently playing Adhan.
  /// AdhanOverlayScreen listens to this instead of running its own sensor
  /// subscription, so the UI reflects a flip even if it happened before
  /// (or without) the screen ever mounting.
  static final ValueNotifier<bool> silenced = ValueNotifier(false);

  static Future<void> play({
    String asset = 'assets/sounds/Adhan-Makkah.mp3',
    double volume = 1.0,
    bool flipToSilenceEnabled = true,
    bool flipSilencePhone = false,
  }) async {
    try {
      await stop();
      silenced.value = false;
      _flipSilencePhone = flipSilencePhone;
      onPlayAttemptForTesting?.call();
      _player = AudioPlayer();
      await _player!.setVolume(volume);
      await _player!.setAsset(asset);
      _player!.playerStateStream.listen((state) {
        _isPlaying = state.playing;
      });
      await _player!.play();
      _isPlaying = true;
      if (flipToSilenceEnabled) _armFlipToSilence();
    } catch (e) {
      debugPrint('AdhanAudio: play error: $e');
    }
  }

  static void _armFlipToSilence() {
    _flipSub?.cancel();
    _flipSub = accelerometerEventStream().listen((event) {
      // Z axis strongly negative = face-down (gravity vector pointing up).
      // Threshold -8.0 m/s² (~0.82 g) is well below the ±9.8 full-flip
      // signal while ignoring normal landscape tilts (~±5 m/s²). Same
      // threshold AdhanOverlayScreen used to apply itself.
      if (event.z < -8.0) _silenceViaFlip();
    });
  }

  /// Called when the accelerometer detects a face-down flip while the Adhan
  /// is playing.
  ///
  /// **Reentrancy fix:** this method is invoked from inside the accelerometer
  /// stream listener callback. The old code called `await stop()` directly,
  /// and `stop()` does `await _flipSub?.cancel()`. Awaiting a subscription's
  /// cancel() from within its own dispatch callback deadlocks on some
  /// platforms — the cancel waits for the current event delivery to finish,
  /// which is blocked waiting for the cancel. The fix is to:
  ///   1. Grab and null out `_flipSub` synchronously before any await, so
  ///      `stop()` sees null and skips the cancel entirely.
  ///   2. Cancel the old subscription asynchronously (fire-and-forget) so it
  ///      eventually cleans up without blocking the current execution.
  static Future<void> _silenceViaFlip() async {
    if (silenced.value) return; // already silenced this Adhan — guard against
    // repeated calls while the phone stays face-down (stream fires ~50 Hz).
    silenced.value = true;

    // Detach and cancel the subscription outside stop() to avoid the
    // reentrancy deadlock described above.
    final sub = _flipSub;
    _flipSub = null;
    sub?.cancel(); // fire-and-forget: no await

    // Stop audio (stop() will see _flipSub == null and skip its own cancel).
    await stop();

    // Haptic confirmation — let the user know the flip worked.
    HapticFeedback.mediumImpact();

    // Optionally switch the phone ringer to silent so the rest of the
    // prayer time stays quiet (controlled by the "auto-silent after adhan"
    // preference, stored in _flipSilencePhone when play() was called).
    if (_flipSilencePhone) {
      try {
        await SoundMode.setSoundMode(RingerModeStatus.silent);
        debugPrint('🔇 Flip-to-silence: phone switched to silent mode.');
      } catch (e) {
        debugPrint('❌ Flip-to-silence: could not set silent mode: $e');
      }
    }
  }

  static Future<void> setVolume(double volume) async {
    if (_player != null) {
      await _player!.setVolume(volume);
    }
  }

  static Future<void> stop() async {
    await _flipSub?.cancel();
    _flipSub = null;
    try {
      if (_player != null) {
        await _player!.stop();
        await _player!.dispose();
        _player = null;
        _isPlaying = false;
      }
    } catch (e) {
      debugPrint('AdhanAudio: stop error: $e');
    }
  }

  static bool get isPlaying => _isPlaying;

  /// Testing hook: called whenever [play] is about to start audio.
  /// Null in production. Set by tests to track when audio starts.
  @visibleForTesting
  static void Function()? onPlayAttemptForTesting;

  /// Whether the flip-to-silence accelerometer subscription is currently
  /// active. Exposed for testing — production code must not depend on this.
  @visibleForTesting
  static bool get isFlipSubscriptionActive => _flipSub != null;

  /// Re-arms the flip-to-silence accelerometer subscription if [enabled] is
  /// true, audio is currently playing, and the subscription is not already
  /// active. Safe no-op in all other cases.
  ///
  /// Call this from [AdhanOverlayScreen._initializePreferences] immediately
  /// after `await _initAudio(prefs)` to close the gap where:
  ///   1. [AdhanAutoTrigger._check] calls [play] (arms subscription),
  ///   2. [AdhanOverlayScreen._initAudio] sees [isPlaying] == true and only
  ///      calls [setVolume] (does NOT re-arm),
  ///   3. the OS briefly pauses the accelerometer between steps 1 and 2 —
  ///      from this point on, flipping the phone does nothing.
  static void ensureFlipArmed(bool enabled, {bool flipSilencePhone = false}) {
    if (!enabled) return;
    // Update the ringer-change preference even when already armed — the
    // overlay screen knows the live pref value; AdhanAutoTrigger._check
    // may have called play() before the screen mounted and may not have had
    // the pref yet.
    _flipSilencePhone = flipSilencePhone;
    if (_flipSub != null) return; // already armed
    if (_player == null || !_isPlaying) return; // nothing playing to arm
    _armFlipToSilence();
  }
}

class AdhanAutoTrigger {
  static Timer? _checkTimer;
  // Key is '<prayerName>_<dayOfYear>' — unique per prayer per day.
  static String? _lastTriggeredPrayer;
  // Guards concurrent executions: avoids stacking multiple async _check
  // calls when the provider is slow to resolve on the first tick.
  static bool _checking = false;

  /// Testing hook: called whenever [FlutterForegroundTask.launchApp] is about
  /// to be invoked. Null in production (default), set by tests to track calls.
  @visibleForTesting
  static void Function(DateTime)? onLaunchAppForTesting;

  /// Resets in-memory state between tests. Never call from production code.
  @visibleForTesting
  static void resetForTesting() {
    _lastTriggeredPrayer = null;
    _checking = false;
    onLaunchAppForTesting = null;
    AdhanAudioPlayer.onPlayAttemptForTesting = null;
  }

  // Same SharedPreferences keys/format `OverlayBackgroundService` uses for
  // its own per-prayer-per-day dedupe (`_kTriggeredPrayersKey`/
  // `_kTriggeredPrayersDateKey`, format `'$year-$month-$day'` with no
  // zero-padding — kept identical on purpose, not just similar). Reading
  // and writing the *same* keys (SharedPreferences is native platform
  // storage, so both isolates genuinely see each other's writes) closes the
  // remaining gap from docs/specs/adhan-overlay-auto-open.md R7: previously
  // `_lastTriggeredPrayer` (this isolate, in-memory, reset on every app
  // restart) and the background isolate's persisted set were two entirely
  // separate stores that could disagree — e.g. after the main isolate
  // restarts mid-window, it had no way to know the background isolate
  // already fired for a prayer today, or vice versa.
  static const _kTriggeredPrayersKey = 'overlay_triggered_prayers';
  static const _kTriggeredPrayersDateKey = 'overlay_triggered_prayers_date';

  static String _sharedDateKey(DateTime dt) =>
      '${dt.year}-${dt.month}-${dt.day}';

  /// Whether [prayerName] (the internal id, e.g. 'fajr') was already marked
  /// triggered today by *either* isolate.
  static Future<bool> _alreadyTriggeredSharedly(String prayerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _sharedDateKey(DateTime.now());
      if ((prefs.getString(_kTriggeredPrayersDateKey) ?? '') != todayKey) {
        return false;
      }
      final raw = prefs.getString(_kTriggeredPrayersKey) ?? '';
      return raw.isNotEmpty && raw.split(',').contains(prayerName);
    } catch (e) {
      // SharedPreferences unavailable — fall back to this isolate's own
      // in-memory guard only, same as before this fix existed.
      debugPrint('AdhanAutoTrigger: shared dedupe read failed: $e');
      return false;
    }
  }

  /// Marks [prayerName] triggered today in the store shared with
  /// `OverlayBackgroundService`.
  static Future<void> _markTriggeredSharedly(String prayerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _sharedDateKey(DateTime.now());
      Set<String> triggered;
      if ((prefs.getString(_kTriggeredPrayersDateKey) ?? '') != todayKey) {
        triggered = {};
        await prefs.setString(_kTriggeredPrayersDateKey, todayKey);
      } else {
        final raw = prefs.getString(_kTriggeredPrayersKey) ?? '';
        triggered = raw.isEmpty ? {} : raw.split(',').toSet();
      }
      triggered.add(prayerName);
      await prefs.setString(_kTriggeredPrayersKey, triggered.join(','));
    } catch (e) {
      debugPrint('AdhanAutoTrigger: shared dedupe write failed: $e');
    }
  }

  /// يبدأ مراقبة أوقات الصلاة كل ثانية بدقة عالية
  static void start(WidgetRef ref, GlobalKey<NavigatorState> navigatorKey) {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _check(ref, navigatorKey);
    });
  }

  static void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    AdhanAudioPlayer.stop();
  }

  /// Unique key per prayer per calendar day, shared by [_check] and
  /// [handleForegroundData] so they claim the same [_lastTriggeredPrayer]
  /// slot instead of deduplicating independently. See the audit note on
  /// [handleForegroundData] for why this matters.
  static String _dailyKey(String prayerName, DateTime now) =>
      '${prayerName}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

  static Future<void> _check(
    WidgetRef ref,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (_checking) return; // prevent overlapping async calls
    _checking = true;
    try {
      final prayers = ref.read(prayerTimesProvider).value;
      if (prayers == null) return;

      // Read preferences synchronously from the cached value to avoid a
      // per-second async database hit. Fall back to the future only if the
      // value has not loaded yet (first launch).
      final UserPreferences prefs =
          ref.read(userPreferencesProvider).valueOrNull ??
          await ref.read(userPreferencesProvider.future);

      final adhanScreen = prefs.adhanScreenEnabled;

      final now = DateTime.now();
      for (final prayer in prayers) {
        final diffSecs = now.difference(prayer.time).inSeconds;
        // Trigger window: from prayer time up to 10 minutes after. Was 3
        // minutes, meant to survive the app being momentarily backgrounded
        // at the exact second — but this timer only runs at all while the
        // main isolate is alive and this widget mounted, so the common real
        // case is a user reopening the app *after* missing the prayer by a
        // few minutes (screen was off, phone was in a pocket, etc.); a
        // 3-minute tail missed that reopen more often than not, leaving the
        // Adhan silently never announced for that prayer at all. Widened to
        // roughly match the shortest iqama gap (5 min for Maghrib) so it's
        // still meaningful to show/play when caught late.
        if (diffSecs < 0 || diffSecs > 600) continue;

        // Unique key per prayer per calendar day — the only deduplication
        // guard needed. The old 30-minute cross-prayer wall was removed
        // because it blocked a prayer that falls within 30 min of the
        // previous one (e.g., Dhuhr at 13:00 and Asr at 13:20 in summer).
        final key = _dailyKey(prayer.name, now);
        if (_lastTriggeredPrayer == key) continue;

        // R7: also defer to the store shared with the background isolate —
        // catches the case where *this* isolate just (re)started (so its
        // own in-memory `_lastTriggeredPrayer` is empty) but the background
        // isolate already fired for this prayer today.
        if (await _alreadyTriggeredSharedly(prayer.name)) {
          _lastTriggeredPrayer = key;
          continue;
        }

        // Guard: don't push the Adhan screen if it's already on top.
        final nav = navigatorKey.currentState;
        bool adhanAlreadyVisible = false;
        if (nav != null) {
          nav.popUntil((route) {
            if (route.settings.name == Routes.adhan) {
              adhanAlreadyVisible = true;
            }
            return true; // never actually pop anything
          });
        }

        _lastTriggeredPrayer = key;
        await _markTriggeredSharedly(prayer.name);

        debugPrint('🕌 Auto-trigger adhan: ${prayer.nameAr}');

        // فتح شاشة الأذان
        if (adhanScreen && !adhanAlreadyVisible) {
          // wakeUpScreen() is always safe: it is a no-op when the screen is
          // already on. launchApp() is only needed when the app is
          // backgrounded/killed (navigatorKey.currentState == null); calling
          // it unconditionally when the app is already in the foreground
          // causes a brief activity re-focus on Android 12+ that transiently
          // nulls the NavigatorState, which then drops the push silently.
          FlutterForegroundTask.wakeUpScreen();
          if (navigatorKey.currentState == null) {
            FlutterForegroundTask.launchApp();
            onLaunchAppForTesting?.call(DateTime.now());
          }
          // Used to bail out here entirely if `navigatorKey.currentContext`
          // was null at this exact instant, with no retry — a real gap
          // whenever the widget tree wasn't built yet (e.g. right after
          // the app was momentarily backgrounded), silently dropping the
          // Adhan screen for that prayer for the rest of the day. Poll
          // instead of taking one snapshot.
          await _waitForNavigatorReady(navigatorKey);
          navigatorKey.currentState?.pushNamed(
            Routes.adhan,
            arguments: prayer.nameAr,
          );
        }

        break;
      }
    } catch (e) {
      debugPrint('AdhanAutoTrigger: error: $e');
    } finally {
      _checking = false;
    }
  }

  /// يُستدعى من foreground task عند استلام بيانات الأذان
  ///
  /// This and [_check] are two independent triggers for the *same* event
  /// (a prayer starting) that can both be live at once — the background
  /// foreground-task isolate is started on every app open
  /// (`OverlayBackgroundService.start()` in main_shell.dart/home_screen.dart)
  /// right alongside this class's own 1s foreground timer, so in ordinary
  /// use both are usually polling simultaneously. Each used to dedupe
  /// independently — [_check] via the in-memory [_lastTriggeredPrayer], this
  /// method only via a live scan of the navigator stack for `Routes.adhan`
  /// — which left a real race: both push after their own 300ms
  /// `Future.delayed`, so if this method's scan ran *before* [_check]'s
  /// delayed push had actually landed, it would see no Adhan screen yet and
  /// push a second one. Both now claim the same [_lastTriggeredPrayer] slot
  /// synchronously, before either awaits anything, so whichever runs first
  /// wins and the other returns immediately. See
  /// docs/specs/adhan-overlay-auto-open.md R7.
  static Future<void> handleForegroundData(
    Map data,
    GlobalKey<NavigatorState> navigatorKey,
    WidgetRef ref,
  ) async {
    final action = data['action'];
    if (action != 'show_adhan') return;

    // Claim the shared per-prayer-per-day slot before doing anything else
    // (in particular, before the `await` a few lines down) so this and
    // [_check] can't both slip past their guards in the same race window.
    // `prayerKey` (the internal 'fajr'/'dhuhr'/... id, not the Arabic
    // display name) is only present once overlay_background_service.dart
    // sends it — absent, this falls back to the pre-existing
    // navigator-stack-only guard below, same as before this fix.
    final prayerKey = data['prayerKey'] as String?;
    if (prayerKey != null) {
      final key = _dailyKey(prayerKey, DateTime.now());
      if (_lastTriggeredPrayer == key) return;
      _lastTriggeredPrayer = key;
    }

    final prayerName = (data['prayer'] as String?) ?? 'الصلاة';

    // Prefer the live Riverpod value (already cached); only await if loading.
    final UserPreferences prefs =
        ref.read(userPreferencesProvider).valueOrNull ??
        await ref.read(userPreferencesProvider.future);

    final adhanScreen = prefs.adhanScreenEnabled;

    if (adhanScreen) {
      // wakeUpScreen() is always safe (no-op when screen is on).
      // launchApp() is only needed when the app is backgrounded/killed;
      // skip it when the navigator is already live to avoid the transient-null
      // window that drops the push on Android 12+.
      FlutterForegroundTask.wakeUpScreen();
      if (navigatorKey.currentState == null) {
        FlutterForegroundTask.launchApp();
        onLaunchAppForTesting?.call(DateTime.now());
      }
      // Guard: don't push on top of an already-visible Adhan screen.
      bool adhanAlreadyVisible = false;
      navigatorKey.currentState?.popUntil((route) {
        if (route.settings.name == Routes.adhan) adhanAlreadyVisible = true;
        return true;
      });

      if (!adhanAlreadyVisible) {
        // This is the path that follows a cold launch (FlutterForegroundTask.
        // launchApp() above, when the app was fully killed) — exactly when a
        // flat 300ms wait is least likely to be enough for the navigator to
        // exist yet. Poll instead of guessing a fixed delay.
        await _waitForNavigatorReady(navigatorKey);
        try {
          navigatorKey.currentState?.pushNamed(
            Routes.adhan,
            arguments: prayerName,
          );
        } catch (e) {
          debugPrint('AdhanAutoTrigger: pushNamed failed: $e');
        }
      }
    }
  }

  /// Polls for the app's navigator to be ready to accept a route push,
  /// instead of a single fixed delay. Needed because both callers above
  /// may run right after `FlutterForegroundTask.launchApp()` cold-starts
  /// the app (or right as it's resumed from background) — cases where
  /// how long the widget tree takes to build varies and can easily exceed
  /// a flat 300ms, which previously meant the push was silently skipped
  /// (or, in [_check]'s case, never even attempted) with no retry, so the
  /// Adhan screen just didn't appear for that prayer.
  static Future<void> _waitForNavigatorReady(
    GlobalKey<NavigatorState> navigatorKey, {
    Duration timeout = const Duration(seconds: 8),
    Duration pollEvery = const Duration(milliseconds: 200),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (navigatorKey.currentState == null) {
      if (DateTime.now().isAfter(deadline)) return;
      await Future.delayed(pollEvery);
    }
    // One extra frame gap even once the state exists, matching the
    // original intent of the flat delay (let the first frame settle)
    // without the fixed-timeout failure mode.
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

class AdhanScreenController {
  static final _instance = AdhanScreenController._();
  AdhanScreenController._();
  static AdhanScreenController get instance => _instance;

  final ValueNotifier<bool> isAdhanPlaying = ValueNotifier(false);
  final ValueNotifier<String?> currentPrayerName = ValueNotifier(null);

  Future<void> onAdhanScreenOpened(String prayerName) async {
    currentPrayerName.value = prayerName;
    isAdhanPlaying.value = true;
    if (!AdhanAudioPlayer.isPlaying) {
      await AdhanAudioPlayer.play();
    }
  }

  Future<void> onAdhanScreenClosed() async {
    currentPrayerName.value = null;
    isAdhanPlaying.value = false;
    await AdhanAudioPlayer.stop();
  }

  Future<void> stopAdhan() async {
    isAdhanPlaying.value = false;
    await AdhanAudioPlayer.stop();
  }
}

mixin AdhanAutoMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void initAdhanAuto(GlobalKey<NavigatorState> navigatorKey) {
    AdhanAutoTrigger.start(ref, navigatorKey);
  }

  @override
  void dispose() {
    AdhanAutoTrigger.stop();
    super.dispose();
  }

  /// استدعِ هذا من _onAdhanData في TakwaApp
  Future<void> handleAdhanData(
    Map data,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    await AdhanAutoTrigger.handleForegroundData(data, navigatorKey, ref);
  }
}
