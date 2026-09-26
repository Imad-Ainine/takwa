// A push that never happened must not look like a push that succeeded.
//
// SyncManager clears a SyncOutbox entry after the service's write returns, so
// when these writes returned normally for a signed-out user, the entry was
// deleted for data that was never sent — permanent silent loss if the session
// ended between fullSync()'s auth check and the actual push. They now throw
// NotAuthenticatedException, which routes into the existing catch → markPending.
//
// Uses a bare, un-initialised SupabaseClient (no session, no network): every
// one of these must throw before PostgREST is touched.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/supabase/supabase_service.dart';

void main() {
  final service = SupabaseClientService(
    SupabaseClient('https://test.supabase.co', 'anon-key'),
  );

  group('signed-out writes throw instead of silently succeeding', () {
    test('upsertDailyRecord', () async {
      await expectLater(
        service.upsertDailyRecord({'date': '2026-09-26'}),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });

    test('upsertProhibitionLog', () async {
      await expectLater(
        service.upsertProhibitionLog({'date': '2026-09-26'}),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });

    test('upsertCustomIbadah', () async {
      await expectLater(
        service.upsertCustomIbadah({'id': 1}),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });

    test('upsertCustomIbadahLog', () async {
      await expectLater(
        service.upsertCustomIbadahLog({'ibadah_id': 1}),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });

    test('upsertAchievement', () async {
      await expectLater(
        service.upsertAchievement({'type': 'streak_3'}),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });

    test('updateProfile', () async {
      await expectLater(
        service.updateProfile({'username': 'x'}),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });
  });

  // Reads keep their old behaviour: a signed-out pull is genuinely "no data",
  // and SyncManager's pull steps must not blow up just because nobody is
  // signed in.
  group('signed-out reads still return empty rather than throwing', () {
    test('getSettings', () async {
      expect(await service.getSettings(), isNull);
    });

    test('getEarnedAchievements', () async {
      expect(await service.getEarnedAchievements(), isEmpty);
    });
  });
}
