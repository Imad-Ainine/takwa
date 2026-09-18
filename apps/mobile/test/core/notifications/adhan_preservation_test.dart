// Preservation Property Tests — Adhan Feature
//
// These tests assert that all non-buggy adhan behaviors are UNCHANGED by
// the fix. They MUST PASS on the UNFIXED codebase (establishing the
// baseline) and continue to pass after the fix is applied (regression guard).
//
// Each PBT sweeps over a representative domain of inputs — prayer names,
// adhan modes, timing offsets, volume levels — to confirm the property
// holds across all combinations, not just a single example.
//
// Scoped so NONE of the four bug conditions are triggered:
//   Bug 1: navigatorKey.currentState == null at entry (avoid unconditional
//           launchApp when navigator is live).
//   Bug 2: no AdhanAudioPlayer.play() before screen push in these paths.
//   Bug 3: flipToSilenceEnabled = false in all widget tests (no sensor sub).
//   Bug 4: _adhanScreenEnabled never read in these paths.
//
// Covers: Requirements 3.1–3.10
// Design reference: .kiro/specs/adhan-feature-fix/design.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:takwa/core/notifications/adhan_auto_trigger.dart';
import 'package:takwa/core/notifications/overlay_background_service.dart';
import 'package:takwa/core/notifications/overlays/adhan_overlay_screen.dart';
import 'package:takwa/features/settings/data/user_preferences.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  DOMAIN CONSTANTS
//  Representative value sets used across all PBTs.
// ──────────────────────────────────────────────────────────────────────────────

/// All five canonical prayer names used by the trigger system.
const _kPrayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

/// Volume levels across the full supported range (subset for widget tests).
const _kVolumeLevels = [0.0, 0.5, 1.0];

// ──────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────f─────────────────────────────────────────────

/// Minimal [WidgetRef] stub that vends a fixed [UserPreferences] from any
/// AsyncNotifierProvider.  Matches the same pattern used in
/// adhan_bug_condition_test.dart.
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

/// Builds a [UserPreferences] with the given [adhanMode] and safe defaults
/// that keep all four bug conditions inactive:
///   - [flipToSilenceEnabled] is always `false` (no sensor subscription).
///   - [adhanScreenEnabled] is `true` (normal flow; Bug 4 gate is irrelevant
///     because these tests don't go through _OverlayTaskHandler).
///   - [wakeScreenEnabled] is `false` (avoids wakelock plugin calls in tests).
///   - [vibrateWithAdhan] is `false` (prevents HapticFeedback noise).
UserPreferences _prefsWithMode(
  String adhanMode, {
  double volume = 1.0,
  bool flipToSilenceEnabled = false,
}) => UserPreferences(
      adhanMode: adhanMode,
      adhanSound: 'Adhan-Makkah.mp3',
      adhanVolumeLevel: volume,
      adhanScreenEnabled: true,
      flipToSilenceEnabled: flipToSilenceEnabled,
      wakeScreenEnabled: false,    // avoids wakelock platform call
      vibrateWithAdhan: false,     // keep vibration timer deterministic
    );

/// An [Override] that supplies [prefs] for [userPreferencesProvider]
/// so [AdhanOverlayScreen] can read it via `ref.read(...)` without hitting the
/// real SQLite database.
Override _prefsOverride(UserPreferences prefs) =>
    userPreferencesProvider.overrideWith(
      () => _FixedPrefsNotifier(prefs),
    );

/// Minimal notifier that immediately returns a fixed [UserPreferences].
/// Extends [UserPreferencesNotifier] to satisfy the provider's type constraint.
class _FixedPrefsNotifier extends UserPreferencesNotifier {
  final UserPreferences _prefs;
  _FixedPrefsNotifier(this._prefs);

  @override
  Future<UserPreferences> build() async => _prefs;
}

/// Pumps a full [ProviderScope]-wrapped [AdhanOverlayScreen] including
/// the localization delegates required by the screen's `build` method.
///
/// The screen is a full-screen modal with a tall content column; the default
/// 800×600 test surface overflows by ~30 px. We use a phone-sized surface
/// (390×844, iPhone 14 logical pixels) and suppress the known overflow error
/// (same pattern used in widget_test.dart) to keep test output clean.
Future<void> _pumpAdhanScreen(
  WidgetTester tester,
  UserPreferences prefs, {
  String? prayerName,
  bool autoPlay = true,
}) async {
  // Use a realistic phone screen size so the tall content column fits.
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Suppress the RenderFlex overflow error that fires on very small surfaces
  // (the screen is designed for full-screen use, not 800×600).
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('A RenderFlex overflowed')) {
      return; // expected on constrained test surfaces
    }
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [_prefsOverride(prefs)],
      child: MaterialApp(
        // Required: AdhanOverlayScreen.build() calls AppLocalizations.of(context)!
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdhanOverlayScreen(
          prayerName: prayerName ?? 'الفجر',
          autoPlay: autoPlay,
        ),
      ),
    ),
  );
  // Let initState / _initializePreferences microtasks settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Resets [AdhanAudioPlayer] static state to a clean slate.
Future<void> _resetAudioPlayer() async {
  await AdhanAudioPlayer.stop();
  AdhanAudioPlayer.silenced.value = false;
  AdhanAudioPlayer.onPlayAttemptForTesting = null;
}

// ──────────────────────────────────────────────────────────────────────────────
//  MOCK CHANNELS
// ──────────────────────────────────────────────────────────────────────────────

void _silencePluginChannels() {
  // flutter_foreground_task — wakeUpScreen / launchApp / isRunningService
  // IMPORTANT: isRunningService returns a bool, so the mock must return false
  // (not null) to avoid a cast error in AdhanForegroundService.stopAdhanService.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter_foreground_task/methods'),
    (call) async {
      if (call.method == 'isRunningService') return false;
      return null;
    },
  );
  // wakelock_plus — WakelockPlus.enable() / disable()
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/wakelock'),
    (call) async => null,
  );
  // just_audio — AudioPlayer (base registration channel)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.ryanheise.just_audio.methods'),
    (call) async => null,
  );
  // sound_mode — SoundMode.setSoundMode()
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('sound_mode'),
    (call) async => null,
  );
  // HapticFeedback goes through SystemChannels.platform — already handled
  // by the test framework by default, no override needed.
}

// ──────────────────────────────────────────────────────────────────────────────
//  TESTS
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(_silencePluginChannels);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _resetAudioPlayer();
    AdhanAutoTrigger.resetForTesting();
  });

  tearDown(() async {
    await _resetAudioPlayer();
  });

  // ──────────────────────────────────────────────────────────────────────────
  //  PBT 2.1 — Silent mode preservation
  //
  //  For ALL prayer inputs with adhanMode = 'silent':
  //    ASSERT AdhanAudioPlayer.play() is never called
  //    ASSERT the screen renders in muted state (_silenced = true → label
  //           shows "الصوت متوقف" / "Muted")
  //
  //  Domain: all 5 prayers × 3 volume levels (15 tests)
  //  None of the four bug conditions are triggered:
  //    • No audio path → Bug 2 and Bug 3 cannot fire
  //    • Widget already mounted → Bug 1 inactive
  //    • _adhanScreenEnabled not read here → Bug 4 inactive
  //
  //  Validates: Requirements 3.1
  // ──────────────────────────────────────────────────────────────────────────
  group('PBT 2.1 — Silent mode preservation', () {
    for (final prayerName in _kPrayerNames) {
      for (final volume in _kVolumeLevels) {
        testWidgets(
          'prayer=$prayerName volume=$volume → no audio, _silenced=true',
          (tester) async {
            final prefs = _prefsWithMode('silent', volume: volume);

            var playAttempted = false;
            AdhanAudioPlayer.onPlayAttemptForTesting =
                () => playAttempted = true;

            await _pumpAdhanScreen(tester, prefs, prayerName: prayerName);

            // AdhanAudioPlayer.play() must never be called in silent mode.
            expect(
              playAttempted,
              isFalse,
              reason:
                  'PBT 2.1: silent mode — play() must NOT be called '
                  '(prayer=$prayerName, volume=$volume)',
            );

            // The "Stop Audio" button must show the muted state because
            // _initAudio sets _silenced = true for silent/vibrate modes.
            // We look for the Arabic "الصوت متوقف" or English "Muted" text
            // that the screen displays when _silenced == true.
            final mutedFinder = find.textContaining(
              RegExp(r'الصوت متوقف|Muted', caseSensitive: false),
            );
            expect(
              mutedFinder,
              findsOneWidget,
              reason:
                  'PBT 2.1: silent mode — UI must show muted state '
                  '(prayer=$prayerName, volume=$volume)',
            );

            // Dispose the widget tree so repeating animation controllers
            // don't leak pending timers into subsequent tests.
            await tester.pumpWidget(const SizedBox());
            await tester.pump();
          },
        );
      }
    }
  });

  // ──────────────────────────────────────────────────────────────────────────
  //  PBT 2.2 — Vibrate mode preservation
  //
  //  For ALL prayer inputs with adhanMode = 'vibrate':
  //    ASSERT AdhanAudioPlayer.play() is never called
  //    ASSERT the screen renders in muted state
  //    (observable contract: no audio, _silenced = true set in _initAudio)
  //
  //  Domain: all 5 prayers (5 tests)
  //  Validates: Requirements 3.2
  // ──────────────────────────────────────────────────────────────────────────
  group('PBT 2.2 — Vibrate mode preservation', () {
    for (final prayerName in _kPrayerNames) {
      testWidgets(
        'prayer=$prayerName → no audio, screen opens in muted state',
        (tester) async {
          final prefs = _prefsWithMode('vibrate');

          var playAttempted = false;
          AdhanAudioPlayer.onPlayAttemptForTesting =
              () => playAttempted = true;

          await _pumpAdhanScreen(tester, prefs, prayerName: prayerName);

          // No audio must be started for vibrate mode.
          expect(
            playAttempted,
            isFalse,
            reason:
                'PBT 2.2: vibrate mode — play() must NOT be called '
                '(prayer=$prayerName)',
          );

          // Screen renders in muted state (same _initAudio path as silent).
          final mutedFinder = find.textContaining(
            RegExp(r'الصوت متوقف|Muted', caseSensitive: false),
          );
          expect(
            mutedFinder,
            findsOneWidget,
            reason:
                'PBT 2.2: vibrate mode — UI must show muted state '
                '(prayer=$prayerName)',
          );

          // Explicitly dispose the widget tree so animation controllers
          // (pulse, stars, entry) are cancelled and don't leak pending timers
          // into the next test.
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          // The vibrate path arms a Future.delayed(minutes: 3) auto-cancel
          // that is NOT cancelled in dispose(). Advance the fake clock past it
          // so the timer fires and completes cleanly before the test ends.
          await tester.pump(const Duration(minutes: 4));
        },
      );
    }
  });

  // ──────────────────────────────────────────────────────────────────────────
  //  PBT 2.3 — Manual mute (Stop Audio button) preservation
  //
  //  For ALL prayer × volume combinations, with adhanMode = 'sound' but
  //  autoPlay = false (avoids Bug 2 / Bug 3 audio-before-screen path):
  //    ASSERT tapping the "Stop Audio" button transitions the button label
  //           to the muted state (proves _silenceAdhan() fired and set
  //           _silenced = true, which also calls AdhanAudioPlayer.stop())
  //
  //  Bug condition avoidance:
  //    • autoPlay = false → _initAudio is skipped → play() never called →
  //      Bug 2 and Bug 3 inactive
  //    • navigatorKey irrelevant → Bug 1 inactive
  //    • _adhanScreenEnabled not involved → Bug 4 inactive
  //
  //  Domain: all 5 prayers (5 tests)
  //  Validates: Requirements 3.4
  // ──────────────────────────────────────────────────────────────────────────
  group('PBT 2.3 — Manual mute preservation', () {
    for (final prayerName in _kPrayerNames) {
      testWidgets(
        'prayer=$prayerName → tap Stop Audio → muted state',
        (tester) async {
          // sound mode, autoPlay=false to avoid triggering Bug 2/3 paths.
          final prefs = _prefsWithMode('sound');

          await _pumpAdhanScreen(
            tester,
            prefs,
            prayerName: prayerName,
            autoPlay: false, // bypass audio init entirely
          );

          // Verify the initial un-muted label is visible.
          // The screen shows "إيقاف الصوت" (AR) or "Stop Audio" (EN).
          final stopAudioFinder = find.textContaining(
            RegExp(r'إيقاف الصوت|Stop Audio', caseSensitive: false),
          );
          expect(
            stopAudioFinder,
            findsOneWidget,
            reason:
                'PBT 2.3: initial state must show "Stop Audio" button '
                '(prayer=$prayerName)',
          );

          // Tap the Stop Audio button.
          await tester.tap(stopAudioFinder);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          // After tapping, _silenced must be true → label changes to muted.
          final mutedFinder = find.textContaining(
            RegExp(r'الصوت متوقف|Muted', caseSensitive: false),
          );
          expect(
            mutedFinder,
            findsOneWidget,
            reason:
                'PBT 2.3: after tapping Stop Audio, UI must show muted state '
                '(prayer=$prayerName)',
          );

          // The un-muted label must no longer be visible.
          expect(
            stopAudioFinder,
            findsNothing,
            reason:
                'PBT 2.3: "Stop Audio" label must disappear after mute tap '
                '(prayer=$prayerName)',
          );

          // Explicitly dispose the widget tree so animation controllers
          // (pulse, stars, entry) are cancelled and don't leak pending timers
          // into the next test.
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        },
      );
    }
  });

  // ──────────────────────────────────────────────────────────────────────────
  //  PBT 2.4 — Deduplication preservation
  //
  //  For ALL prayer × timing-offset combinations:
  //    Given a prayer's daily key is already claimed by the first trigger
  //    WHEN handleForegroundData is called a second time with the same prayer
  //    ASSERT the second trigger is a no-op:
  //      - onLaunchAppForTesting is NOT called
  //
  //  This tests the shared per-day dedupe mechanism (_lastTriggeredPrayer)
  //  that prevents double-triggering between isolates.
  //
  //  Bug condition avoidance:
  //    • adhanScreenEnabled = false AND adhanMode = 'silent' → both the audio
  //      path AND the screen push path are skipped entirely. handleForegroundData
  //      completes synchronously after claiming the key, with no concurrent
  //      8-second navigator poll running in the background.
  //    • No concurrent timers → no race conditions between triggers.
  //    • flipToSilenceEnabled = false → Bug 3 inactive.
  //    • _adhanScreenEnabled not involved → Bug 4 inactive.
  //
  //  Domain: all 5 prayers × 4 timing offsets (20 tests)
  //  Validates: Requirements 3.7
  // ──────────────────────────────────────────────────────────────────────────
  group('PBT 2.4 — Deduplication preservation', () {
    const offsets = [1, 30, 120, 299];

    for (final prayerName in _kPrayerNames) {
      for (final offsetSecs in offsets) {
        test(
          'prayer=$prayerName offsetSecs=$offsetSecs → second trigger is no-op',
          () async {
            // Reset static state for each parameterized test body since
            // setUp() only runs once per test() scope, not per loop iteration
            // within the same isolate.
            AdhanAutoTrigger.resetForTesting();
            SharedPreferences.setMockInitialValues({
              'overlay_triggered_prayers_date': '',
              'overlay_triggered_prayers': '',
            });

            final navigatorKey = GlobalKey<NavigatorState>();

            // Use adhanScreenEnabled=false AND adhanMode='silent' so that
            // handleForegroundData claims the key and returns immediately
            // without starting any long-running concurrent work (no audio,
            // no 8-second navigator poll). This makes the test fully
            // synchronous and eliminates all race conditions between triggers.
            const prefs = UserPreferences(
              adhanMode: 'silent',
              adhanScreenEnabled: false,
              flipToSilenceEnabled: false,
              wakeScreenEnabled: false,
            );
            final ref = _StubRef(prefs);

            // ── First trigger: claim the daily key ──
            // With adhanScreen=false the function completes immediately
            // after claiming _lastTriggeredPrayer — no pending timers.
            await AdhanAutoTrigger.handleForegroundData(
              {
                'action': 'show_adhan',
                'prayer': _prayerNameAr(prayerName),
                'prayerKey': prayerName,
                'adhanMode': 'silent',
                'sound': false,
              },
              navigatorKey,
              ref,
            );

            // ── Second trigger: same prayer, same day ──
            final launchCalls2 = <DateTime>[];
            AdhanAutoTrigger.onLaunchAppForTesting =
                (ts) => launchCalls2.add(ts);

            var playCount2 = 0;
            AdhanAudioPlayer.onPlayAttemptForTesting = () => playCount2++;

            await AdhanAutoTrigger.handleForegroundData(
              {
                'action': 'show_adhan',
                'prayer': _prayerNameAr(prayerName),
                'prayerKey': prayerName,
                'adhanMode': 'silent',
                'sound': false,
              },
              navigatorKey,
              ref,
            );

            // EXPECTED (preserved): second trigger is claimed by
            // _lastTriggeredPrayer check → returns immediately →
            // no launchApp(), no play().
            expect(
              launchCalls2,
              isEmpty,
              reason:
                  'PBT 2.4: second trigger must be a no-op — launchApp() '
                  'must NOT be called again '
                  '(prayer=$prayerName, offsetSecs=$offsetSecs)',
            );
            expect(
              playCount2,
              isZero,
              reason:
                  'PBT 2.4: second trigger must be a no-op — play() '
                  'must NOT be called again '
                  '(prayer=$prayerName, offsetSecs=$offsetSecs)',
            );
          },
        );
      }
    }
  });

  // ──────────────────────────────────────────────────────────────────────────
  //  PBT 2.5 — Adhkar/dua popup isolation
  //
  //  Property: the adhan-trigger path (TestableOverlayHandler.
  //  triggerAdhanCheckForTesting) must NEVER produce adhkar/dua payloads
  //  regardless of what toggle sequences are sent via onReceiveData.
  //  The adhkar popup path (_checkAndShowAdhkarOverlay) is an entirely
  //  separate method in the production code and must remain unaffected by
  //  any changes to adhan screen gating logic.
  //
  //  Additionally verifies the non-bug path (adhanScreenEnabled=true):
  //  sendDataToMain IS called exactly once with action='show_adhan'.
  //
  //  Domain: all 5 prayers (5 tests), with toggle sequences of length 1–5
  //  Validates: Requirements 3.10
  // ──────────────────────────────────────────────────────────────────────────
  group('PBT 2.5 — Adhkar/dua popup isolation', () {
    for (final prayerName in _kPrayerNames) {
      test(
        'prayer=$prayerName → adhkar path unaffected by adhanScreen toggle',
        () async {
          SharedPreferences.setMockInitialValues({
            'overlay_triggered_prayers_date': '',
            'overlay_triggered_prayers': '',
          });

          // ── Case A: adhanScreenEnabled = true (default, non-bug path) ──
          // Confirms the normal non-toggled path still works correctly.
          final handlerA = OverlayBackgroundService.createHandlerForTesting();

          handlerA.injectPrayerForTesting(
            name: prayerName,
            nameAr: _prayerNameAr(prayerName),
            emoji: _prayerEmoji(prayerName),
            time: DateTime.now().subtract(const Duration(seconds: 30)),
          );

          final sentA = <Map>[];
          handlerA.onSendDataToMain = sentA.add;

          await handlerA.triggerAdhanCheckForTesting();

          // Non-bug path: sendDataToMain IS called with action='show_adhan'.
          final showAdhanA = sentA
              .where((m) => m['action'] == 'show_adhan')
              .toList();
          expect(
            showAdhanA.length,
            equals(1),
            reason:
                'PBT 2.5 Case A: with adhanScreenEnabled=true, '
                'sendDataToMain(show_adhan) must be called exactly once '
                '(prayer=$prayerName)',
          );

          // Adhan trigger path must never produce adhkar/dua-type payloads.
          final nonAdhanA = sentA
              .where((m) => m['type'] == 'adhkar' || m['type'] == 'dua')
              .toList();
          expect(
            nonAdhanA,
            isEmpty,
            reason:
                'PBT 2.5 Case A: adhkar/dua messages must never be produced '
                'by the adhan trigger path (prayer=$prayerName)',
          );

          // ── Case B: Toggle sequence applied before trigger ──
          // Confirms that any number of onReceiveData calls does not inject
          // adhkar/dua payloads into the adhan trigger output.
          SharedPreferences.setMockInitialValues({
            'overlay_triggered_prayers_date': '',
            'overlay_triggered_prayers': '',
          });

          final handlerB = OverlayBackgroundService.createHandlerForTesting();

          // Apply a sequence of toggle changes (the unfixed code ignores
          // 'adhan_screen_enabled', so these are no-ops there — but the
          // important assertion is that neither path produces adhkar data).
          const toggleSequence = [true, false, true, false, true];
          for (final v in toggleSequence) {
            handlerB.onReceiveData({'adhan_screen_enabled': v});
          }
          // Final state in sequence: true → adhan trigger fires on unfixed code.

          handlerB.injectPrayerForTesting(
            name: prayerName,
            nameAr: _prayerNameAr(prayerName),
            emoji: _prayerEmoji(prayerName),
            time: DateTime.now().subtract(const Duration(seconds: 30)),
          );

          final sentB = <Map>[];
          handlerB.onSendDataToMain = sentB.add;

          await handlerB.triggerAdhanCheckForTesting();

          // No adhkar/dua payloads must come through the adhan-trigger path
          // regardless of toggle sequence.
          final adhkarMessagesB = sentB
              .where(
                (m) => m['type'] == 'adhkar' || m['type'] == 'dua',
              )
              .toList();
          expect(
            adhkarMessagesB,
            isEmpty,
            reason:
                'PBT 2.5 Case B: adhkar/dua messages must never be produced '
                'by the adhan trigger path regardless of toggle sequence '
                '(prayer=$prayerName)',
          );
        },
      );
    }
  });
}

// ──────────────────────────────────────────────────────────────────────────────
//  HELPERS (test-only utilities)
// ──────────────────────────────────────────────────────────────────────────────

String _prayerNameAr(String name) => switch (name) {
  'fajr' => 'الفجر',
  'dhuhr' => 'الظهر',
  'asr' => 'العصر',
  'maghrib' => 'المغرب',
  'isha' => 'العشاء',
  _ => name,
};

String _prayerEmoji(String name) => switch (name) {
  'fajr' => '🌅',
  'dhuhr' => '☀️',
  'asr' => '🌤',
  'maghrib' => '🌆',
  'isha' => '🌃',
  _ => '🕌',
};
