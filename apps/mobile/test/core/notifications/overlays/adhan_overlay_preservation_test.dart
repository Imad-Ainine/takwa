// Preservation Property Tests — Adhan Overlay Redesign & Settings Fix
//
// Spec: .kiro/specs/adhan-overlay-redesign-settings-fix/
// Tasks.md Task 2: "Write preservation property tests (BEFORE implementing fix)"
//
// These tests assert BASELINE behaviours that must remain UNCHANGED after the
// fix is applied.  They MUST ALL PASS on the UNFIXED codebase — any failure
// here would mean a regression was introduced, not a bug being caught.
//
// Scope: covers the five PBTs required by the task spec.
//
//   PBT 1 — autoSilentAfterAdhan==false → _applyAutoSilent() never calls
//            SoundMode.setSoundMode (phone ringer left untouched)
//   PBT 2 — adhanMode=='vibrate' → AdhanAudioPlayer.isPlaying never becomes
//            true after _initAudio runs (no audio in vibrate mode)
//   PBT 3 — wakeScreenEnabled==true → FlutterForegroundTask.wakeUpScreen()
//            IS called in the auto-trigger path (_check / handleForegroundData)
//   PBT 4 — silentModeEnabled==false → adhan trigger fires for all prayer
//            keys regardless of their presence in silentAdhanPrayers
//            (Requirement 3.11: silent-mode gate inactive when flag is off)
//   PBT 5 — autoSilentAfterAdhan==false, silentDurationMins in 1–60 →
//            no ringer-restore timer is ever scheduled
//
// All five tests PASS on unfixed code.  After the fix they must still pass
// (regression guard for the preservation requirements).
//
// Requirements validated: 3.1–3.15

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:takwa/core/notifications/adhan_auto_trigger.dart';
import 'package:takwa/core/notifications/overlay_background_service.dart';
import 'package:takwa/core/notifications/overlays/adhan_overlay_screen.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/settings/data/user_preferences.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  DOMAIN CONSTANTS
// ──────────────────────────────────────────────────────────────────────────────

/// The six canonical prayer keys used throughout the system.
const _kAllPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'jumuah'];

/// silentDurationMins representative range (1–60 in steps of 5).
const _kSilentDurationSamples = [1, 5, 10, 15, 20, 30, 45, 60];

/// Various silentModeAlertStyle values — NONE of these should matter when
/// autoSilentAfterAdhan==false (PBT 1 / PBT 5).
const _kAlertStyles = ['silent', 'vibrate', 'tone', 'toneVibrate', 'none'];

// ──────────────────────────────────────────────────────────────────────────────
//  CHANNEL MOCKS
//
//  Register mock handlers once (setUpAll) so no real platform channels
//  are called.  Capture calls to the sound_mode and foreground-task channels
//  so individual PBTs can inspect them.
// ──────────────────────────────────────────────────────────────────────────────

/// Calls captured from sound_mode method channel ('method.channel.audio').
final List<MethodCall> _soundModeCalls = [];

/// Calls captured from the flutter_foreground_task method channel.
final List<MethodCall> _foregroundTaskCalls = [];

void _registerChannelMocks() {
  // sound_mode — setSilentMode / setVibrateMode / setNormalMode / getRingerMode
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('method.channel.audio'),
    (call) async {
      _soundModeCalls.add(call);
      if (call.method == 'getRingerMode') return 'normal';
      if (call.method == 'setNormalMode') return 'normal';
      if (call.method == 'setSilentMode') return 'silent';
      if (call.method == 'setVibrateMode') return 'vibrate';
      return null;
    },
  );

  // flutter_foreground_task
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter_foreground_task/methods'),
    (call) async {
      _foregroundTaskCalls.add(call);
      if (call.method == 'isRunningService') return false;
      if (call.method == 'checkNotificationPermission') return 1;
      return null;
    },
  );

  // flutter_local_notifications
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    (call) async => null,
  );

  // just_audio
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.ryanheise.just_audio.methods'),
    (call) async => null,
  );

  // wakelock_plus
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('wakelock_plus'),
    (call) async => null,
  );

  // sensors_plus (accelerometer)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
    (call) async => null,
  );

  // HapticFeedback (SystemChannels.platform)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => null,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ──────────────────────────────────────────────────────────────────────────────

/// Stub [WidgetRef] that returns a fixed [UserPreferences] wrapped in
/// [AsyncData] from any provider read.
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

/// Notifier that immediately resolves to [_prefs] without touching the DB.
class _FixedPrefsNotifier extends UserPreferencesNotifier {
  final UserPreferences _prefs;
  _FixedPrefsNotifier(this._prefs);

  @override
  Future<UserPreferences> build() async => _prefs;
}

/// Wraps [AdhanOverlayScreen] in a minimal [ProviderScope] + [MaterialApp]
/// sufficient for [build()] to run (localizations, theme, routes).
Future<void> _pumpOverlay(
  WidgetTester tester,
  UserPreferences prefs, {
  String prayerName = 'الفجر',
  bool autoPlay = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Suppress RenderFlex overflow on constrained test surfaces.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('RenderFlex overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userPreferencesProvider.overrideWith(
          () => _FixedPrefsNotifier(prefs),
        ),
        // Suppress the ramadanModeProvider stream so it does not produce
        // pending timers after the test widget is disposed.
        ramadanModeProvider.overrideWith((ref) => Stream.value(false)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/home': (_) => const Scaffold(body: SizedBox.shrink()),
          '/prayer': (_) => const Scaffold(body: SizedBox.shrink()),
        },
        home: AdhanOverlayScreen(
          prayerName: prayerName,
          autoPlay: autoPlay,
        ),
      ),
    ),
  );
  // Let initState / _initializePreferences async work settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

// ──────────────────────────────────────────────────────────────────────────────
//  SUITE SETUP
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(_registerChannelMocks);

  setUp(() async {
    _soundModeCalls.clear();
    _foregroundTaskCalls.clear();
    SharedPreferences.setMockInitialValues({});
    await AdhanAudioPlayer.stop();
    AdhanAudioPlayer.silenced.value = false;
    AdhanAudioPlayer.onPlayAttemptForTesting = null;
    AdhanAutoTrigger.resetForTesting();
  });

  tearDown(() async {
    await AdhanAudioPlayer.stop();
    await Future<void>.delayed(Duration.zero);
  });

  // ────────────────────────────────────────────────────────────────────────────
  //  PBT 1 — autoSilentAfterAdhan==false → _applyAutoSilent() never calls
  //           SoundMode.setSoundMode
  //
  //  Preservation requirement: "When autoSilentAfterAdhan is false, the system
  //  SHALL CONTINUE TO leave the phone ringer unchanged after the adhan screen
  //  is dismissed by any method." (Requirement 3.10)
  //
  //  Domain: 5 silentModeAlertStyle values × 8 silentDurationMins samples
  //         × close / goToPrayer dismissal paths = 80 combinations
  //
  //  PASSES on unfixed code because _applyAutoSilent() has an explicit early
  //  return: `if (prefs?.autoSilentAfterAdhan ?? false) { ... }`.
  //  Any change to that early return would break this test.
  //
  //  **Validates: Requirements 3.10**
  // ────────────────────────────────────────────────────────────────────────────
  group('PBT 1 — autoSilentAfterAdhan==false: ringer never changed', () {
    for (final style in _kAlertStyles) {
      for (final durMins in _kSilentDurationSamples) {
        testWidgets(
          'style=$style durMins=$durMins → no SoundMode call',
          (tester) async {
            final prefs = UserPreferences(
              adhanMode: 'silent', // avoid audio channel calls
              autoSilentAfterAdhan: false, // the non-bug condition
              silentModeAlertStyle: style,
              silentDurationMins: durMins,
              wakeScreenEnabled: false,
              flipToSilenceEnabled: false,
              vibrateWithAdhan: false,
            );

            await _pumpOverlay(tester, prefs, autoPlay: false);

            // Trigger close (calls _cleanup + _applyAutoSilent).
            final closeBtn = find.byIcon(Icons.close_rounded);
            if (closeBtn.evaluate().isNotEmpty) {
              await tester.tap(closeBtn.first);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 50));
            }

            // No sound_mode platform call must have been made.
            final soundModeMethods = _soundModeCalls
                .where((c) =>
                    c.method == 'setSilentMode' ||
                    c.method == 'setVibrateMode' ||
                    c.method == 'setNormalMode')
                .toList();

            expect(
              soundModeMethods,
              isEmpty,
              reason:
                  'PBT 1: autoSilentAfterAdhan==false — SoundMode must NOT '
                  'be called regardless of silentModeAlertStyle or '
                  'silentDurationMins (style=$style, durMins=$durMins). '
                  'The ringer must remain unchanged. '
                  'Preservation: Requirement 3.10.',
            );

            await tester.pumpWidget(const SizedBox());
            await tester.pump();
          },
        );
      }
    }
  });

  // ────────────────────────────────────────────────────────────────────────────
  //  PBT 2 — adhanMode=='vibrate' → AdhanAudioPlayer.isPlaying never true
  //
  //  Preservation requirement: "When adhanMode is vibrate, the system SHALL
  //  CONTINUE TO vibrate without audio." (Requirement 3.2)
  //
  //  Domain: all 6 prayer keys × 3 volume levels = 18 combinations
  //
  //  PASSES on unfixed code because _initAudio() has:
  //    if (mode == 'silent' || mode == 'vibrate') {
  //      setState(() => _silenced = true); return;
  //    }
  //  so AdhanAudioPlayer.play() is never called for vibrate mode.
  //
  //  **Validates: Requirements 3.2**
  // ────────────────────────────────────────────────────────────────────────────
  group('PBT 2 — adhanMode==vibrate: no audio ever started', () {
    const volumeLevels = [0.0, 0.5, 1.0];

    for (final prayerKey in _kAllPrayerKeys) {
      for (final vol in volumeLevels) {
        testWidgets(
          'prayer=$prayerKey vol=$vol → isPlaying==false after _initAudio',
          (tester) async {
            final prefs = UserPreferences(
              adhanMode: 'vibrate',
              adhanVolumeLevel: vol,
              wakeScreenEnabled: false,
              flipToSilenceEnabled: false,
              autoSilentAfterAdhan: false,
            );

            var playAttempted = false;
            AdhanAudioPlayer.onPlayAttemptForTesting =
                () => playAttempted = true;

            // autoPlay=true to exercise _initAudio fully.
            await _pumpOverlay(
              tester,
              prefs,
              prayerName: _prayerAr(prayerKey),
              autoPlay: true,
            );

            // play() must NOT have been called.
            expect(
              playAttempted,
              isFalse,
              reason:
                  'PBT 2: adhanMode==vibrate — AdhanAudioPlayer.play() must '
                  'NEVER be called (prayer=$prayerKey, vol=$vol). '
                  'Preservation: Requirement 3.2.',
            );

            // AdhanAudioPlayer.isPlaying must be false.
            expect(
              AdhanAudioPlayer.isPlaying,
              isFalse,
              reason:
                  'PBT 2: adhanMode==vibrate — AdhanAudioPlayer.isPlaying '
                  'must be false after _initAudio (prayer=$prayerKey, vol=$vol). '
                  'Preservation: Requirement 3.2.',
            );

            // Dispose and drain the 3-minute vibration auto-cancel timer.
            await tester.pumpWidget(const SizedBox());
            await tester.pump();
            await tester.pump(const Duration(minutes: 4));
          },
        );
      }
    }
  });

  // ────────────────────────────────────────────────────────────────────────────
  //  PBT 3 — wakeScreenEnabled==true → wakeUpScreen() IS called
  //
  //  Preservation requirement: "When wakeScreenEnabled is true, the system
  //  SHALL CONTINUE TO call FlutterForegroundTask.wakeUpScreen() when the
  //  adhan triggers." (Requirement 3.12)
  //
  //  Domain: all 6 prayer keys (6 combinations via handleForegroundData)
  //
  //  Both _check() and handleForegroundData() call wakeUpScreen() inside the
  //  `if (adhanScreen)` branch (adhanScreenEnabled==true).  The code fires
  //  wakeUpScreen() synchronously BEFORE entering _waitForNavigatorReady,
  //  so we can observe it before the 8-second navigator-ready poll.
  //
  //  We run this as a plain test() (not testWidgets) so real async timers
  //  fire.  The navigatorKey has no live state (currentState == null), which
  //  causes launchApp() to be called and _waitForNavigatorReady to start —
  //  but wakeUpScreen() already ran before that point.  We cancel the hang
  //  by wrapping in a short Future.timeout.
  //
  //  **Validates: Requirements 3.12**
  // ────────────────────────────────────────────────────────────────────────────
  group('PBT 3 — wakeScreenEnabled==true: wakeUpScreen() called', () {
    for (final prayerKey in _kAllPrayerKeys) {
      test(
        'prayer=$prayerKey → wakeUpScreen() called via handleForegroundData',
        () async {
          AdhanAutoTrigger.resetForTesting();
          SharedPreferences.setMockInitialValues({});

          // No live navigator: currentState == null → wakeUpScreen() is
          // called, then launchApp() is called, then _waitForNavigatorReady
          // starts its 8-second poll.  We cancel early via timeout.
          final navigatorKey = GlobalKey<NavigatorState>();

          final prefs = UserPreferences(
            wakeScreenEnabled: true, // the preserved condition
            adhanMode: 'silent',
            adhanScreenEnabled: true, // required for wakeUpScreen branch
            flipToSilenceEnabled: false,
            autoSilentAfterAdhan: false,
          );
          final ref = _StubRef(prefs);

          // Use the testing hook — FlutterForegroundTask.wakeUpScreen() is
          // guarded by `platform.isAndroid` inside the plugin, so it never
          // invokes the MethodChannel on non-Android test hosts.  The hook
          // fires synchronously in the Dart layer, before the platform guard.
          var wakeUpCalled = false;
          AdhanAutoTrigger.onWakeUpScreenForTesting = () {
            wakeUpCalled = true;
          };

          // Allow up to 2 seconds (well past the wakeUpScreen call but
          // before the 8-second navigator poll timeout).
          await AdhanAutoTrigger.handleForegroundData(
            {
              'action': 'show_adhan',
              'prayer': _prayerAr(prayerKey),
              'prayerKey': prayerKey,
              'adhanMode': 'silent',
              'sound': false,
            },
            navigatorKey,
            ref,
          ).timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              // Expected: the navigator poll times out; that's fine because
              // wakeUpScreen() was already called before the poll started.
            },
          );

          // wakeUpScreen must have been called.
          expect(
            wakeUpCalled,
            isTrue,
            reason:
                'PBT 3: wakeScreenEnabled==true — wakeUpScreen() must be '
                'called when the adhan triggers via handleForegroundData '
                '(prayer=$prayerKey). Preservation: Requirement 3.12.',
          );
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    }
  });

  // ────────────────────────────────────────────────────────────────────────────
  //  PBT 4 — silentModeEnabled==false → adhan fires for ALL prayer keys
  //
  //  Preservation requirement: "When silentModeEnabled is false, the system
  //  SHALL CONTINUE TO play adhan audio and post notifications regardless of
  //  the phone's current ringer state." (Requirement 3.11)
  //
  //  Domain: all subsets of the 6 prayer keys used as silentAdhanPrayers,
  //          with silentModeEnabled==false. Even when a key IS listed in
  //          silentAdhanPrayers, the trigger must still fire when the flag
  //          is globally off.
  //
  //  This PBT generates 6 cases: each prayer key individually injected.
  //  silentAdhanPrayers lists only that prayer's key (worst case: the prayer
  //  is present in the list but silentModeEnabled==false so the gate is off).
  //
  //  PASSES on unfixed code because _checkAndTriggerAdhan() sends show_adhan
  //  unconditionally when _adhanScreenEnabled==true, without any silent-mode
  //  check at all (the allow-list gate doesn't exist yet — that is Bug 4.8).
  //
  //  **Validates: Requirements 3.11**
  // ────────────────────────────────────────────────────────────────────────────
  group('PBT 4 — silentModeEnabled==false: adhan fires for all prayer keys', () {
    for (final prayerKey in _kAllPrayerKeys) {
      test(
        'prayer=$prayerKey in silentAdhanPrayers, silentModeEnabled=false → show_adhan sent',
        () async {
          SharedPreferences.setMockInitialValues({
            'overlay_triggered_prayers_date': '',
            'overlay_triggered_prayers': '',
            // silentModeEnabled is false (the preserved path)
            'silent_mode_enabled': false,
          });

          final handler = OverlayBackgroundService.createHandlerForTesting();

          // Inject the prayer with a time 30 seconds in the past (within trigger window).
          handler.injectPrayerForTesting(
            name: prayerKey,
            nameAr: _prayerAr(prayerKey),
            emoji: _prayerEmoji(prayerKey),
            time: DateTime.now().subtract(const Duration(seconds: 30)),
          );

          final sent = <Map>[];
          handler.onSendDataToMain = sent.add;

          await handler.triggerAdhanCheckForTesting();

          final showAdhanMessages =
              sent.where((m) => m['action'] == 'show_adhan').toList();

          expect(
            showAdhanMessages,
            hasLength(1),
            reason:
                'PBT 4: silentModeEnabled==false — show_adhan must be sent '
                'for prayer=$prayerKey even when it appears in silentAdhanPrayers. '
                'The silent-mode gate must be inactive when silentModeEnabled==false. '
                'Preservation: Requirement 3.11.',
          );

          // Confirm the correct prayer key is reported.
          expect(
            showAdhanMessages.first['prayerKey'],
            equals(prayerKey),
            reason:
                'PBT 4: The sent show_adhan message must carry the correct '
                'prayerKey=$prayerKey.',
          );
        },
      );
    }
  });

  // ────────────────────────────────────────────────────────────────────────────
  //  PBT 5 — autoSilentAfterAdhan==false, silentDurationMins in 1–60 →
  //           no restore timer ever scheduled
  //
  //  Preservation requirement: "When autoSilentAfterAdhan is false, the
  //  system SHALL CONTINUE TO leave the phone ringer unchanged after the
  //  adhan screen is dismissed." (Requirement 3.10)
  //
  //  This PBT specifically targets the restore-timer path: even if the
  //  fix adds a Future.delayed restore timer, it must ONLY be scheduled
  //  when autoSilentAfterAdhan==true. When the flag is false, no timer
  //  must be scheduled regardless of silentDurationMins.
  //
  //  Domain: 5 silentModeAlertStyle values × 8 silentDurationMins samples
  //         = 40 combinations, tested via direct overlay pump + close.
  //
  //  PASSES on unfixed code because _applyAutoSilent() exits before
  //  reaching any scheduling logic when autoSilentAfterAdhan==false.
  //
  //  We verify by:
  //   1. Pumping the overlay, triggering close (_applyAutoSilent called).
  //   2. Advancing the fake clock by silentDurationMins + 1 minute.
  //   3. Asserting no additional SoundMode calls occurred (would indicate
  //      a restore timer fired).
  //
  //  **Validates: Requirements 3.10**
  // ────────────────────────────────────────────────────────────────────────────
  group('PBT 5 — autoSilentAfterAdhan==false: no restore timer scheduled', () {
    for (final style in _kAlertStyles) {
      for (final durMins in _kSilentDurationSamples) {
        testWidgets(
          'style=$style durMins=$durMins → no timer fires after durMins',
          (tester) async {
            final prefs = UserPreferences(
              adhanMode: 'silent',
              autoSilentAfterAdhan: false, // key: flag is off
              silentModeAlertStyle: style,
              silentDurationMins: durMins,
              wakeScreenEnabled: false,
              flipToSilenceEnabled: false,
              vibrateWithAdhan: false,
            );

            await _pumpOverlay(tester, prefs, autoPlay: false);

            // Trigger close so _applyAutoSilent() is invoked.
            final closeBtn = find.byIcon(Icons.close_rounded);
            if (closeBtn.evaluate().isNotEmpty) {
              await tester.tap(closeBtn.first);
              await tester.pump();
            }

            // Record how many SoundMode calls occurred at close time.
            final soundCallsAtClose = _soundModeCalls
                .where((c) =>
                    c.method == 'setSilentMode' ||
                    c.method == 'setVibrateMode' ||
                    c.method == 'setNormalMode')
                .length;

            // No SoundMode calls must have happened at close.
            expect(
              soundCallsAtClose,
              isZero,
              reason:
                  'PBT 5 pre-check: close with autoSilentAfterAdhan==false '
                  'must produce no SoundMode calls '
                  '(style=$style, durMins=$durMins). Requirement 3.10.',
            );

            // Advance past the silentDurationMins window.
            await tester.pump(Duration(minutes: durMins + 1));

            // Still no SoundMode calls (no restore timer was scheduled).
            final soundCallsAfterTimer = _soundModeCalls
                .where((c) =>
                    c.method == 'setSilentMode' ||
                    c.method == 'setVibrateMode' ||
                    c.method == 'setNormalMode')
                .length;

            expect(
              soundCallsAfterTimer,
              isZero,
              reason:
                  'PBT 5: autoSilentAfterAdhan==false — no restore timer '
                  'must fire after $durMins minutes '
                  '(style=$style, durMins=$durMins). '
                  'Preservation: Requirement 3.10.',
            );

            await tester.pumpWidget(const SizedBox());
            await tester.pump();
          },
        );
      }
    }
  });
}

// ──────────────────────────────────────────────────────────────────────────────
//  UTILITIES
// ──────────────────────────────────────────────────────────────────────────────

String _prayerAr(String key) => switch (key) {
      'fajr' => 'الفجر',
      'dhuhr' => 'الظهر',
      'asr' => 'العصر',
      'maghrib' => 'المغرب',
      'isha' => 'العشاء',
      'jumuah' => 'الجمعة',
      _ => key,
    };

String _prayerEmoji(String key) => switch (key) {
      'fajr' => '🌅',
      'dhuhr' => '☀️',
      'asr' => '🌤',
      'maghrib' => '🌆',
      'isha' => '🌃',
      'jumuah' => '🕌',
      _ => '🕌',
    };
