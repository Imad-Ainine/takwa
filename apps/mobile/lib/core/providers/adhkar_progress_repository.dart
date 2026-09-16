import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Owns the `adhkar_progress_<category>` SharedPreferences keys that track
/// per-item tap counts for each Adhkar category, so [AdhkarProgressNotifier]
/// reads/writes through here instead of calling the plugin directly.
class AdhkarProgressRepository {
  AdhkarProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'adhkar_progress_';

  Map<int, int> getProgress(String categoryKey) {
    final raw = _prefs.getString('$_prefix$categoryKey');
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> setProgress(String categoryKey, Map<int, int> progress) {
    final encoded = jsonEncode(
      progress.map((k, v) => MapEntry(k.toString(), v)),
    );
    return _prefs.setString('$_prefix$categoryKey', encoded);
  }
}
