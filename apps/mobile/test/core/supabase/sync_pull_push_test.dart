// P3 #17: the pull half of SyncManager._syncDailyRecords.
//
// R3 (a date whose push is still owed must be skipped by the pull) is
// implemented in DailyRecordDao.upsertFromRemote, not in SyncManager — so
// it can only be exercised end-to-end through fullSync. Without the skip, a
// stale remote copy of a half-synced day overwrites the local row that the
// failed push was meant to fix: "log a day, it's gone the next morning".

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/providers/shared_preferences_provider.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/supabase/supabase_providers.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_service.dart';

User _fakeUser() => User(
  id: 'test-user-id',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
);

void main() {
  late AppDatabase db;
  late FakeSupabaseService fakeService;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeService = FakeSupabaseService();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseServiceProvider.overrideWithValue(fakeService),
        currentUserProvider.overrideWithValue(_fakeUser()),
        connectivityCheckerProvider.overrideWithValue(() async => true),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() async {
    await db.close();
  });

  DateTime daysAgo(int n) {
    final d = DateTime.now().subtract(Duration(days: n));
    return DateTime(d.year, d.month, d.day);
  }

  String dateKeyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// A local row with a fixed net_points, so a value that comes back
  /// different can only have arrived through the pull.
  Future<void> seedLocal(DateTime date, int netPoints) async {
    await db
        .into(db.dailyRecords)
        .insert(
          DailyRecordsCompanion.insert(
            date: date,
            netPoints: Value(netPoints),
            taqwaPoints: Value(netPoints),
          ),
        );
  }

  /// A remote row in the shape PostgREST returns. Deliberately carries no
  /// `updated_at`: with no freshness signal, `upsertFromRemote`'s only
  /// reason not to overwrite is the pending-push check.
  Map<String, dynamic> remoteRecord(DateTime date, int netPoints) => {
    'date': dateKeyFor(date),
    'fajr_status': 'performed',
    'net_points': netPoints,
    'taqwa_points': netPoints,
  };

  Future<int?> localPoints(DateTime date) async =>
      (await db.dailyRecordDao.getRecordByDate(date))?.netPoints;

  group('pull defers to what the outbox still owes', () {
    test('a date with a push still owed keeps its local values, then catches '
        'up on the pass where the push succeeds', () async {
      final today = daysAgo(0);
      await seedLocal(today, 30);
      // Another device's older version of the same day, already on the
      // remote and about to be pulled down on top of local.
      fakeService.dailyRecordsByDate[dateKeyFor(today)] = remoteRecord(
        today,
        1,
      );

      // The push fails, so syncDailyRecord queues today under the key it
      // generated itself (SyncManager._dateKey) rather than a key this
      // test hand-wrote — which also pins the two key builders agreeing.
      fakeService.signedOutDuringPush = true;
      await container.read(syncManagerProvider).fullSync();

      expect(
        await db.syncOutboxDao.getPendingKeys('daily_records'),
        contains(dateKeyFor(today)),
        reason: 'sanity: the failed push queued this date',
      );
      expect(
        await localPoints(today),
        30,
        reason: 'the stale remote row must not replace un-pushed local data',
      );

      // Connection back: the queued push runs first, clears its entry,
      // and the remote is the one that ends up catching up.
      fakeService.signedOutDuringPush = false;
      await container.read(syncManagerProvider).fullSync();

      expect(
        fakeService.dailyRecordsByDate[dateKeyFor(today)]!['net_points'],
        30,
        reason: 'the retried push carries the local values up',
      );
      expect(await db.syncOutboxDao.getPendingKeys('daily_records'), isEmpty);
      expect(await localPoints(today), 30);
    });

    test('the skip is keyed by date, not by table', () async {
      final owed = daysAgo(20);
      final other = daysAgo(15);
      await seedLocal(owed, 42);
      await db.syncOutboxDao.markPending(
        'daily_records',
        dateKeyFor(owed),
        'previous attempt failed',
      );
      fakeService.signedOutDuringPush = true; // the retry fails; entry stays
      // Both dates have a stale remote copy waiting to be pulled; only the
      // one that still owes a push may be skipped.
      fakeService.dailyRecordsByDate[dateKeyFor(owed)] = remoteRecord(owed, 5);
      fakeService.dailyRecordsByDate[dateKeyFor(other)] = remoteRecord(
        other,
        77,
      );

      await container.read(syncManagerProvider).fullSync();

      expect(await localPoints(owed), 42, reason: 'the owed date is protected');
      expect(
        await localPoints(other),
        77,
        reason:
            "a date with nothing pending pulls normally — one day's "
            'failed push must not freeze the whole 30-day pull',
      );
    });

    test('entries that can never be pushed again are dropped', () async {
      // A date whose local row no longer exists, and a key that isn't even
      // a date. Both are unretryable, and leaving them would pin
      // pendingSyncCountProvider — the Settings screen's "N items waiting
      // to sync" badge — at a number that can never reach zero.
      await db.syncOutboxDao.markPending('daily_records', '2019-03-04', 'gone');
      await db.syncOutboxDao.markPending('daily_records', 'not-a-date', 'junk');

      await container.read(syncManagerProvider).fullSync();

      expect(await db.syncOutboxDao.getPendingKeys('daily_records'), isEmpty);
      expect(
        fakeService.callLog,
        isNot(contains('upsertDailyRecord:2019-03-04')),
      );
    });
  });

  // `_syncProhibitions` has no recent-days push loop at all: the outbox
  // retry is the only path that ever sends a prohibition that failed the
  // first time, so a lost entry there is lost permanently.
  group('prohibition pushes are replayed from the outbox', () {
    test('an entry left by a failed push is sent and then cleared', () async {
      final record = await db.dailyRecordDao.getOrCreateToday();
      await db.dailyRecordDao.logProhibition(
        recordId: record.id,
        category: ProhibitionCategory.kadhb,
        committed: true,
      );
      final log = (await db.dailyRecordDao.getTodayProhibitions(
        record.id,
      )).single;
      await db.syncOutboxDao.markPending(
        'prohibitions_log',
        '${log.id}',
        'previous attempt failed',
      );

      await container.read(syncManagerProvider).fullSync();

      expect(fakeService.callLog, contains('upsertProhibitionLog'));
      expect(
        fakeService.prohibitionLogs.single['category'],
        ProhibitionCategory.kadhb.name,
      );
      expect(
        await db.syncOutboxDao.getPendingKeys('prohibitions_log'),
        isEmpty,
      );
    });

    test(
      'an entry whose local row is gone is dropped without a push',
      () async {
        await db.syncOutboxDao.markPending(
          'prohibitions_log',
          '999999',
          'gone',
        );

        await container.read(syncManagerProvider).fullSync();

        expect(
          fakeService.callLog,
          isNot(contains('upsertProhibitionLog')),
          reason: 'nothing to send — the row it referred to was deleted',
        );
        expect(
          await db.syncOutboxDao.getPendingKeys('prohibitions_log'),
          isEmpty,
        );
      },
    );
  });
}
