// Tests for the Quran/Khatma Supabase sync in SyncManager._syncQuran and
// the quran feature notifiers: device-switch/reinstall adoption, offline
// pushes and journaled deletes, exactly-one-active khatma reconciliation,
// per-account isolation of the local copies, and push coalescing.
// Mirrors auth_sync_test.dart's setup: in-memory Drift + fake Supabase.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/providers/shared_preferences_provider.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/supabase/supabase_providers.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:takwa/features/quran/data/quran_models.dart';
import 'package:takwa/features/quran/providers/quran_providers.dart';

import '../support/fake_supabase_service.dart';

User _user(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
);

/// A row in `khatma_sessions` shape (what getKhatmaSessions returns).
Map<String, dynamic> khatmaRow({
  required String id,
  int pagesRead = 0,
  DateTime? startedAt,
  String? completedDate,
  String? cancelledDate,
}) => {
  'id': id,
  'label': 'ختمة',
  'type': 'muyassara',
  'start_date': (startedAt ?? DateTime(2026, 1, 1)).toIso8601String(),
  'end_date': null,
  'completed_date': completedDate,
  'cancelled_date': cancelledDate,
  'start_page': 1,
  'current_page': 1 + pagesRead,
  'pages_read': pagesRead,
  'notifications_enabled': false,
  'daily_pages': null,
  'total_reading_seconds': 0,
  'reading_sessions_count': 0,
};

KhatmaSessionEx _session(
  String id, {
  int pagesRead = 0,
  DateTime? startDate,
  DateTime? completedDate,
  DateTime? cancelledDate,
}) => KhatmaSessionEx(
  id: id,
  label: 'ختمة',
  type: KhatmaType.muyassara,
  startDate: startDate ?? DateTime(2026, 1, 1),
  pagesRead: pagesRead,
  currentPage: 1 + pagesRead,
  completedDate: completedDate,
  cancelledDate: cancelledDate,
);

String _sessionJson(KhatmaSessionEx s) => jsonEncode(s.toJson());

QuranBookmark _bookmark(int surah, int ayah, int page, {DateTime? at}) =>
    QuranBookmark(
      surahNum: surah,
      ayahNum: ayah,
      page: page,
      surahName: 'البقرة',
      savedAt: at,
    );

void main() {
  late AppDatabase db;
  late FakeSupabaseService fake;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fake = FakeSupabaseService();
  });

  tearDown(() async {
    await db.close();
  });

  Future<ProviderContainer> buildContainer({
    Map<String, Object> prefsSeed = const {},
    String uid = 'test-user-id',
  }) async {
    SharedPreferences.setMockInitialValues(prefsSeed);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        supabaseServiceProvider.overrideWithValue(fake),
        currentUserProvider.overrideWithValue(_user(uid)),
        connectivityCheckerProvider.overrideWithValue(() async => true),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> fullSync(ProviderContainer container) =>
      container.read(syncManagerProvider).fullSync();

  List<KhatmaSessionEx> localHistory(SharedPreferences prefs) {
    final list = prefs.getStringList('khatma_ex_history') ?? [];
    return list.map((s) => KhatmaSessionEx.fromJson(jsonDecode(s))).toList();
  }

  group('Khatma sync', () {
    test('a fresh device adopts the remote active Khatma', () async {
      fake.khatmaSessionsById['r1'] = khatmaRow(id: 'r1', pagesRead: 42);

      final container = await buildContainer();
      await fullSync(container);

      final session = container.read(khatmaExProvider);
      expect(session?.id, 'r1');
      expect(session?.pagesRead, 42);
    });

    test('two devices with different active Khatmas: furthest wins, other archived', () async {
      final container = await buildContainer(
        prefsSeed: {
          'khatma_ex_active': _sessionJson(_session('a', pagesRead: 10)),
        },
      );
      fake.khatmaSessionsById['b'] = khatmaRow(id: 'b', pagesRead: 50);

      await fullSync(container);

      expect(container.read(khatmaExProvider)?.id, 'b');
      // The losing local session lands in history as cancelled and the
      // remote row is told — no invisible zombie, no second active.
      expect(
        fake.khatmaSessionsById['a']!['cancelled_date'],
        isNotNull,
      );
      final prefs = await SharedPreferences.getInstance();
      final history = localHistory(prefs);
      expect(history.map((s) => s.id), contains('a'));
      expect(history.firstWhere((s) => s.id == 'a').isCancelled, isTrue);
    });

    test('a Khatma finished on another device ends locally too', () async {
      final container = await buildContainer(
        prefsSeed: {
          'khatma_ex_active': _sessionJson(_session('x', pagesRead: 30)),
        },
      );
      fake.khatmaSessionsById['x'] = khatmaRow(
        id: 'x',
        pagesRead: 604,
        completedDate: DateTime(2026, 2, 1).toIso8601String(),
      );

      await fullSync(container);

      expect(container.read(khatmaExProvider), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(
        localHistory(prefs).where((s) => s.id == 'x' && s.isCompleted),
        hasLength(1),
      );
    });

    test('a Khatma completed offline is not resurrected by its stale remote row', () async {
      final done = _session(
        'x',
        pagesRead: 300,
        completedDate: DateTime(2026, 2, 1),
      );
      final container = await buildContainer(
        prefsSeed: {
          'khatma_ex_history': [_sessionJson(done)],
        },
      );
      // The completion push failed, so the remote still says "active".
      fake.khatmaSessionsById['x'] = khatmaRow(id: 'x', pagesRead: 300);

      await fullSync(container);

      expect(container.read(khatmaExProvider), isNull);
      expect(
        fake.khatmaSessionsById['x']!['completed_date'],
        isNotNull,
      );
    });

    test('a history entry deleted offline stays deleted and its remote row is removed', () async {
      final done = _session(
        'x',
        pagesRead: 604,
        completedDate: DateTime(2026, 2, 1),
      );
      final container = await buildContainer(
        prefsSeed: {
          'khatma_ex_history': [_sessionJson(done)],
        },
      );
      // Remote copy is stale *and active* — the failure mode where a lost
      // delete would resurrect the whole session.
      fake.khatmaSessionsById['x'] = khatmaRow(id: 'x', pagesRead: 300);

      fake.failQuranPushes = true;
      await container.read(khatmaDeleteHistoryProvider)('x');
      fake.failQuranPushes = false;

      await fullSync(container);

      expect(fake.khatmaSessionsById.containsKey('x'), isFalse);
      expect(container.read(khatmaExProvider), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(localHistory(prefs).where((s) => s.id == 'x'), isEmpty);
    });

    test('deleting a history entry online removes the remote row immediately', () async {
      final done = _session(
        'x',
        completedDate: DateTime(2026, 2, 1),
      );
      final container = await buildContainer(
        prefsSeed: {
          'khatma_ex_history': [_sessionJson(done)],
        },
      );
      fake.khatmaSessionsById['x'] = khatmaRow(
        id: 'x',
        completedDate: DateTime(2026, 2, 1).toIso8601String(),
      );

      await container.read(khatmaDeleteHistoryProvider)('x');

      expect(fake.khatmaSessionsById.containsKey('x'), isFalse);
    });

    test('consecutive page advances coalesce into one remote push', () async {
      final container = await buildContainer();
      final notifier = container.read(khatmaExProvider.notifier);

      await notifier.createNew(
        label: 'ختمة',
        type: KhatmaType.muyassara,
        startPage: 1,
      );
      final id = container.read(khatmaExProvider)!.id;
      await notifier.advancePage(2);
      await notifier.advancePage(3);

      // createNew pushed immediately (leading edge); the two advances fold
      // into one queued push rather than one request per swipe.
      expect(
        fake.callLog.where((c) => c == 'upsertKhatmaSession:$id').length,
        1,
      );

      await notifier.flushPendingPush();
      expect(
        fake.callLog.where((c) => c == 'upsertKhatmaSession:$id').length,
        2,
      );
      expect(fake.khatmaSessionsById[id]!['pages_read'], 2);
    });
  });

  group('account isolation', () {
    test('a second account signing in does not inherit or upload the first one\'s data', () async {
      final container = await buildContainer(
        prefsSeed: {
          'quran_data_owner': 'previous-user',
          'khatma_ex_active': _sessionJson(_session('legacy', pagesRead: 7)),
          'q_last_read': jsonEncode(_bookmark(2, 5, 4).toJson()),
          'q_bookmarks': [jsonEncode(_bookmark(1, 1, 1).toJson())],
        },
      );

      await fullSync(container);

      // Previous account's data is gone locally…
      expect(container.read(khatmaExProvider), isNull);
      expect(container.read(quranLastReadProvider), isNull);
      expect(container.read(quranBookmarksProvider), isEmpty);
      // …and was never pushed into the new account's rows.
      expect(fake.khatmaSessionsById.containsKey('legacy'), isFalse);
      expect(fake.quranLastRead, isNull);
      expect(fake.quranBookmarksByKey, isEmpty);
    });

    test('data predating ownership is adopted by the first signed-in account', () async {
      final container = await buildContainer(
        prefsSeed: {
          'khatma_ex_active': _sessionJson(_session('l1', pagesRead: 5)),
        },
      );

      await fullSync(container);

      expect(container.read(khatmaExProvider)?.id, 'l1');
      expect(fake.khatmaSessionsById.containsKey('l1'), isTrue);
    });
  });

  group('last read and bookmarks', () {
    test('a newer local last-read position is pushed, not overwritten', () async {
      final now = DateTime.now();
      final container = await buildContainer(
        prefsSeed: {
          'q_last_read': jsonEncode(
            _bookmark(2, 25, 10, at: now).toJson(),
          ),
        },
      );
      fake.quranLastRead = {
        'surah_num': 2,
        'ayah_num': 5,
        'page': 2,
        'surah_name': 'البقرة',
        'saved_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
      };

      await fullSync(container);

      expect(fake.quranLastRead!['page'], 10);
      expect(container.read(quranLastReadProvider)?.page, 10);
    });

    test('a newer remote last-read position is adopted', () async {
      final now = DateTime.now();
      final container = await buildContainer(
        prefsSeed: {
          'q_last_read': jsonEncode(
            _bookmark(2, 5, 2, at: now.subtract(const Duration(days: 1)))
                .toJson(),
          ),
        },
      );
      fake.quranLastRead = {
        'surah_num': 67,
        'ayah_num': 1,
        'page': 563,
        'surah_name': 'الملك',
        'saved_at': now.toIso8601String(),
      };

      await fullSync(container);

      expect(container.read(quranLastReadProvider)?.page, 563);
    });

    test('a bookmark saved offline is pushed on the next sync', () async {
      final container = await buildContainer(
        prefsSeed: {
          'q_bookmarks': [jsonEncode(_bookmark(18, 5, 300).toJson())],
        },
      );

      await fullSync(container);

      expect(fake.quranBookmarksByKey.containsKey('18:5'), isTrue);
    });

    test('a bookmark deleted offline stays deleted after sync', () async {
      final container = await buildContainer(
        prefsSeed: {
          'q_bookmarks': [jsonEncode(_bookmark(2, 5, 4).toJson())],
        },
      );
      fake.quranBookmarksByKey['2:5'] = {
        'surah_num': 2,
        'ayah_num': 5,
        'page': 4,
        'surah_name': 'البقرة',
        'saved_at': DateTime(2026, 1, 1).toIso8601String(),
      };

      fake.failQuranPushes = true;
      await container.read(quranBookmarksProvider.notifier).remove(2, 5);
      fake.failQuranPushes = false;

      await fullSync(container);

      expect(fake.quranBookmarksByKey.containsKey('2:5'), isFalse);
      expect(container.read(quranBookmarksProvider), isEmpty);
    });
  });
}
