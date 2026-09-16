import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_providers.dart';
import '../../core/database/app_database.dart';
import '../../features/books/providers/books_reading_provider.dart';
import '../../features/quran/providers/quran_providers.dart';
import 'supabase_config.dart';
import 'supabase_providers.dart';
import 'supabase_service.dart';
import '../providers/favorites_providers.dart';
import '../../features/settings/data/user_preferences.dart';
import '../../features/settings/providers/user_preferences_provider.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

final isSyncingProvider = StateProvider<bool>((ref) => false);

/// Non-debug-log signal for the last `fullSync()` (R6 of
/// achievements-statistics-db-persistence-fix.md): null once a sync
/// completes with no per-step failures, otherwise a joined summary of every
/// step that threw. Read by the Settings screen so a stuck/partial sync is
/// visible to the user instead of only ever appearing in `developer.log`.
final lastSyncErrorProvider = StateProvider<String?>((ref) => null);

/// Live count of entities still awaiting a retried push (the `SyncOutbox`
/// table) — the other half of R6's "surface sync health" ask. Backed by a
/// DB watch so it updates the moment a push succeeds/fails, with no manual
/// invalidation needed.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncOutboxDaoProvider).watchPendingCount();
});

final syncManagerProvider = Provider((ref) => SyncManager(ref));

/// The real connectivity check, wrapped behind a provider so tests can
/// override it without needing the connectivity_plus platform channel.
final connectivityCheckerProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  };
});

class SyncManager {
  final Ref _ref;
  SyncManager(this._ref);

  static bool _syncing = false;

  SupabaseService get _service => _ref.read(supabaseServiceProvider);

  Future<bool> get _hasConnection => _ref.read(connectivityCheckerProvider)();

  /// Full synchronization on App Start
  Future<void> fullSync() async {
    if (_syncing) return;
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    _syncing = true;
    _ref.read(isSyncingProvider.notifier).state = true;
    // R5: each step used to run inside one flat try/finally, so a throw
    // from any one of them (a schema mismatch, an RLS rejection, a dropped
    // connection mid-step) skipped every step after it — e.g. a failure
    // pulling daily records could silently mean settings/achievements/
    // reminders never synced that session either, with nothing to show for
    // it but a debug log. Isolating each step means one bad step no longer
    // takes the rest of the sync down with it.
    final stepErrors = <String>[];
    try {
      await _runStep('dailyRecords', _syncDailyRecords, stepErrors);
      await _runStep('prohibitions', _syncProhibitions, stepErrors);
      await _runStep('customIbadah', _syncCustomIbadah, stepErrors);
      await _runStep('achievements', _syncAchievements, stepErrors);
      await _runStep('settings', _syncSettings, stepErrors);
      await _runStep('stats', _syncStats, stepErrors);
      await _runStep('bookProgress', _syncBookProgress, stepErrors);
      await _runStep('reminders', _syncReminders, stepErrors);
      await _runStep('userAdhkar', _syncUserAdhkar, stepErrors);
      await _runStep('userDuas', _syncUserDuas, stepErrors);
      await _runStep('quran', _syncQuran, stepErrors);
    } finally {
      _syncing = false;
      _ref.read(isSyncingProvider.notifier).state = false;
      _ref.read(lastSyncErrorProvider.notifier).state = stepErrors.isEmpty
          ? null
          : stepErrors.join('; ');
    }
  }

  /// Runs one `fullSync()` step in isolation: a throw is logged and
  /// recorded in [stepErrors] (surfaced via [lastSyncErrorProvider]) rather
  /// than propagating and aborting every step still to come.
  Future<void> _runStep(
    String name,
    Future<void> Function() step,
    List<String> stepErrors,
  ) async {
    try {
      await step();
    } catch (e, st) {
      developer.log(
        'fullSync step "$name" failed: $e',
        name: 'SyncManager',
        stackTrace: st,
      );
      stepErrors.add('$name: $e');
    }
  }

  /// The key `SyncOutbox` rows use for a `daily_records` entity — must
  /// match `DailyRecordDao._dailyRecordOutboxKey` exactly, since a pending
  /// push and a pull for the same date need to agree on what "this date"
  /// means.
  String _dateKey(DateTime date) => date.toIso8601String().split('T')[0];

  Future<void> _syncDailyRecords() async {
    final dao = _ref.read(dailyRecordDaoProvider);
    final outbox = _ref.read(syncOutboxDaoProvider);

    // 0. Retry any previously-failed pushes first (R2). These can be older
    // than the 7-day window pushed below — e.g. the app wasn't opened again
    // for over a week after a push failed — so the plain "last 7 days" loop
    // alone wouldn't necessarily catch them back up.
    final pendingDates = await outbox.getPendingKeys('daily_records');
    for (final dateStr in pendingDates) {
      final date = DateTime.tryParse(dateStr);
      if (date == null) {
        await outbox.clearPending('daily_records', dateStr);
        continue;
      }
      final record = await dao.getRecordByDate(date);
      if (record == null) {
        // The local row this was pending for doesn't exist anymore —
        // nothing left to retry.
        await outbox.clearPending('daily_records', dateStr);
        continue;
      }
      await syncDailyRecord(record);
    }

    // 1. Push recent local records to Supabase (e.g., last 7 days)
    final localRecords = await dao.getLastNDays(7);
    for (final record in localRecords) {
      await syncDailyRecord(record);
    }

    // 2. Pull from Supabase
    final from = DateTime.now().subtract(const Duration(days: 30));
    final remoteRecords = await _service.getRecordsRange(
      from: from,
      to: DateTime.now(),
    );

    for (final record in remoteRecords) {
      await dao.upsertFromRemote(record);
    }
  }

  Future<void> _syncProhibitions() async {
    final dao = _ref.read(dailyRecordDaoProvider);
    final outbox = _ref.read(syncOutboxDaoProvider);

    // Retry any previously-failed prohibition-log pushes (R2).
    final pendingIds = await outbox.getPendingKeys('prohibitions_log');
    for (final idStr in pendingIds) {
      final id = int.tryParse(idStr);
      if (id == null) {
        await outbox.clearPending('prohibitions_log', idStr);
        continue;
      }
      final log = await dao.getProhibitionById(id);
      if (log == null) {
        await outbox.clearPending('prohibitions_log', idStr);
        continue;
      }
      await syncProhibition(log);
    }

    final from = DateTime.now().subtract(const Duration(days: 14));
    final remoteLogs = await _service.getProhibitionLogs(
      from: from,
      to: DateTime.now(),
    );

    for (final log in remoteLogs) {
      await dao.upsertProhibitionFromRemote(log);
    }
  }

  Future<void> _syncCustomIbadah() async {
    final ibadahDao = _ref.read(customIbadahDaoProvider);
    final outbox = _ref.read(syncOutboxDaoProvider);

    // Retry any previously-failed custom-ibadah-log pushes (R2).
    final pendingIds = await outbox.getPendingKeys('custom_ibadah_log');
    for (final idStr in pendingIds) {
      final id = int.tryParse(idStr);
      if (id == null) {
        await outbox.clearPending('custom_ibadah_log', idStr);
        continue;
      }
      final log = await ibadahDao.getLogById(id);
      if (log == null) {
        await outbox.clearPending('custom_ibadah_log', idStr);
        continue;
      }
      await syncCustomIbadahLog(log);
    }

    // 1. Push local logs (last 7 days)
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final localLogs = await ibadahDao.getLogsForDate(dateOnly);
      for (final log in localLogs) {
        await syncCustomIbadahLog(log);
      }
    }

    // 2. Pull from Supabase
    final remoteIbadah = await _service.getCustomIbadah();
    final remoteLogs = await _service.getCustomIbadahLogs(
      from: DateTime.now().subtract(const Duration(days: 14)),
      to: DateTime.now(),
    );

    for (final item in remoteIbadah) {
      await ibadahDao.upsertCustomIbadahFromRemote(item);
    }

    // Keep track of dates to recalc points later
    final updatedDates = <DateTime>{};
    for (final log in remoteLogs) {
      await ibadahDao.upsertCustomIbadahLogFromRemote(log);
      final dateStr = log['date'] as String;
      updatedDates.add(DateTime.parse(dateStr));
    }

    // 3. Recalculate points for all affected dates
    final dailyDao = _ref.read(dailyRecordDaoProvider);
    for (final date in updatedDates) {
      final dr = await dailyDao.getRecordByDate(date);
      if (dr != null) {
        // Ensure points are correct in the local daily_records table
        await dailyDao.recalcPoints(dr.id);

        // Fetch the recalculated record and push to Supabase
        // to keep points in sync on the remote server
        final afterRecalc = await dailyDao.getRecordByDate(date);
        if (afterRecalc != null) {
          await syncDailyRecord(afterRecalc);
        }
      }
    }
  }

  Future<void> _syncAchievements() async {
    final remoteAchievements = await _service.getEarnedAchievements();
    final statsDao = _ref.read(statsDaoProvider);
    final db = _ref.read(appDatabaseProvider);

    // 1. Pull from Supabase FIRST
    for (final data in remoteAchievements) {
      final earnedAtStr = data['earned_at'] as String?;
      final earnedAt = earnedAtStr != null
          ? DateTime.tryParse(earnedAtStr)
          : null;

      await statsDao.addAchievement(
        type: data['type'],
        titleAr: data['title_ar'] ?? '',
        descAr: data['desc_ar'] ?? '',
        emoji: data['emoji'] ?? '✨',
        pointsReward: data['points_reward'] ?? 0,
        earnedAt: earnedAt,
      );
    }

    // 2. Push local earned achievements (that might not be on Supabase yet)
    final localEarned = await (db.select(db.achievements)).get();
    for (final ach in localEarned) {
      await syncAchievement(ach);
    }
  }

  Future<void> _syncSettings() async {
    final remote = await _service.getSettings();
    final dao = _ref.read(settingsDaoProvider);

    if (remote != null) {
      // If we have remote settings, pull them down into local DB
      await dao.upsertFromRemote(remote);

      // Invalidate the preferences provider so the UI rebuilds with fresh data
      _ref.invalidate(userPreferencesProvider);

      if (remote['favorite_adhkar'] != null) {
        final adhkar = remote['favorite_adhkar'] as List<dynamic>;
        _ref.read(favoriteAdhkarProvider.notifier).syncFromRemote(adhkar);
      }
      if (remote['favorite_duas'] != null) {
        final duas = remote['favorite_duas'] as List<dynamic>;
        _ref.read(favoriteDuasProvider.notifier).syncFromRemote(duas);
      }
    } else {
      // If no remote settings exist (new user), push local defaults
      await syncSettings();
    }
  }

  Future<void> _syncStats() async {
    final stats = await _ref
        .read(statsDaoProvider)
        .getMonthStats(DateTime.now().year, DateTime.now().month);

    await _service.updateUserStats(
      totalPoints: stats.totalPoints,
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
      quranPages: stats.quranPages,
    );
  }

  /// Single record sync (call after local update)
  Future<void> syncDailyRecord(DailyRecord record) async {
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    try {
      await _service.upsertDailyRecord({
        'date': record.date.toIso8601String().split('T')[0],
        'fajr_status': record.fajrStatus.name,
        'dhuhr_status': record.dhuhrStatus.name,
        'asr_status': record.asrStatus.name,
        'maghrib_status': record.maghribStatus.name,
        'isha_status': record.ishaStatus.name,
        'night_prayer': record.nightPrayer,
        'witr': record.witr,
        'rawatib': record.rawatib,
        'quran_pages': record.quranPages,
        'quran_verses': record.quranVerses,
        'quran_juzaa': record.quranJuzaa,
        'morning_adhkar': record.morningAdhkar,
        'evening_adhkar': record.eveningAdhkar,
        'after_prayer_adhkar': record.afterPrayerAdhkar,
        'tasbeeh_count': record.tasbeehCount,
        'fasting_type': record.fastingType.name,
        'sadaqah': record.sadaqah,
        // 'ghadh_basar' is intentionally still omitted: unlike the other
        // fields uncommented above (which docs/schema.sql confirms already
        // exist on the remote `daily_records` table), `ghadh_basar` is not
        // in that remote schema yet — sending it would throw "column does
        // not exist". Needs an actual Supabase migration before it can be
        // pushed (see achievements-statistics-db-persistence-fix.md R4).
        // 'ghadh_basar': record.ghadhBasar,
        'sadaqah_amount': record.sadaqahAmount,
        'net_points': record.netPoints,
        'taqwa_points': record.taqwaPoints,
        'deducted_points': record.deductedPoints,
        'mood': record.mood,
        'notes': record.notes,
      });
      await _ref.read(syncOutboxDaoProvider).clearPending('daily_records', _dateKey(record.date));
    } catch (e) {
      developer.log('syncDailyRecord exception: $e', name: 'SyncManager');
      await _ref
          .read(syncOutboxDaoProvider)
          .markPending('daily_records', _dateKey(record.date), e.toString());
    }
  }

  /// Sync newly earned achievement
  Future<void> syncAchievement(Achievement achievement) async {
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    final key = achievement.id.toString();
    try {
      await _service.upsertAchievement({
        'type': achievement.type,
        'title_ar': achievement.titleAr,
        'desc_ar': achievement.descAr,
        'emoji': achievement.emoji,
        'points_reward': achievement.pointsReward,
        'earned_at': achievement.earnedAt.toIso8601String(),
      });
      await _ref.read(syncOutboxDaoProvider).clearPending('achievements', key);
    } catch (e) {
      developer.log('syncAchievement exception: $e', name: 'SyncManager');
      await _ref
          .read(syncOutboxDaoProvider)
          .markPending('achievements', key, e.toString());
    }
  }

  /// Sync prohibition log
  Future<void> syncProhibition(ProhibitionsLogData log) async {
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    final key = log.id.toString();
    try {
      await _service.upsertProhibitionLog({
        'record_id': log.recordId,
        'date': log.date.toIso8601String().split('T')[0],
        'category': log.category.name,
        'committed': log.committed,
        'times_count': log.timesCount,
        'deduct_points': log.deductPoints,
        'notes': log.notes,
      });
      await _ref
          .read(syncOutboxDaoProvider)
          .clearPending('prohibitions_log', key);
    } catch (e) {
      developer.log('syncProhibition exception: $e', name: 'SyncManager');
      await _ref
          .read(syncOutboxDaoProvider)
          .markPending('prohibitions_log', key, e.toString());
    }
  }

  /// Sync custom ibadah
  Future<void> syncCustomIbadah(CustomIbadahData ibadah) async {
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    await _service.upsertCustomIbadah({
      'id': ibadah.id,
      'name_ar': ibadah.nameAr,
      'emoji': ibadah.emoji,
      'is_positive': ibadah.isPositive,
      'points': ibadah.points,
      'is_active': ibadah.isActive,
      'sort_order': ibadah.sortOrder,
    });
  }

  /// Delete custom ibadah
  Future<void> deleteCustomIbadah(int id) async {
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    try {
      await _service.deleteCustomIbadah(id);
    } catch (e) {
      // Log or handle error
    }
  }

  /// Sync custom ibadah log
  Future<void> syncCustomIbadahLog(CustomIbadahLogData log) async {
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    final outbox = _ref.read(syncOutboxDaoProvider);
    final key = log.id.toString();

    try {
      await _service.upsertCustomIbadahLog({
        'ibadah_id': log.ibadahId,
        'date': log.date.toIso8601String().split('T')[0],
        'done': log.done,
        'count': log.count,
      });

      // Also sync the daily record to update points on remote
      final dailyDao = _ref.read(dailyRecordDaoProvider);
      final dr = await dailyDao.getRecordByDate(log.date);
      if (dr != null) {
        await syncDailyRecord(dr);
      }
      await outbox.clearPending('custom_ibadah_log', key);
    } catch (e) {
      if (e.toString().contains('23503')) {
        // Foreign key violation: custom_ibadah might be missing on remote
        try {
          final dao = _ref.read(customIbadahDaoProvider);
          final ibadahItems = await dao.getAllIbadat();
          final ibadah = ibadahItems
              .where((i) => i.id == log.ibadahId)
              .firstOrNull;

          if (ibadah != null) {
            await syncCustomIbadah(ibadah);
            // Retry log sync
            await _service.upsertCustomIbadahLog({
              'ibadah_id': log.ibadahId,
              'date': log.date.toIso8601String().split('T')[0],
              'done': log.done,
              'count': log.count,
            });

            // Also sync daily record on retry
            final dailyDao = _ref.read(dailyRecordDaoProvider);
            final dr = await dailyDao.getRecordByDate(log.date);
            if (dr != null) {
              await syncDailyRecord(dr);
            }
            await outbox.clearPending('custom_ibadah_log', key);
            return;
          }
        } catch (retryError) {
          developer.log(
            'syncCustomIbadahLog retry exception: $retryError',
            name: 'SyncManager',
          );
        }
      }
      await outbox.markPending('custom_ibadah_log', key, e.toString());
    }
  }

  /// Sync all local settings to Supabase
  Future<void> syncSettings() async {
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    _ref.read(isSyncingProvider.notifier).state = true;
    try {
      final dao = _ref.read(settingsDaoProvider);
      final settings = await dao.getAllSettings();
      if (settings.isNotEmpty) {
        final prefs = UserPreferences.fromMap(settings);
        await _service.updateSettings(prefs.toMap());
      }
    } finally {
      _ref.read(isSyncingProvider.notifier).state = false;
    }
  }

  Future<void> _syncBookProgress() async {
    try {
      await _ref.read(readingProgressProvider.notifier).syncFromRemote();
    } catch (e) {
      developer.log('Failed to sync book progress: $e', name: 'SyncManager');
    }
  }

  Future<void> _syncReminders() async {
    try {
      final remoteReminders = await _service.getReminders();
      final dao = _ref.read(remindersDaoProvider);

      for (final remote in remoteReminders) {
        // Upsert remote into local DB
        // We need a method in RemindersDao to handle this
        await dao.upsertFromRemote(remote);
      }
    } catch (e) {
      developer.log('Failed to sync reminders: $e', name: 'SyncManager');
    }
  }

  /// Sync local reminder to remote
  Future<void> syncReminder(Reminder reminder) async {
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    await _service.upsertReminder({
      'local_id': reminder.id,
      'title': reminder.title,
      'icon_name': reminder.iconName,
      'time': reminder.time,
      'is_enabled': reminder.isEnabled,
    });
  }

  Future<void> deleteReminder(int localId) async {
    final isOnline = await _hasConnection;
    final isAuth = _ref.read(currentUserProvider) != null;
    if (!isOnline || !isAuth) return;

    await _service.deleteReminder(localId);
  }

  Future<void> _syncUserAdhkar() async {
    try {
      final remoteItems = await _service.getUserAdhkar();
      final dao = _ref.read(userAdhkarDaoProvider);

      for (final remote in remoteItems) {
        await dao.upsertFromRemote(remote);
      }
    } catch (e) {
      developer.log('Failed to sync user adhkar: $e', name: 'SyncManager');
    }
  }

  Future<void> _syncUserDuas() async {
    try {
      final remoteItems = await _service.getUserDuas();
      final dao = _ref.read(userDuasDaoProvider);

      for (final remote in remoteItems) {
        await dao.upsertFromRemote(remote);
      }
    } catch (e) {
      developer.log('Failed to sync user duas: $e', name: 'SyncManager');
    }
  }

  /// Pulls Quran bookmarks, the last-read position, and Khatma sessions
  /// from Supabase. Pushing local changes back happens as they occur (see
  /// quran_providers.dart's notifiers), so this side only needs to pull —
  /// same split as _syncBookProgress/readingProgressProvider.
  Future<void> _syncQuran() async {
    try {
      await _ref.read(quranLastReadProvider.notifier).syncFromRemote();
      await _ref.read(quranBookmarksProvider.notifier).syncFromRemote();
      await _ref.read(khatmaExProvider.notifier).syncFromRemote();
    } catch (e) {
      developer.log('Failed to sync quran data: $e', name: 'SyncManager');
    }
  }
}
