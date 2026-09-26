import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_providers.dart';

/// Unifies authentication states for the application
enum AuthStatus {
  /// The auth stream has not produced a first event yet. It says nothing
  /// about whether the user is signed out, so nothing that gates the whole
  /// UI on "signed out" may treat this as [AuthStatus.unauthenticated].
  pending,

  /// The auth subscription itself failed (rejected token refresh, GoTrue
  /// error). Also not a sign-out — but unlike [pending] it will not resolve
  /// on its own, so it needs a visible retry rather than a spinner.
  error,
  authenticated,
  guest,
  unauthenticated,
}

/// The signed-in Supabase user, derived from the app's one and only
/// [authStateProvider] subscription.
///
/// This used to open a second `onAuthStateChange` listen of its own, so the
/// process held two subscriptions to the same stream and two independent
/// ideas of who was signed in — the two disagreed during whatever window
/// one of them had not emitted yet.
///
/// Exposed as `AsyncValue<User?>` (the shape a `StreamProvider` gave here)
/// because every consumer only reads `.value`.
final supabaseUserProvider = Provider<AsyncValue<User?>>((ref) {
  return ref.watch(authStateProvider).whenData((state) => state.session?.user);
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
    // Both of these used to answer `unauthenticated`, which made every
    // "signed out?" gate — the shell's redirect to the auth screen above all
    // — fire while the stream was merely unresolved: a slow first event or a
    // failed token refresh visibly logged users out of a session they still
    // had.
    loading: () => AuthStatus.pending,
    error: (_, _) => AuthStatus.error,
  );
});
