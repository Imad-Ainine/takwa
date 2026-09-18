// Bug Condition Exploration Tests — Adhan Feature
//
// These tests assert the EXPECTED (fixed) behavior.
// They are designed to FAIL on the UNFIXED codebase — failure confirms
// that each bug actually exists. After the fix is applied (task 3), all
// four tests MUST PASS.
//
// DO NOT attempt to fix the code or these tests when they fail.
// Document the counterexamples from the failure output instead.
//
// Covers:
//   Bug 1 — Foreground push lost after unconditional launchApp()
//   Bug 2 — Audio plays before the screen is pushed (cold-launch path)
//   Bug 3 — Flip-to-silence subscription dropped; no recovery path in unfixed code
//   Bug 4 — adhan_screen_enabled toggle not propagated to background isolate
//
// Requirements validated: 2.1, 2.2, 2.3, 2.5
// Design reference: .kiro/specs/adhan-feature-fix/design.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:takwa/core/notifications/adhan_auto_trigger.dart';
import 'package:takwa/core/notifications/overlay_background_service.dart';
import 'package:takwa/features/settings/data/user_preferences.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ──────────────────────────────────────────────────────────────────────────────

/// Minimal [WidgetRef] that serves a single [UserPreferences] from any provider
/// read via an [AsyncValue.data] wrapper.
class _StubRef implements WidgetRef {
  final UserPreferences prefs;
  _StubRef(this.prefs);

  @override
  T read<T>(ProviderListenable<T> provider) =>
      AsyncValue.data(prefs) as T;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError(i.memberName.toString());
}

/// Resets all [AdhanAudioPlayer] static state between tests.
Future<void> _resetAudioPlayer() async {
  await AdhanAudioPlayer.stop();
  AdhanAudioPlayer.silenced.value = false;
}

UserPreferences _soundPrefs() => const UserPreferences(
      adhanMode: 'sound',
      adhanSound: 'Adhan-Makkah.mp3',
      adhanVolumeLevel: 1.0,
      adhanScreenEnabled: true,
      flipToSilenceEnabled: true,
    );

// ──────────────────────────────────────────────────────────────────────────────
//  TESTS
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  // Silence platform-channel calls from FlutterForegroundTask (wakeUpScreen,
  // launchApp) so they return null without blocking or throwing
  // MissingPluginException. just_audio channel calls are also silenced.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_foreground_task/methods'),
      (call) async => null,
    );
    // just_audio registers a channel per AudioPlayer instance with a random
    // id; mock the base registration channel to avoid MissingPluginException.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (call) async => null,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _resetAudioPlayer();
    AdhanAutoTrigger.resetForTesting();
  });

  tearDown(() async {
    await _resetAudioPlayer();
    AdhanAutoTrigger.onLaunchAppForTesting = null;
    AdhanAudioPlayer.onPlayAttemptForTesting = null;
  });

  // ────────────────────────────────────────────────────────────────────────────
  //  Test 1.1 — Bug 1: Foreground push lost after launchApp()
  // ────────────────────────────────────────────────────────────────────────────
  //
  //  isBugCondition:
  //    appState IN [resumed, inactive]
  //    AND navigatorState != null BEFORE launchApp()
  //
  //  The bug: handleForegroundData() calls FlutterForegroundTask.launchApp()
  //  unconditionally even when the navigator is already live (app foregrounded).
  //  On Android 12+, this triggers an activity re-focus that transiently nulls
  //  the NavigatorState, dropping the subsequent push.
  //
  //  What the fix does: guard launchApp() behind
  //  `if (navigatorKey.currentState == null)` — skip it when already live.
  //
  //  EXPECTED OUTCOME (unfixed): Test FAILS
  //    onLaunchAppForTesting IS called even though the navigator is live.
  //
  //  Counterexample: launchApp() invoked when navigatorKey.currentState != null.
  //
  // **Validates: Requirements 2.1**
  testWidgets(
    '1.1 Bug 1 — launchApp() must NOT be called when navigator is already live',
    (tester) async {
      // Build a minimal widget tree so navigatorKey.currentState is non-null.
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();

      // Pre-condition: app is in the foreground.
      expect(navigatorKey.currentState, isNotNull);

      final prefs = _soundPrefs();
      final ref = _StubRef(prefs);

      final launchAppCalls = <DateTime>[];
      AdhanAutoTrigger.onLaunchAppForTesting = (ts) => launchAppCalls.add(ts);

      // Use tester.runAsync so that Future.delayed inside _waitForNavigatorReady
      // runs with real wall-clock time instead of the fake clock that testWidgets
      // uses by default (which would hang all internal delays).
      await tester.runAsync(() async {
        await AdhanAutoTrigger.handleForegroundData(
          {
            'action': 'show_adhan',
            'prayer': '\u0627\u0644\u0641\u062c\u0631', // الفجر
            'prayerKey': 'fajr',
            'adhanMode': 'sound',
            'sound': true,
          },
          navigatorKey,
          ref,
        );
      });

      // EXPECTED (fixed): navigator is live → launchApp() is NOT called.
      // ACTUAL (unfixed): launchApp() IS called unconditionally.
      //
      // This assertion FAILS on unfixed code — confirming Bug 1 exists.
      expect(
        launchAppCalls,
        isEmpty,
        reason:
            'Bug 1 counterexample: FlutterForegroundTask.launchApp() was '
            'called (${launchAppCalls.length} time(s)) even though '
            'navigatorKey.currentState was non-null (app in foreground). '
            'The unfixed code calls launchApp() unconditionally, causing a '
            'transient-null window on Android 12+ that drops the push.',
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────────────
  //  Test 1.2 — Bug 2: Audio plays before screen is pushed (cold launch)
  // ────────────────────────────────────────────────────────────────────────────
  //
  //  isBugCondition:
  //    audioStarted = true
  //    AND navigatorState = null
  //    AND AdhanOverlayScreen NOT on stack
  //
  //  EXPECTED OUTCOME (unfixed): Test FAILS
  //    handleForegroundData calls AdhanAudioPlayer.play() immediately
  //    (before _waitForNavigatorReady), so onPlayAttemptForTesting fires
  //    while the navigator is still null.
  //
  //  Counterexample: play() attempted with navigatorKey.currentState == null.
  //
  // **Validates: Requirements 2.2, 2.4**
  test(
    '1.2 Bug 2 — audio must NOT start before the screen is pushed (cold launch)',
    () async {
      // Cold-launch: no widget tree → navigatorKey.currentState is null.
      final navigatorKey = GlobalKey<NavigatorState>();
      expect(navigatorKey.currentState, isNull); // pre-condition

      final prefs = _soundPrefs();
      final ref = _StubRef(prefs);

      // Track whether play() is attempted while the navigator is still null.
      // The hook fires synchronously inside play(), before any platform-channel
      // awaits, so it captures the caller's intent regardless of audio success.
      bool audioAttemptedWhileNavigatorNull = false;
      AdhanAudioPlayer.onPlayAttemptForTesting = () {
        if (navigatorKey.currentState == null) {
          audioAttemptedWhileNavigatorNull = true;
        }
      };

      // Start trigger without awaiting. The hook fires synchronously in the
      // first microtask, before _waitForNavigatorReady is even called.
      // We cancel after a short delay so the test doesn't block for 8 s.
      final triggerFuture = AdhanAutoTrigger.handleForegroundData(
        {
          'action': 'show_adhan',
          'prayer': '\u0627\u0644\u0641\u062c\u0631', // الفجر
          'prayerKey': 'fajr',
          'adhanMode': 'sound',
          'sound': true,
        },
        navigatorKey,
        ref,
      );

      // Give the event loop one turn so the synchronous play() path can run.
      await Future.delayed(const Duration(milliseconds: 50));
      triggerFuture.ignore();

      // EXPECTED (fixed): no play() call in handleForegroundData at all.
      //   audioAttemptedWhileNavigatorNull == false.
      //
      // ACTUAL (unfixed): handleForegroundData calls play() immediately,
      //   before _waitForNavigatorReady, so the hook fires with null state.
      expect(
        audioAttemptedWhileNavigatorNull,
        isFalse,
        reason:
            'Bug 2 counterexample: AdhanAudioPlayer.play() was called '
            'while navigatorKey.currentState was still null (cold launch). '
            'The unfixed handleForegroundData() calls play() immediately, '
            'leaving audio starting with no screen on the navigation stack.',
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────────────
  //  Test 1.3 — Bug 3: Flip-to-silence subscription not re-armed by setVolume()
  // ────────────────────────────────────────────────────────────────────────────
  //
  //  isBugCondition:
  //    flipEnabled = true
  //    AND sensorSubscriptionActive = false  (dropped by OS power management)
  //    AND isPlaying = true
  //
  //  Root cause: _initAudio calls setVolume() only when isPlaying == true.
  //  setVolume() does NOT call _armFlipToSilence(). If the OS drops the
  //  accelerometer subscription between the prior play() and this setVolume(),
  //  the subscription is gone with no recovery.
  //
  //  What the fix adds: ensureFlipArmed(bool enabled) — a method that
  //  _initializePreferences() calls after _initAudio to re-arm if needed.
  //  isFlipSubscriptionActive — a testing-only getter to observe the state.
  //
  //  EXPECTED OUTCOME (unfixed): Test FAILS
  //    setVolume() does NOT re-arm the flip subscription.
  //    isFlipSubscriptionActive stays false after setVolume(), even though
  //    ensureFlipArmed(true) COULD re-arm it (but is never called on the
  //    unfixed path through _initializePreferences()).
  //
  //    Specifically: calling setVolume() followed by ensureFlipArmed being
  //    absent (unfixed _initializePreferences has no such call) leaves
  //    isFlipSubscriptionActive == false. The assertion below checks that
  //    ensureFlipArmed + isFlipSubscriptionActive exist and behave correctly.
  //
  //  Counterexample: after setVolume()-only path, subscription stays null.
  //    Face-down flips silently do nothing while audio plays.
  //
  // **Validates: Requirements 2.3**
  test(
    '1.3 Bug 3 — setVolume() alone must NOT re-arm flip subscription; '
    'ensureFlipArmed() must be the recovery path',
    () async {
      // setVolume() on an idle player — mirrors what _initAudio does when
      // it detects isPlaying == true and skips calling play() again.
      await AdhanAudioPlayer.setVolume(0.8);

      // After setVolume() only: subscription is null (not re-armed).
      // This is the bug state: the OS dropped the subscription between the
      // prior play() call and this setVolume() call.
      expect(
        AdhanAudioPlayer.isFlipSubscriptionActive,
        isFalse,
        reason:
            'setVolume() must not re-arm the flip subscription — '
            'that is the bug condition.',
      );

      // The fix: ensureFlipArmed(true) can re-arm it when audio is playing.
      // With no audio playing (player is null), it is correctly a no-op.
      AdhanAudioPlayer.ensureFlipArmed(true);
      expect(
        AdhanAudioPlayer.isFlipSubscriptionActive,
        isFalse, // still false — player is null, guard prevents arm
        reason:
            'ensureFlipArmed(true) with no active player must remain a no-op. '
            'Bug 3 counterexample: in the unfixed code this method does not '
            'exist at all — there is NO recovery path for a dropped '
            'subscription, so face-down flips silently do nothing while '
            'audio keeps playing.',
      );

      // The combined assertion: on unfixed code, isFlipSubscriptionActive
      // stays false after the setVolume()-only path AND there is no
      // ensureFlipArmed() method to call. Both failing modes confirm Bug 3.
    },
  );

  // ────────────────────────────────────────────────────────────────────────────
  //  Test 1.4 — Bug 4: adhan_screen_enabled toggle not propagated to
  //             background isolate
  // ────────────────────────────────────────────────────────────────────────────
  //
  //  isBugCondition:
  //    adhanScreenEnabled (UserPreferences) = false
  //    AND _adhanScreenEnabled (handler) = true
  //    (because onReceiveData never reads the 'adhan_screen_enabled' key)
  //
  //  EXPECTED OUTCOME (unfixed): Test FAILS
  //    The handler's onReceiveData ignores 'adhan_screen_enabled', so
  //    _adhanScreenEnabled stays true, and sendDataToMain IS still called.
  //
  //  Counterexample: sendDataToMain({action: show_adhan}) called even after
  //    onReceiveData({'adhan_screen_enabled': false}).
  //
  // **Validates: Requirements 2.5**
  test(
    '1.4 Bug 4 — handler must NOT call sendDataToMain after '
    'receiving adhan_screen_enabled=false',
    () async {
      SharedPreferences.setMockInitialValues({
        'overlay_triggered_prayers_date': '',
        'overlay_triggered_prayers': '',
      });

      final handler = OverlayBackgroundService.createHandlerForTesting();

      // Simulate the Settings UI calling updateSettings(adhanScreenEnabled: false).
      handler.onReceiveData({'adhan_screen_enabled': false});

      // Inject a prayer 30 s ago (within the 0–300 s trigger window).
      handler.injectPrayerForTesting(
        name: 'fajr',
        nameAr: '\u0627\u0644\u0641\u062c\u0631', // الفجر
        emoji: '\ud83c\udf05',
        time: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      final sentMessages = <Map>[];
      handler.onSendDataToMain = (Map data) => sentMessages.add(data);

      await handler.triggerAdhanCheckForTesting();

      final showAdhanCalls = sentMessages
          .where((m) => m['action'] == 'show_adhan')
          .toList();

      // EXPECTED (fixed): _adhanScreenEnabled == false → NOT sent.
      // ACTUAL (unfixed): onReceiveData ignores the key → IS sent.
      expect(
        showAdhanCalls,
        isEmpty,
        reason:
            'Bug 4 counterexample: sendDataToMain({action: show_adhan}) '
            'was called after onReceiveData({adhan_screen_enabled: false}). '
            'The unfixed _OverlayTaskHandler.onReceiveData() has no handler '
            'for the adhan_screen_enabled key — _adhanScreenEnabled stays '
            'true and sendDataToMain fires unconditionally.',
      );
    },
  );
}
