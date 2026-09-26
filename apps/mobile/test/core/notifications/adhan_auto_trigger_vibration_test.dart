// Regression tests for the auto-trigger vibration timer lifetime (P0 fix):
//
// Bug 1: AdhanAutoTrigger started `Timer.periodic(2s, vibrate)` from
//        _check()/handleForegroundData() and cancelled it ONLY when
//        AdhanAudioPlayer.silenced flipped true (flip-to-silence). An adhan
//        that ended naturally — or that never started, e.g. adhanScreen=false
//        with the overlay path absent — left the phone vibrating every 2s
//        until process death.
// Bug 2: Each trigger added a NEW anonymous listener to the static
//        AdhanAudioPlayer.silenced notifier, accumulating one per prayer.
//
// Expected fixed behavior (both bugs):
//   - vibration is bounded: it stops by itself once the tick guard runs out
//     of grace without ever seeing audio playing;
//   - flip-to-silence still stops it immediately via a single, permanently
//     registered listener.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:takwa/core/notifications/adhan_auto_trigger.dart';
import 'package:takwa/features/settings/data/user_preferences.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';

/// Stub [WidgetRef] serving fixed [UserPreferences] (same approach as
/// adhan_overlay_bug_condition_test.dart).
class _StubRef implements WidgetRef {
  _StubRef(this.prefs);

  final UserPreferences prefs;

  @override
  T read<T>(ProviderListenable<T> provider) {
    if (identical(provider, userPreferencesProvider) ||
        provider.toString().contains('userPreferencesProvider')) {
      return AsyncValue.data(prefs) as T;
    }
    throw UnimplementedError('_StubRef.read: $provider');
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

Future<void> _armVibration(UserPreferences prefs) =>
    AdhanAutoTrigger.handleForegroundData(
      {'action': 'show_adhan', 'prayer': 'الفجر', 'prayerKey': 'fajr'},
      GlobalKey<NavigatorState>(),
      _StubRef(prefs),
    );

void main() {
  const soundVibratePrefs = UserPreferences(
    adhanMode: 'sound',
    vibrateWithAdhan: true,
    wakeScreenEnabled: false,
    adhanScreenEnabled: false,
  );

  late int ticks;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdhanAutoTrigger.resetForTesting();
    AdhanAudioPlayer.silenced.value = false;
    ticks = 0;
    AdhanAutoTrigger.onVibrationTickForTesting = () => ticks++;
  });

  tearDown(() {
    AdhanAutoTrigger.resetForTesting();
    AdhanAudioPlayer.silenced.value = false;
  });

  testWidgets(
    'vibration timer stops by itself when the adhan audio never starts '
    '(was: vibrated forever)',
    (tester) async {
      await _armVibration(soundVibratePrefs);

      // Tick while inside the audio-start grace window: vibration runs.
      await tester.pump(const Duration(seconds: 6));
      expect(ticks, greaterThan(0));

      // Advance well past the grace window (60s) — the timer must have
      // cancelled itself, so the count freezes.
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
      final frozen = ticks;
      await tester.pump(const Duration(seconds: 120));
      expect(ticks, frozen, reason: 'timer must self-cancel after the grace window');
      expect(frozen, lessThan(35), reason: '≈30 grace ticks, then stop');
    },
  );

  testWidgets(
    'flip-to-silence stops the vibration immediately, and the silenced '
    'listener is registered once, not per trigger',
    (tester) async {
      await _armVibration(soundVibratePrefs);
      await tester.pump(const Duration(seconds: 2));
      expect(ticks, 1);

      AdhanAudioPlayer.silenced.value = true;
      await tester.pump(const Duration(seconds: 20));
      expect(ticks, 1, reason: 'silenced listener must cancel the timer synchronously');

      // Re-arm for a "second prayer": with the old per-trigger addListener
      // this would have stacked a new listener each time; the single
      // permanent listener must still stop the new timer.
      AdhanAutoTrigger.resetForTesting();
      AdhanAudioPlayer.silenced.value = false;
      AdhanAutoTrigger.onVibrationTickForTesting = () => ticks++;
      await _armVibration(soundVibratePrefs);
      ticks = 0;
      AdhanAudioPlayer.silenced.value = true;
      await tester.pump(const Duration(seconds: 10));
      expect(ticks, 0, reason: 'silenced before first tick → no vibration at all');
    },
  );
}
