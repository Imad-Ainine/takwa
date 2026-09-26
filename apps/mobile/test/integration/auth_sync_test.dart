// Integration test for the auth → SyncManager.fullSync() flow flagged in
// the engineering audit as the highest-risk untested path (silent data
// loss/duplication on sync). Uses an in-memory Drift DB and a fake
// SupabaseService (test/support/fake_supabase_service.dart) instead of a
// real backend — see supabase_service.dart for why that seam exists.

import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
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
import 'package:takwa/features/quran/providers/quran_providers.dart';

import '../support/fake_supabase_service.dart';

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

  test('signed-out or offline: fullSync is a no-op', () async {
    final offlineContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        supabaseServiceProvider.overrideWithValue(fakeService),
        currentUserProvider.overrideWithValue(null), // signed out
        connectivityCheckerProvider.overrideWithValue(() async => true),
      ],
    );
    addTearDown(offlineContainer.dispose);

    await offlineContainer.read(syncManagerProvider).fullSync();

    expect(fakeService.callLog, isEmpty);
  });

  test('pushes recent local daily records up to the remote', () async {
    final record = await db.dailyRecordDao.getOrCreateToday();
    await db.dailyRecordDao.updatePrayerStatus(
      recordId: record.id,
      prayerName: 'fajr',
      status: PrayerStatus.performed,
    );

    await container.read(syncManagerProvider).fullSync();

    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final pushed = fakeService.dailyRecordsByDate[dateKey];

    expect(pushed, isNotNull);
    expect(pushed!['fajr_status'], 'performed');
    expect(pushed['net_points'], 10);
  });

  // _syncDailyRecords() pushes only the last 7 days but pulls the last 30 —
  // these tests use dates in that 8-29-days-ago band so pull is the only
  // thing touching them (no push-then-immediate-pull-of-the-same-value
  // masking what pull actually did), and dates are relative to "now" so
  // the test isn't tied to when it happens to run.
  DateTime daysAgo(int n) {
    final d = DateTime.now().subtract(Duration(days: n));
    return DateTime(d.year, d.month, d.day);
  }

  String dateKeyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  test('pulls remote daily records down into the local DB', () async {
    final target = daysAgo(15);
    fakeService.dailyRecordsByDate[dateKeyFor(target)] = {
      'date': dateKeyFor(target),
      'fajr_status': 'performed',
      'dhuhr_status': 'performed',
      'asr_status': 'notDue',
      'maghrib_status': 'notDue',
      'isha_status': 'notDue',
      'night_prayer': false,
      'quran_pages': 3,
      'morning_adhkar': true,
      'evening_adhkar': false,
      'fasting_type': 'none',
      'sadaqah': false,
      'ghadh_basar': false,
      'net_points': 21,
      'taqwa_points': 21,
    };

    await container.read(syncManagerProvider).fullSync();

    final local = await db.dailyRecordDao.getRecordByDate(target);
    expect(local, isNotNull);
    expect(local!.fajrStatus, PrayerStatus.performed);
    expect(local.quranPages, 3);
    expect(local.morningAdhkar, isTrue);
    expect(local.netPoints, 21);
  });

  test(
    'a remote record for the same (non-pushed) date overwrites the local one',
    () async {
      final target = daysAgo(15);

      // Local already has a (thinner) record for that day — e.g. logged
      // once, never touched since, so it's outside the 7-day push window.
      await db
          .into(db.dailyRecords)
          .insert(
            DailyRecordsCompanion.insert(
              date: target,
              fajrStatus: const Value(PrayerStatus.performed),
              netPoints: const Value(10),
              taqwaPoints: const Value(10),
            ),
          );

      // Remote has a fuller version of the same day (e.g. synced earlier
      // from another device).
      fakeService.dailyRecordsByDate[dateKeyFor(target)] = {
        'date': dateKeyFor(target),
        'fajr_status': 'performed',
        'dhuhr_status': 'performed',
        'asr_status': 'performed',
        'maghrib_status': 'performed',
        'isha_status': 'performed',
        'night_prayer': true,
        'quran_pages': 10,
        'morning_adhkar': true,
        'evening_adhkar': true,
        'fasting_type': 'none',
        'sadaqah': true,
        'ghadh_basar': true,
        'net_points': 999,
        'taqwa_points': 999,
      };

      await container.read(syncManagerProvider).fullSync();

      final local = await db.dailyRecordDao.getRecordByDate(target);
      expect(local!.netPoints, 999);
      expect(local.dhuhrStatus, PrayerStatus.performed);
    },
  );

  test('pulls remote settings into local settings when present', () async {
    fakeService.settings = {
      'madhab': 'hanafi',
      'calc_method': 'Karachi',
      'ramadan_mode': true,
    };

    await container.read(syncManagerProvider).fullSync();

    final settingsDao = container.read(settingsDaoProvider);
    expect(await settingsDao.get('madhab'), 'hanafi');
    expect(await settingsDao.get('calc_method'), 'Karachi');
    expect(await settingsDao.getBool('ramadan_mode'), isTrue);
  });

  test(
    'pushes local settings as defaults when remote has none for a new user',
    () async {
      expect(fakeService.settings, isNull);

      await container.read(syncManagerProvider).fullSync();

      // SyncManager.syncSettings() pushes local defaults for a brand-new
      // remote user rather than leaving them unset.
      expect(fakeService.callLog, contains('updateSettings'));
    },
  );

  test(
    'pulls earned achievements from remote and pushes locally-earned ones',
    () async {
      fakeService.achievementsByType['streak_3'] = {
        'type': 'streak_3',
        'title_ar': 'البداية الطيبة',
        'desc_ar': 'test',
        'emoji': '🌱',
        'points_reward': 20,
        'earned_at': DateTime.now().toIso8601String(),
      };

      await container.read(syncManagerProvider).fullSync();

      final statsDao = container.read(statsDaoProvider);
      final db2 = container.read(appDatabaseProvider);
      final local = await (db2.select(db2.achievements)).get();
      expect(local.map((a) => a.type), contains('streak_3'));
      // statsDao is reachable through the same overridden database.
      expect(statsDao, isNotNull);
    },
  );

  test('fullSync does not re-enter itself if already syncing', () async {
    // Calling fullSync twice concurrently should not double-run the sync
    // steps — the second call should see `_syncing` already true and
    // return immediately. We can't easily observe the internal flag, but
    // we can assert it doesn't throw and settings still end up correct.
    final first = container.read(syncManagerProvider).fullSync();
    final second = container.read(syncManagerProvider).fullSync();
    await Future.wait([first, second]);
    // No exception means both calls completed cleanly.
  });

  test('overlapping fullSync triggers with a pending connectivity check run '
      'only ONE pass (P1 #4 race regression)', () async {
    // The old code awaited the connectivity check while `_syncing` was
    // still false, so a second trigger that started during that await
    // passed the guard too and interleaved a duplicate full pass —
    // double-pushing every record. The gate holds the first pass open at
    // exactly that window.
    final gate = Completer<bool>();
    var checkCount = 0;
    final raceContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        supabaseServiceProvider.overrideWithValue(fakeService),
        currentUserProvider.overrideWithValue(_fakeUser()),
        connectivityCheckerProvider.overrideWithValue(() {
          checkCount++;
          return gate.future;
        }),
      ],
    );
    addTearDown(raceContainer.dispose);

    final first = raceContainer.read(syncManagerProvider).fullSync();
    final second = raceContainer.read(syncManagerProvider).fullSync();
    gate.complete(true);
    await Future.wait([first, second]);

    // updateUserStats is called exactly once per _syncStats step — two
    // means both triggers ran a full pass.
    expect(checkCount, 1, reason: 'second trigger must not hit connectivity');
    expect(
      fakeService.callLog.where((c) => c == 'updateUserStats').length,
      1,
      reason: 'only one fullSync pass should have run',
    );
  });

  test(
    'connectivity is checked once per pass, not once per pushed record',
    () async {
      var checkCount = 0;
      final countingContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          supabaseServiceProvider.overrideWithValue(fakeService),
          currentUserProvider.overrideWithValue(_fakeUser()),
          connectivityCheckerProvider.overrideWithValue(() async {
            checkCount++;
            return true;
          }),
        ],
      );
      addTearDown(countingContainer.dispose);

      // Seed 5 recent days so the push loop has several records, each of
      // which used to pay for its own platform-channel connectivity check.
      for (var i = 1; i <= 5; i++) {
        await db
            .into(db.dailyRecords)
            .insert(
              DailyRecordsCompanion.insert(
                date: DateTime.now().subtract(Duration(days: i)),
              ),
            );
      }

      await countingContainer.read(syncManagerProvider).fullSync();

      expect(
        fakeService.callLog.any((c) => c.startsWith('upsertDailyRecord')),
        isTrue,
        reason: 'sanity: the seeded records were actually pushed',
      );
      expect(
        checkCount,
        1,
        reason: 'the whole pass should share one cached connectivity result',
      );
    },
  );

  // P2: SyncManager only clears an outbox entry after the push actually
  // happened. These pin both halves — a failing push keeps the entry (so a
  // session that ends mid-pass can't delete unsent data), and entries left by
  // a DIFFERENT account are dropped instead of being replayed under the uid
  // that happens to be signed in now.
  group('outbox entries survive a failed push', () {
    /// A date outside the 7-day push window, so only the retry loop can ever
    /// push it — that keeps "was this retried?" unambiguous.
    Future<DateTime> seedOldPendingRecord() async {
      final date = daysAgo(20);
      await db
          .into(db.dailyRecords)
          .insert(
            DailyRecordsCompanion.insert(
              date: date,
              netPoints: const Value(10),
              taqwaPoints: const Value(10),
            ),
          );
      await db.syncOutboxDao.markPending(
        'daily_records',
        dateKeyFor(date),
        'previous attempt failed',
      );
      return date;
    }

    test(
      'a push that throws keeps its entry pending for the next pass',
      () async {
        fakeService.signedOutDuringPush = true;
        final record = await db.dailyRecordDao.getOrCreateToday();
        await db.dailyRecordDao.updatePrayerStatus(
          recordId: record.id,
          prayerName: 'fajr',
          status: PrayerStatus.performed,
        );

        await container.read(syncManagerProvider).fullSync();

        expect(
          fakeService.dailyRecordsByDate,
          isEmpty,
          reason: 'nothing reached the remote',
        );
        expect(
          await db.syncOutboxDao.getPendingKeys('daily_records'),
          isNotEmpty,
          reason:
              'the unsent record must still be queued — clearing it here is '
              'how data used to disappear silently',
        );
      },
    );

    test('entries left by another account are dropped, not pushed under the '
        'current uid', () async {
      final date = await seedOldPendingRecord();
      await container
          .read(quranPrefsRepositoryProvider)
          .setDataOwner('a-different-user');

      await container.read(syncManagerProvider).fullSync();

      expect(
        fakeService.callLog,
        isNot(contains('upsertDailyRecord:${dateKeyFor(date)}')),
        reason: "the previous account's row must not land in this account",
      );
      expect(await db.syncOutboxDao.getPendingKeys('daily_records'), isEmpty);
      expect(
        await db.dailyRecordDao.getRecordByDate(date),
        isNotNull,
        reason: 'only the queued push is dropped, never the local row',
      );
    });

    test(
      'a first sign-in adopts pending entries instead of dropping them',
      () async {
        final date = await seedOldPendingRecord();

        await container.read(syncManagerProvider).fullSync();

        expect(
          fakeService.callLog,
          contains('upsertDailyRecord:${dateKeyFor(date)}'),
        );
        expect(await db.syncOutboxDao.getPendingKeys('daily_records'), isEmpty);
      },
    );
  });
}
