// `authStatusProvider` is what gates the whole app: main_shell shows the
// sign-in screen whenever it reports `unauthenticated`. It used to report
// that for a stream that had merely not emitted yet, or whose subscription
// had failed — so a slow first event or a rejected token refresh logged
// users out of a session they still held. These tests pin the distinction,
// and also that the user comes from the app's single auth subscription
// (overriding `authStateProvider` alone is enough to drive every status).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/supabase/supabase_providers.dart';

AuthState _signedIn() => AuthState(AuthChangeEvent.signedIn, _session());

AuthState _signedOut() => const AuthState(AuthChangeEvent.signedOut, null);

Session _session() => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: User(
    id: 'user-1',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime(2026, 1, 1).toIso8601String(),
  ),
);

ProviderContainer _container(
  Stream<AuthState> authStates, {
  bool guest = false,
}) {
  final container = ProviderContainer(
    overrides: [authStateProvider.overrideWith((ref) => authStates)],
  );
  if (guest) {
    // StateProvider has no value override; the notifier is the way in.
    container.read(guestModeProvider.notifier).state = true;
  }
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('a live session is authenticated, and the user comes from the '
      'shared auth subscription', () async {
    final container = _container(Stream.value(_signedIn()));
    // Let the stream's first event land before reading.
    await container.read(authStateProvider.future);

    expect(container.read(supabaseUserProvider).value?.id, 'user-1');
    expect(container.read(authStatusProvider), AuthStatus.authenticated);
  });

  test('no session is unauthenticated, unless guest mode is on', () async {
    final signedOut = _container(Stream.value(_signedOut()));
    await signedOut.read(authStateProvider.future);
    expect(signedOut.read(authStatusProvider), AuthStatus.unauthenticated);

    final guest = _container(Stream.value(_signedOut()), guest: true);
    await guest.read(authStateProvider.future);
    expect(guest.read(authStatusProvider), AuthStatus.guest);
  });

  test('a stream that has not emitted yet is pending, not signed out', () {
    // Empty on purpose: it never delivers a first event, which is exactly
    // the state the old code read as "no user".
    final container = _container(const Stream<AuthState>.empty());

    expect(container.read(supabaseUserProvider).isLoading, isTrue);
    expect(container.read(authStatusProvider), AuthStatus.pending);
  });

  test('a failed auth stream is an error to retry, not a sign-out', () async {
    final container = _container(
      Stream<AuthState>.error(Exception('token refresh failed')),
    );
    try {
      await container.read(authStateProvider.future);
      fail('the override stream should surface its error');
    } on Exception {
      // Expected: the provider is now in its error state.
    }

    expect(container.read(supabaseUserProvider).hasValue, isFalse);
    expect(container.read(authStatusProvider), AuthStatus.error);
  });
}
