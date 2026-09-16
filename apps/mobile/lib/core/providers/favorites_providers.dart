import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_config.dart';
import '../supabase/supabase_providers.dart';
import 'favorites_repository.dart';
import 'shared_preferences_provider.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(sharedPreferencesProvider));
});

class FavoriteItemsNotifier extends StateNotifier<Set<int>> {
  final String _key;
  final Ref ref;

  FavoriteItemsNotifier(this._key, this.ref)
    : super(ref.read(favoritesRepositoryProvider).getIds(_key));

  void toggle(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
    _save();
  }

  Future<void> _save({bool syncToRemote = true}) async {
    await ref.read(favoritesRepositoryProvider).setIds(_key, state);

    if (syncToRemote) {
      final isOnline = ref.read(connectivityProvider).value ?? false;
      final isAuth = ref.read(currentUserProvider) != null;
      if (isOnline && isAuth) {
        ref
            .read(supabaseServiceProvider)
            .updateSettings({_key: state.toList()})
            .catchError((_) {}); // Handle silently in background
      }
    }
  }

  Future<void> syncFromRemote(List<dynamic> remoteList) async {
    final mapped = remoteList
        .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
        .toSet();
    if (mapped.isNotEmpty) {
      state = {...state, ...mapped};
      await _save(syncToRemote: false);
    }
  }
}

final favoriteDuasProvider =
    StateNotifierProvider<FavoriteItemsNotifier, Set<int>>((ref) {
      return FavoriteItemsNotifier('favorite_duas', ref);
    });

final favoriteAdhkarProvider =
    StateNotifierProvider<FavoriteItemsNotifier, Set<int>>((ref) {
      return FavoriteItemsNotifier('favorite_adhkar', ref);
    });
