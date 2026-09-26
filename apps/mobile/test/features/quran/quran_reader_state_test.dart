// The reader's font-size control is driven by gestures (settings slider
// ticks, pinch/step scale changes), so `setFontSize` used to write
// SharedPreferences once per pointer event. It now pushes the new value into
// state immediately and coalesces the persistence behind a short timer —
// these tests pin both halves of that split, including the flush on dispose,
// without which closing the reader straight after a drag would lose the
// choice for the next app start.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/features/quran/data/quran_prefs_repository.dart';
import 'package:takwa/features/quran/providers/quran_providers.dart';

void main() {
  late SharedPreferences prefs;
  late QuranPrefsRepository repo;
  late QuranStateNotifier notifier;

  /// Reads the same SharedPreferences cache [notifier] writes through, so a
  /// test can tell "state updated" apart from "disk updated".
  late QuranPrefsRepository disk;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = QuranPrefsRepository(prefs);
    disk = QuranPrefsRepository(prefs);
    notifier = QuranStateNotifier(repo);
  });

  tearDown(() {
    notifier.dispose();
  });

  test(
    'state takes the new size at once while the write is still pending',
    () async {
      notifier.setFontSize(26);

      expect(notifier.state.fontSize, 26);
      expect(
        disk.getFontSize(),
        22.0,
        reason: 'nothing should reach SharedPreferences yet',
      );
    },
  );

  test('a burst of gesture ticks costs one persisted value', () async {
    for (final size in [23.0, 24.0, 25.0, 26.0, 27.0]) {
      notifier.setFontSize(size);
    }
    expect(disk.getFontSize(), 22.0);

    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(
      disk.getFontSize(),
      27.0,
      reason: 'the timer should settle on the last requested size',
    );
  });

  test(
    'the persisted size is clamped to the same range as the state',
    () async {
      notifier.setFontSize(50);
      expect(notifier.state.fontSize, 36);

      await Future<void>.delayed(const Duration(milliseconds: 400));

      // The state clamp and the persisted value used to disagree: the clamped
      // number went to state, the raw one to SharedPreferences.
      expect(disk.getFontSize(), 36);
    },
  );

  test('disposing flushes the pending size instead of dropping it', () async {
    final own = QuranStateNotifier(repo);
    own.setFontSize(30);
    expect(disk.getFontSize(), 22.0);

    own.dispose();
    // SharedPreferences commits its cache on a microtask, so give the
    // unawaited flush one turn before reading it back.
    await Future<void>.delayed(Duration.zero);

    expect(disk.getFontSize(), 30);
  });
}
