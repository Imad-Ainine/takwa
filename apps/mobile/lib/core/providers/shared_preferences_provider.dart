import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The resolved [SharedPreferences] instance, overridden in `main()` before
/// `runApp` once `SharedPreferences.getInstance()` has completed.
///
/// Feature repositories should depend on this provider instead of calling
/// `SharedPreferences.getInstance()` themselves — it keeps preference access
/// behind one provider per feature repository, and lets notifiers read
/// synchronously since the instance is already resolved by the time the
/// widget tree builds.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider was not overridden — override it with '
    'SharedPreferences.getInstance() before runApp().',
  );
});
