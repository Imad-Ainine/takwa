// Tests for the Drift → SharedPreferences settings mirror that the
// foreground-service isolate reads. A key that never reaches
// SharedPreferences makes the background compute prayer times with its own
// fallbacks (the historical cause of the notification showing Maghrib +5
// min while the Adhan screen showed the configured time), so mirrorAll —
// run on every UserPreferencesNotifier.build() — must carry every value
// type through with its type intact.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/features/settings/data/settings_prefs_bridge.dart';

void main() {
  late SharedPreferences prefs;
  late SettingsPrefsBridge bridge;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bridge = SettingsPrefsBridge(prefs);
  });

  test('mirror stores each Dart type under its native pref type', () async {
    await bridge.mirror('flag', true);
    await bridge.mirror('count', 7);
    await bridge.mirror('ratio', 0.5);
    await bridge.mirror('calc_method', 'Algeria');

    expect(prefs.getBool('flag'), isTrue);
    expect(prefs.getInt('count'), 7);
    expect(prefs.getDouble('ratio'), 0.5);
    expect(prefs.getString('calc_method'), 'Algeria');
  });

  test('mirrorAll seeds every key of a settings map', () async {
    await bridge.mirrorAll(const {
      'madhab': 'hanafi',
      'calc_method': 'MWL',
      'maghrib_offset': -3,
      'prayer_reminder': true,
      'adhan_volume_level': 0.8,
    });

    expect(prefs.getString('madhab'), 'hanafi');
    expect(prefs.getString('calc_method'), 'MWL');
    expect(prefs.getInt('maghrib_offset'), -3);
    expect(prefs.getBool('prayer_reminder'), isTrue);
    expect(prefs.getDouble('adhan_volume_level'), 0.8);
  });

  test('mirrorAll overwrites stale values — the seed pass is self-healing',
      () async {
    await prefs.setString('calc_method', 'Algeria');

    await bridge.mirrorAll(const {'calc_method': 'MWL'});

    expect(prefs.getString('calc_method'), 'MWL');
  });
}
