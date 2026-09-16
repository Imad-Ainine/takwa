import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Unifies authentication states for the application
enum AuthStatus { authenticated, guest, unauthenticated }

/// Watches the current Supabase user
final supabaseUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (event) => event.session?.user,
  );
});

/// Tracks if the user has opted for guest mode
final guestModeProvider = StateProvider<bool>((ref) => false);

/// Global authentication status provider
final authStatusProvider = Provider<AuthStatus>((ref) {
  final userAsync = ref.watch(supabaseUserProvider);
  final isGuest = ref.watch(guestModeProvider);

  return userAsync.when(
    data: (user) {
      if (user != null) return AuthStatus.authenticated;
      return isGuest ? AuthStatus.guest : AuthStatus.unauthenticated;
    },
    loading: () =>
        AuthStatus.unauthenticated, // Default to unauth during loading
    error: (_, _) => AuthStatus.unauthenticated,
  );
});
