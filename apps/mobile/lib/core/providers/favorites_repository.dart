import 'package:shared_preferences/shared_preferences.dart';

/// Owns the SharedPreferences-backed favorite-id sets (e.g. favorite duas,
/// favorite adhkar), so [FavoriteItemsNotifier] reads/writes through here
/// instead of calling the plugin directly.
class FavoritesRepository {
  FavoritesRepository(this._prefs);

  final SharedPreferences _prefs;

  Set<int> getIds(String key) {
    final list = _prefs.getStringList(key);
    return list == null ? {} : list.map(int.parse).toSet();
  }

  Future<void> setIds(String key, Set<int> ids) {
    return _prefs.setStringList(key, ids.map((e) => e.toString()).toList());
  }
}
