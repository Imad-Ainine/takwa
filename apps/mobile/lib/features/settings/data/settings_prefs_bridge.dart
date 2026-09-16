import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors settings written to the Drift-backed `SettingsDao` into raw
/// SharedPreferences keys as well.
///
/// This exists for one reason: `OverlayBackgroundService`'s task handler
/// runs in a separate isolate (started via `FlutterForegroundTask`) that has
/// no Riverpod `ProviderContainer` to read `SettingsDao` from, so it reads
/// these same keys straight off the SharedPreferences plugin. Key names here
/// must match exactly what that isolate reads — see the `_k*Key` constants
/// in `overlay_background_service.dart`.
class SettingsPrefsBridge {
  SettingsPrefsBridge(this._prefs);

  final SharedPreferences _prefs;

  Future<void> mirror(String key, dynamic value) {
    if (value is bool) return _prefs.setBool(key, value);
    if (value is int) return _prefs.setInt(key, value);
    if (value is double) return _prefs.setDouble(key, value);
    return _prefs.setString(key, value.toString());
  }
}
