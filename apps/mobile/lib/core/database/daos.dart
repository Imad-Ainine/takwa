import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:takwa/l10n/app_localizations.dart';
import 'app_database.dart';
part 'daos.g.dart';

// ─────────────────────────────────────────
//  DAO 1: DailyRecordDao
// ─────────────────────────────────────────
@DriftAccessor(
  tables: [
    DailyRecords,
    ProhibitionsLog,
    CustomIbadahLog,
    CustomIbadah,
    SyncOutbox,
  ],
)
class DailyRecordDao extends DatabaseAccessor<AppDatabase>
    with _$DailyRecordDaoMixin {
  DailyRecordDao(super.db);

  Future<DailyRecord?> getTodayRecord() {
    final today = _dateOnly(DateTime.now());
    return (select(
      dailyRecords,
    )..where((r) => r.date.equals(today))).getSingleOrNull();
  }

  Future<DailyRecord> getOrCreateToday() async {
    final now = DateTime.now();
    final today = _dateOnly(now);

    // Atomic insert Or Ignore to handle race conditions
    await into(dailyRecords).insert(
      DailyRecordsCompanion(date: Value(today)),
      mode: InsertMode.insertOrIgnore,
    );

    // Fetch the record (either newly created or existed)
    return (select(
      dailyRecords,
    )..where((r) => r.date.equals(today))).getSingle();
  }

  Future<void> updatePrayerStatus({
    required int recordId,
    required String prayerName,
    required PrayerStatus status,
  }) async {
    final companion = _prayerCompanion(prayerName, status);
    await transaction(() async {
      await (update(
        dailyRecords,
      )..where((r) => r.id.equals(recordId))).write(companion);
      await recalcPoints(recordId);
    });
  }

  Future<void> updateQuran({
    required int recordId,
    int? pages,
    double? juzaa,
  }) async {
    await transaction(() async {
      await (update(dailyRecords)..where((r) => r.id.equals(recordId))).write(
        DailyRecordsCompanion(
          quranPages: pages != null ? Value(pages) : const Value.absent(),
          quranJuzaa: juzaa != null ? Value(juzaa) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await recalcPoints(recordId);
    });
  }

  Future<void> updateQuranPages(int recordId, int pages) =>
      updateQuran(recordId: recordId, pages: pages);

  Future<void> updateAdhkar({
    required int recordId,
    bool? morning,
    bool? evening,
    bool? afterPrayer,
  }) async {
    await transaction(() async {
      await (update(dailyRecords)..where((r) => r.id.equals(recordId))).write(
        DailyRecordsCompanion(
          morningAdhkar: morning != null
              ? Value(morning)
              : const Value.absent(),
          eveningAdhkar: evening != null
              ? Value(evening)
              : const Value.absent(),
          afterPrayerAdhkar: afterPrayer != null
              ? Value(afterPrayer)
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await recalcPoints(recordId);
    });
  }

  Future<void> toggleAdhkar(int recordId, String key, bool value) {
    return updateAdhkar(
      recordId: recordId,
      morning: key == 'morning' ? value : null,
      evening: key == 'evening' ? value : null,
      afterPrayer: key == 'afterPrayer' ? value : null,
    );
  }

  Future<void> toggleSadaqah(int recordId, bool value) async {
    await transaction(() async {
      await (update(dailyRecords)..where((r) => r.id.equals(recordId))).write(
        DailyRecordsCompanion(
          sadaqah: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await recalcPoints(recordId);
    });
  }

  Future<void> toggleNightPrayer(int recordId, bool value) async {
    await transaction(() async {
      await (update(dailyRecords)..where((r) => r.id.equals(recordId))).write(
        DailyRecordsCompanion(
          nightPrayer: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await recalcPoints(recordId);
    });
  }

  Future<void> updateFasting(int recordId, FastingType type) async {
    await transaction(() async {
      await (update(dailyRecords)..where((r) => r.id.equals(recordId))).write(
        DailyRecordsCompanion(
          fastingType: Value(type),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await recalcPoints(recordId);
    });
  }

  Future<void> toggleGhadhBasar(int recordId, bool value) async {
    await transaction(() async {
      await (update(dailyRecords)..where((r) => r.id.equals(recordId))).write(
        DailyRecordsCompanion(
          ghadhBasar: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await recalcPoints(recordId);
    });
  }

  Future<void> logProhibition({
    required int recordId,
    required ProhibitionCategory category,
    required bool committed,
    int timesCount = 0,
    int deductPoints = 10,
    String? notes,
  }) async {
    await transaction(() async {
      final existing =
          await (select(prohibitionsLog)..where(
                (p) =>
                    p.recordId.equals(recordId) &
                    p.category.equals(category.index),
              ))
              .getSingleOrNull();

      if (existing != null) {
        await (update(
          prohibitionsLog,
        )..where((p) => p.id.equals(existing.id))).write(
          ProhibitionsLogCompanion(
            committed: Value(committed),
            timesCount: Value(timesCount),
            notes: Value(notes),
          ),
        );
      } else {
        await into(prohibitionsLog).insert(
          ProhibitionsLogCompanion(
            recordId: Value(recordId),
            date: Value(DateTime.now()),
            category: Value(category),
            committed: Value(committed),
            timesCount: Value(timesCount),
            deductPoints: Value(deductPoints),
            notes: Value(notes),
          ),
        );
      }
      await recalcPoints(recordId);
    });
  }

  Future<List<ProhibitionsLogData>> getTodayProhibitions(int recordId) {
    return (select(
      prohibitionsLog,
    )..where((p) => p.recordId.equals(recordId))).get();
  }

  /// Looks up a single prohibition-log row by its local id — used by
  /// `SyncManager._syncProhibitions` to retry a push that's pending in the
  /// `SyncOutbox` (see achievements-statistics-db-persistence-fix.md R2).
  Future<ProhibitionsLogData?> getProhibitionById(int id) {
    return (select(
      prohibitionsLog,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<DailyRecord?> getRecordByDate(DateTime date) {
    return (select(
      dailyRecords,
    )..where((r) => r.date.equals(_dateOnly(date)))).getSingleOrNull();
  }

  Future<List<DailyRecord>> getLastNDays(int n) {
    final from = DateTime.now().subtract(Duration(days: n));
    return (select(dailyRecords)
          ..where((r) => r.date.isBiggerOrEqualValue(from))
          ..orderBy([(r) => OrderingTerm.desc(r.date)]))
        .get();
  }

  Stream<DailyRecord?> watchTodayRecord() {
    final today = _dateOnly(DateTime.now());
    return (select(
      dailyRecords,
    )..where((r) => r.date.equals(today))).watchSingleOrNull();
  }

  /// Recomputes and persists a day's points using the shared Taqwa points
  /// model in `package:takwa_core` — see that package for the scoring
  /// rules themselves; this method's job is just gathering this record's
  /// inputs (prayers, prohibitions, custom ibadah) and writing the result.
  Future<void> recalcPoints(int recordId) async {
    final record = await (select(
      dailyRecords,
    )..where((r) => r.id.equals(recordId))).getSingle();

    final prohibs = await getTodayProhibitions(recordId);

    final customLogs = await (select(customIbadahLog).join([
      innerJoin(
        customIbadah,
        customIbadah.id.equalsExp(customIbadahLog.ibadahId),
      ),
    ])..where(customIbadahLog.recordId.equals(recordId))).get();

    final result = calculateDailyPoints(
      DailyPointsInput(
        fajrStatus: record.fajrStatus,
        dhuhrStatus: record.dhuhrStatus,
        asrStatus: record.asrStatus,
        maghribStatus: record.maghribStatus,
        ishaStatus: record.ishaStatus,
        nightPrayer: record.nightPrayer,
        witr: record.witr,
        rawatib: record.rawatib,
        quranPages: record.quranPages,
        quranJuzaa: record.quranJuzaa,
        morningAdhkar: record.morningAdhkar,
        eveningAdhkar: record.eveningAdhkar,
        afterPrayerAdhkar: record.afterPrayerAdhkar,
        fastingType: record.fastingType,
        sadaqah: record.sadaqah,
        ghadhBasar: record.ghadhBasar,
        prohibitions: [
          for (final p in prohibs)
            ProhibitionEntry(
              committed: p.committed,
              deductPoints: p.deductPoints,
              timesCount: p.timesCount,
            ),
        ],
        customIbadah: [
          for (final row in customLogs)
            CustomIbadahEntry(
              done: row.readTable(customIbadahLog).done,
              isPositive: row.readTable(customIbadah).isPositive,
              points: row.readTable(customIbadah).points,
              count: row.readTable(customIbadahLog).count,
            ),
        ],
      ),
    );

    await (update(dailyRecords)..where((r) => r.id.equals(recordId))).write(
      DailyRecordsCompanion(
        taqwaPoints: Value(result.earnedPoints),
        deductedPoints: Value(result.deductedPoints),
        netPoints: Value(result.netPoints),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DailyRecordsCompanion _prayerCompanion(String name, PrayerStatus s) {
    final v = Value<PrayerStatus>(s);
    return switch (name) {
      'fajr' => DailyRecordsCompanion(fajrStatus: v),
      'dhuhr' => DailyRecordsCompanion(dhuhrStatus: v),
      'asr' => DailyRecordsCompanion(asrStatus: v),
      'maghrib' => DailyRecordsCompanion(maghribStatus: v),
      'isha' => DailyRecordsCompanion(ishaStatus: v),
      _ => const DailyRecordsCompanion(),
    };
  }

  /// Safely coerce a dynamic JSON value to [int].
  /// Supabase may return integer fields as [String] in some responses.
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Safely coerce a dynamic JSON value to [bool].
  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  /// Safely coerce a dynamic JSON value to [double].
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  /// The key `SyncOutbox` rows use for a `daily_records` entity — matches
  /// the date string `SyncManager.syncDailyRecord`/`_dateKey` pushes with,
  /// so a pending push for a date and a pull for that same date agree on
  /// what "this date" means.
  String _dailyRecordOutboxKey(DateTime date) =>
      date.toIso8601String().split('T')[0];

  /// Parses a Supabase timestamp value (ISO 8601 string, or already a
  /// [DateTime]) into a [DateTime]. Returns null if missing/unparseable —
  /// callers should then treat the remote record as having no reliable
  /// freshness signal (see [upsertFromRemote]).
  DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  PrayerStatus _parsePrayerStatus(dynamic v) {
    if (v == null) return PrayerStatus.notDue;
    if (v is int) {
      if (v >= 0 && v < PrayerStatus.values.length) {
        return PrayerStatus.values[v];
      }
      return PrayerStatus.notDue;
    }
    final String s = v.toString().replaceFirst('PrayerStatus.', '');
    return PrayerStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () {
        final idx = int.tryParse(s) ?? 0;
        if (idx >= 0 && idx < PrayerStatus.values.length) {
          return PrayerStatus.values[idx];
        }
        return PrayerStatus.notDue;
      },
    );
  }

  FastingType _parseFastingType(dynamic v) {
    if (v == null) return FastingType.none;
    if (v is int) {
      if (v >= 0 && v < FastingType.values.length) return FastingType.values[v];
      return FastingType.none;
    }
    final String s = v.toString().replaceFirst('FastingType.', '');
    return FastingType.values.firstWhere(
      (e) => e.name == s,
      orElse: () {
        final idx = int.tryParse(s) ?? 0;
        if (idx >= 0 && idx < FastingType.values.length) {
          return FastingType.values[idx];
        }
        return FastingType.none;
      },
    );
  }

  /// Syncs a remote prohibition log (uses date for matching local daily records)
  Future<void> upsertProhibitionFromRemote(Map<String, dynamic> data) async {
    final dateStr = data['date'] as String;
    final date = DateTime.parse(dateStr);

    var dr = await getRecordByDate(date);
    if (dr == null) {
      await into(dailyRecords).insert(
        DailyRecordsCompanion(date: Value(date)),
        mode: InsertMode.insertOrIgnore,
      );
      dr = await getRecordByDate(date);
    }
    if (dr == null) return;

    final categoryName = data['category'] as String;
    final category = ProhibitionCategory.values.firstWhere(
      (e) => e.name == categoryName,
      orElse: () => ProhibitionCategory.custom,
    );

    final companion = ProhibitionsLogCompanion(
      recordId: Value(dr.id),
      date: Value(date),
      category: Value(category),
      committed: Value(
        (data['committed'] is bool)
            ? data['committed']
            : data['committed'] == 1,
      ),
      timesCount: Value(data['times_count'] as int? ?? 0),
      deductPoints: Value(data['deduct_points'] as int? ?? 10),
      notes: Value(data['notes'] as String?),
    );

    final existing =
        await (select(prohibitionsLog)..where(
              (p) =>
                  p.recordId.equals(dr!.id) & p.category.equals(category.index),
            ))
            .getSingleOrNull();

    if (existing != null) {
      await (update(
        prohibitionsLog,
      )..where((p) => p.id.equals(existing.id))).write(companion);
    } else {
      await into(prohibitionsLog).insert(companion);
    }
  }

  /// Sync from remote Supabase record.
  ///
  /// A full sync pushes the last 7 local days *then* pulls the last 30
  /// remote days on every app start (see `SyncManager._syncDailyRecords`).
  /// If an earlier push for a date failed (flaky connectivity, a cold auth
  /// session, an RLS hiccup — see docs/specs/achievements-statistics-db-
  /// persistence-fix.md), the remote copy of that date is stale, and a
  /// blind overwrite here would clobber the correct local
  /// prayers/points/streak data with it — exactly the "log a day, it's
  /// gone the next day" bug. So this only applies the incoming row when it
  /// is actually newer than what's already stored locally; a stale/absent
  /// remote copy is left alone and gets caught up by the *next* push
  /// instead (the last-7-days push isn't conditional on last sync having
  /// succeeded, so it keeps retrying on its own).
  Future<void> upsertFromRemote(Map<String, dynamic> data) async {
    final date = DateTime.parse(data['date'] as String);
    final remoteUpdatedAt = _parseDateTime(data['updated_at']);

    // R3: if this date's local row has a push still pending in the outbox
    // (the last push attempt failed or hasn't happened yet), the remote
    // copy we'd be pulling is by definition not caught up with local — never
    // let it overwrite netPoints/taqwaPoints/prayer-status/etc. for this
    // date. The pending push itself will catch the remote copy up on a
    // later retry; this pull just has to stay out of the way until then.
    final pendingKey = _dailyRecordOutboxKey(date);
    final pending =
        await (select(syncOutbox)..where(
              (o) =>
                  o.entityTable.equals('daily_records') &
                  o.entityKey.equals(pendingKey),
            ))
            .getSingleOrNull();
    if (pending != null) return;

    final existing = await getRecordByDate(date);
    if (existing != null &&
        remoteUpdatedAt != null &&
        !remoteUpdatedAt.isAfter(existing.updatedAt)) {
      // Local row is at least as fresh as the remote one — nothing to pull.
      return;
    }

    final companion = DailyRecordsCompanion(
      date: Value(date),
      fajrStatus: Value(_parsePrayerStatus(data['fajr_status'])),
      dhuhrStatus: Value(_parsePrayerStatus(data['dhuhr_status'])),
      asrStatus: Value(_parsePrayerStatus(data['asr_status'])),
      maghribStatus: Value(_parsePrayerStatus(data['maghrib_status'])),
      ishaStatus: Value(_parsePrayerStatus(data['isha_status'])),
      nightPrayer: Value(_toBool(data['night_prayer'])),
      witr: Value(_toBool(data['witr'])),
      rawatib: Value(_toInt(data['rawatib'])),
      quranPages: Value(_toInt(data['quran_pages'])),
      quranVerses: Value(_toInt(data['quran_verses'])),
      quranJuzaa: Value(_toDouble(data['quran_juzaa'])),
      morningAdhkar: Value(_toBool(data['morning_adhkar'])),
      eveningAdhkar: Value(_toBool(data['evening_adhkar'])),
      afterPrayerAdhkar: Value(_toBool(data['after_prayer_adhkar'])),
      tasbeehCount: Value(_toInt(data['tasbeeh_count'])),
      fastingType: Value(_parseFastingType(data['fasting_type'])),
      sadaqah: Value(_toBool(data['sadaqah'])),
      sadaqahAmount: Value(_toDouble(data['sadaqah_amount'])),
      // ghadh_basar isn't pulled back here on purpose — it isn't pushed
      // either (see SyncManager.syncDailyRecord), since the remote table
      // doesn't have that column yet. Leaving the local value untouched
      // (Value.absent()) is correct until that migration lands.
      netPoints: Value(_toInt(data['net_points'])),
      taqwaPoints: Value(_toInt(data['taqwa_points'])),
      deductedPoints: Value(_toInt(data['deducted_points'])),
      mood: Value(data['mood'] as String?),
      notes: Value(data['notes'] as String?),
      // Stamp local `updatedAt` with the remote row's own timestamp (not
      // "now") so the next comparison above reflects when the data was
      // actually last changed, not when it happened to be pulled.
      updatedAt: Value(remoteUpdatedAt ?? DateTime.now()),
    );

    await into(dailyRecords).insert(
      companion,
      onConflict: DoUpdate((old) => companion, target: [dailyRecords.date]),
    );
  }
}

// ─────────────────────────────────────────
//  DAO: SyncOutboxDao
// ─────────────────────────────────────────
//
// See `SyncOutbox` in app_database.dart for why this table exists
// (docs/specs/achievements-statistics-db-persistence-fix.md R2/R3).
@DriftAccessor(tables: [SyncOutbox])
class SyncOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$SyncOutboxDaoMixin {
  SyncOutboxDao(super.db);

  /// Record that pushing [entityTable]/[entityKey] to Supabase just failed
  /// (or hasn't succeeded yet), so the next `fullSync()` retries it instead
  /// of silently dropping it forever.
  Future<void> markPending(
    String entityTable,
    String entityKey,
    String error,
  ) async {
    await into(syncOutbox).insert(
      SyncOutboxCompanion.insert(
        entityTable: entityTable,
        entityKey: entityKey,
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
      onConflict: DoUpdate(
        (old) => SyncOutboxCompanion.custom(
          lastError: Variable(error),
          attempts: old.attempts + const Constant(1),
          updatedAt: Variable(DateTime.now()),
        ),
        target: [syncOutbox.entityTable, syncOutbox.entityKey],
      ),
    );
  }

  /// Clear a pending entry after a successful push.
  Future<void> clearPending(String entityTable, String entityKey) async {
    await (delete(syncOutbox)..where(
          (o) =>
              o.entityTable.equals(entityTable) &
              o.entityKey.equals(entityKey),
        ))
        .go();
  }

  /// All keys currently pending push for [entityTable] (e.g. the ISO date
  /// strings of `daily_records` rows whose last push failed).
  Future<List<String>> getPendingKeys(String entityTable) async {
    final rows = await (select(
      syncOutbox,
    )..where((o) => o.entityTable.equals(entityTable))).get();
    return rows.map((r) => r.entityKey).toList();
  }

  /// Total number of entities awaiting a retried push, across all tables —
  /// surfaced to the UI so a stuck sync is visible instead of silent (R6).
  Future<int> pendingCount() async {
    final rows = await select(syncOutbox).get();
    return rows.length;
  }

  Stream<int> watchPendingCount() {
    return select(syncOutbox).watch().map((rows) => rows.length);
  }
}

// ─────────────────────────────────────────
//  DAO 2: StatsDao
// ─────────────────────────────────────────
@DriftAccessor(tables: [DailyRecords, ProhibitionsLog, Achievements])
class StatsDao extends DatabaseAccessor<AppDatabase> with _$StatsDaoMixin {
  StatsDao(super.db);

  Future<int> getMonthlyPoints(int year, int month) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0);
    final rows = await (select(
      dailyRecords,
    )..where((r) => r.date.isBetweenValues(from, to))).get();
    return rows.fold<int>(0, (sum, r) => sum + r.netPoints);
  }

  Future<int> getLongestStreak() async {
    // Only the two columns the streak walk actually needs — this table
    // grows without bound over a user's lifetime, so fetching full rows
    // (15+ columns) here was needless overhead on every call.
    final query = selectOnly(dailyRecords)
      ..addColumns([dailyRecords.date, dailyRecords.netPoints])
      ..orderBy([OrderingTerm.asc(dailyRecords.date)]);

    int longest = 0;
    int current = 0;
    DateTime? prev;

    final rows = await query.get();
    for (final row in rows) {
      final date = row.read(dailyRecords.date)!;
      final netPoints = row.read(dailyRecords.netPoints)!;
      if (netPoints > 0) {
        if (prev != null && date.difference(prev).inDays == 1) {
          current++;
        } else {
          current = 1;
        }
        if (current > longest) longest = current;
        prev = date;
      } else {
        current = 0;
        prev = null;
      }
    }
    return longest;
  }

  Future<int> getCurrentStreak() async {
    final records =
        await (select(dailyRecords)
              ..orderBy([(r) => OrderingTerm.desc(r.date)])
              ..limit(60))
            .get();

    int streak = 0;
    DateTime? prev;

    for (final r in records) {
      if (r.netPoints > 0) {
        if (prev == null) {
          streak = 1;
          prev = r.date;
        } else if (prev.difference(r.date).inDays == 1) {
          streak++;
          prev = r.date;
        } else {
          break;
        }
      } else {
        break;
      }
    }
    return streak;
  }

  Future<double> getPrayerAttendanceRate(int year, int month) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0);
    final rows = await (select(
      dailyRecords,
    )..where((r) => r.date.isBetweenValues(from, to))).get();

    if (rows.isEmpty) return 0;

    int total = rows.length * 5;
    int performed = 0;

    for (final r in rows) {
      for (final status in [
        r.fajrStatus,
        r.dhuhrStatus,
        r.asrStatus,
        r.maghribStatus,
        r.ishaStatus,
      ]) {
        if (status == PrayerStatus.performed) performed++;
      }
    }
    return performed / total;
  }

  Future<int> getMonthlyQuranPages(int year, int month) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0);
    final rows = await (select(
      dailyRecords,
    )..where((r) => r.date.isBetweenValues(from, to))).get();
    return rows.fold<int>(0, (sum, r) => sum + r.quranPages);
  }

  Future<List<WeeklyPoint>> getWeeklyPoints() async {
    final today = DateTime.now();
    final from = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));
    final to = DateTime(today.year, today.month, today.day);
    return getPointsPerDay(from, to);
  }

  TaqwaLevel getTaqwaLevel(int totalPoints) => taqwaLevelFor(totalPoints);

  Future<MonthStats> getMonthStats(int year, int month) async {
    return MonthStats(
      totalPoints: await getMonthlyPoints(year, month),
      longestStreak: await getLongestStreak(),
      currentStreak: await getCurrentStreak(),
      prayerRate: await getPrayerAttendanceRate(year, month),
      quranPages: await getMonthlyQuranPages(year, month),
    );
  }

  Stream<MonthStats> watchMonthStats(int year, int month) {
    return customSelect(
      'SELECT 1',
      readsFrom: {dailyRecords},
    ).watch().asyncMap((_) => getMonthStats(year, month)).distinct();
  }

  Stream<int> watchCurrentStreak() {
    return customSelect(
      'SELECT 1',
      readsFrom: {dailyRecords},
    ).watch().asyncMap((_) => getCurrentStreak()).distinct();
  }

  Stream<List<WeeklyPoint>> watchWeeklyPoints() {
    return customSelect('SELECT 1', readsFrom: {dailyRecords})
        .watch()
        .asyncMap((_) => getWeeklyPoints())
        .distinct(const ListEquality<WeeklyPoint>().equals);
  }

  // ── Range-based queries for period selector ──

  /// Returns per-prayer attendance rates for records within [from, to].
  Future<List<PrayerRateData>> getPerPrayerRates(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await (select(
      dailyRecords,
    )..where((r) => r.date.isBetweenValues(from, to))).get();

    // Same "DB layer can't be locale-aware without going through ARB
    // directly" situation as checkAndGrantAchievements() — see that
    // method's comment.
    final l10n = lookupAppLocalizations(const Locale('ar'));

    if (rows.isEmpty) {
      return [
        PrayerRateData(name: l10n.prayerFajr, emoji: '🌅', rate: 0),
        PrayerRateData(name: l10n.prayerDhuhr, emoji: '☀️', rate: 0),
        PrayerRateData(name: l10n.prayerAsr, emoji: '🌤', rate: 0),
        PrayerRateData(name: l10n.prayerMaghrib, emoji: '🌆', rate: 0),
        PrayerRateData(name: l10n.prayerIsha, emoji: '🌃', rate: 0),
      ];
    }

    int fajr = 0, dhuhr = 0, asr = 0, maghrib = 0, isha = 0;
    for (final r in rows) {
      if (r.fajrStatus == PrayerStatus.performed) fajr++;
      if (r.dhuhrStatus == PrayerStatus.performed) dhuhr++;
      if (r.asrStatus == PrayerStatus.performed) asr++;
      if (r.maghribStatus == PrayerStatus.performed) maghrib++;
      if (r.ishaStatus == PrayerStatus.performed) isha++;
    }
    final n = rows.length;
    return [
      PrayerRateData(name: l10n.prayerFajr, emoji: '🌅', rate: fajr / n),
      PrayerRateData(name: l10n.prayerDhuhr, emoji: '☀️', rate: dhuhr / n),
      PrayerRateData(name: l10n.prayerAsr, emoji: '🌤', rate: asr / n),
      PrayerRateData(name: l10n.prayerMaghrib, emoji: '🌆', rate: maghrib / n),
      PrayerRateData(name: l10n.prayerIsha, emoji: '🌃', rate: isha / n),
    ];
  }

  /// Returns MonthStats aggregated over any date range [from, to].
  Future<MonthStats> getStatsForRange(DateTime from, DateTime to) async {
    final rows = await (select(
      dailyRecords,
    )..where((r) => r.date.isBetweenValues(from, to))).get();

    final totalPoints = rows.fold<int>(0, (s, r) => s + r.netPoints);
    final quranPages = rows.fold<int>(0, (s, r) => s + r.quranPages);

    int performed = 0;
    for (final r in rows) {
      for (final s in [
        r.fajrStatus,
        r.dhuhrStatus,
        r.asrStatus,
        r.maghribStatus,
        r.ishaStatus,
      ]) {
        if (s == PrayerStatus.performed) performed++;
      }
    }
    final prayerRate = rows.isEmpty ? 0.0 : performed / (rows.length * 5);

    return MonthStats(
      totalPoints: totalPoints,
      longestStreak: await getLongestStreak(),
      currentStreak: await getCurrentStreak(),
      prayerRate: prayerRate,
      quranPages: quranPages,
    );
  }

  /// Returns one [WeeklyPoint] per day in [from..to] for the bar chart.
  ///
  /// Single ranged query + in-memory bucketing instead of one query per day.
  Future<List<WeeklyPoint>> getPointsPerDay(DateTime from, DateTime to) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    final rows = await (select(
      dailyRecords,
    )..where((r) => r.date.isBetweenValues(start, end))).get();

    final pointsByDate = {
      for (final r in rows)
        DateTime(r.date.year, r.date.month, r.date.day): r.netPoints,
    };

    final results = <WeeklyPoint>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      results.add(WeeklyPoint(date: cursor, points: pointsByDate[cursor] ?? 0));
      cursor = cursor.add(const Duration(days: 1));
    }
    return results;
  }

  // ── Stream watchers for range queries ──

  Stream<MonthStats> watchStatsForRange(DateTime from, DateTime to) {
    return customSelect(
      'SELECT 1',
      readsFrom: {dailyRecords},
    ).watch().asyncMap((_) => getStatsForRange(from, to)).distinct();
  }

  Stream<List<WeeklyPoint>> watchPointsPerDay(DateTime from, DateTime to) {
    return customSelect('SELECT 1', readsFrom: {dailyRecords})
        .watch()
        .asyncMap((_) => getPointsPerDay(from, to))
        .distinct(const ListEquality<WeeklyPoint>().equals);
  }

  Stream<List<PrayerRateData>> watchPerPrayerRates(DateTime from, DateTime to) {
    return customSelect('SELECT 1', readsFrom: {dailyRecords})
        .watch()
        .asyncMap((_) => getPerPrayerRates(from, to))
        .distinct(const ListEquality<PrayerRateData>().equals);
  }

  /// Marks an earned achievement as seen, so its unlock animation only
  /// plays once (the achievements screen checks `seen` to decide whether
  /// to celebrate a card or just render it normally).
  Future<void> markAchievementSeen(String type) async {
    await (update(achievements)..where((a) => a.type.equals(type))).write(
      const AchievementsCompanion(seen: Value(true)),
    );
  }

  Future<void> addAchievement({
    required String type,
    required String titleAr,
    required String descAr,
    required String emoji,
    int pointsReward = 0,
    DateTime? earnedAt,
  }) async {
    final existing = await (select(
      achievements,
    )..where((a) => a.type.equals(type))).get();
    if (existing.isNotEmpty) return;

    await into(achievements).insert(
      AchievementsCompanion(
        type: Value(type),
        titleAr: Value(titleAr),
        descAr: Value(descAr),
        emoji: Value(emoji),
        pointsReward: Value(pointsReward),
        earnedAt: Value(earnedAt ?? DateTime.now()),
      ),
    );
  }

  Future<List<Achievement>> checkAndGrantAchievements() async {
    final newAchievements = <Achievement>[];
    final streak = await getCurrentStreak();
    final now = DateTime.now();

    // Achievement copy lives in lib/l10n/app_ar.arb (+ app_en.arb), not as
    // literals here — see the audit's "i18n & Accessibility" section. The
    // app is Arabic-only at runtime today (no locale switcher yet), so
    // this locks in the same 'ar' text as before; once real language
    // switching exists, resolve this from the user's chosen locale
    // instead. Note this only affects the string baked into a NEW
    // achievement's title_ar/desc_ar columns at grant time — already
    // earned achievements keep whatever text was stored when granted.
    final l10n = lookupAppLocalizations(const Locale('ar'));

    // 1. Streaks
    if (streak >= 3) {
      final a = await _tryGrant(
        'streak_3',
        l10n.achievementStreak3Title,
        l10n.achievementStreak3Desc,
        '🌱',
        20,
      );
      if (a != null) newAchievements.add(a);
    }
    if (streak >= 7) {
      final a = await _tryGrant(
        'streak_7',
        l10n.achievementStreak7Title,
        l10n.achievementStreak7Desc,
        '🌿',
        50,
      );
      if (a != null) newAchievements.add(a);
    }
    if (streak >= 30) {
      final a = await _tryGrant(
        'streak_30',
        l10n.achievementStreak30Title,
        l10n.achievementStreak30Desc,
        '⚔️',
        200,
      );
      if (a != null) newAchievements.add(a);
    }

    // 2. Quran
    final quranPages = await getMonthlyQuranPages(now.year, now.month);
    if (quranPages >= 30) {
      final a = await _tryGrant(
        'quran_juz',
        l10n.achievementQuranJuzTitle,
        l10n.achievementQuranJuzDesc,
        '📖',
        100,
      );
      if (a != null) newAchievements.add(a);
    }

    // 3. Today's tasks (Dynamic)
    final todayDate = DateTime(now.year, now.month, now.day);
    final today = await (select(
      dailyRecords,
    )..where((r) => r.date.equals(todayDate))).getSingleOrNull();

    if (today != null) {
      if (today.netPoints > 0) {
        final a = await _tryGrant(
          'daily_muhasaba',
          l10n.achievementDailyMuhasabaTitle,
          l10n.achievementDailyMuhasabaDesc,
          '📝',
          10,
        );
        if (a != null) newAchievements.add(a);
      }
      if (today.morningAdhkar) {
        final a = await _tryGrant(
          'morning_adhkar',
          l10n.achievementMorningAdhkarTitle,
          l10n.achievementMorningAdhkarDesc,
          '🌅',
          5,
        );
        if (a != null) newAchievements.add(a);
      }
      if (today.eveningAdhkar) {
        final a = await _tryGrant(
          'evening_adhkar',
          l10n.achievementEveningAdhkarTitle,
          l10n.achievementEveningAdhkarDesc,
          '🌙',
          5,
        );
        if (a != null) newAchievements.add(a);
      }
      if (today.sadaqah) {
        final a = await _tryGrant(
          'first_sadaqah',
          l10n.achievementFirstSadaqahTitle,
          l10n.achievementFirstSadaqahDesc,
          '💰',
          30,
        );
        if (a != null) newAchievements.add(a);
      }
      if (today.tasbeehCount >= 100) {
        final a = await _tryGrant(
          'tasbeeh_100',
          l10n.achievementTasbeeh100Title,
          l10n.achievementTasbeeh100Desc,
          '📿',
          20,
        );
        if (a != null) newAchievements.add(a);
      }
    }

    // 4. Historical Checks (last 3-7 days)
    final last7Rows =
        await (select(dailyRecords)
              ..orderBy([(r) => OrderingTerm.desc(r.date)])
              ..limit(7))
            .get();

    if (last7Rows.length >= 3) {
      final last3 = last7Rows.sublist(0, 3);
      if (last3.every((r) => r.fajrStatus == PrayerStatus.performed)) {
        final a = await _tryGrant(
          'fajr_on_time',
          l10n.achievementFajrOnTimeTitle,
          l10n.achievementFajrOnTimeDesc,
          '🕌',
          30,
        );
        if (a != null) newAchievements.add(a);
      }
      if (last3.every((r) => r.quranPages > 0)) {
        final a = await _tryGrant(
          'constant_reader',
          l10n.achievementConstantReaderTitle,
          l10n.achievementConstantReaderDesc,
          '📚',
          40,
        );
        if (a != null) newAchievements.add(a);
      }
    }

    if (last7Rows.length == 7) {
      if (last7Rows.every(
        (r) =>
            r.fajrStatus == PrayerStatus.performed &&
            r.dhuhrStatus == PrayerStatus.performed &&
            r.asrStatus == PrayerStatus.performed &&
            r.maghribStatus == PrayerStatus.performed &&
            r.ishaStatus == PrayerStatus.performed,
      )) {
        final a = await _tryGrant(
          'perfect_week_prayer',
          l10n.achievementPerfectWeekPrayerTitle,
          l10n.achievementPerfectWeekPrayerDesc,
          '🕌',
          150,
        );
        if (a != null) newAchievements.add(a);
      }
    }

    // 5. Global Lifetime Checks — targeted aggregate queries instead of
    // loading every daily_records row into memory. This table grows
    // without bound over a user's lifetime with the app, and this method
    // runs after most user actions, so a full-table load here scaled
    // badly with tenure.
    final naflCountExp = dailyRecords.id.count();
    final naflCount =
        await (selectOnly(dailyRecords)
              ..addColumns([naflCountExp])
              ..where(dailyRecords.fastingType.equals(FastingType.nafl.index)))
            .map((row) => row.read(naflCountExp) ?? 0)
            .getSingle();

    // Fasting Nafl Check
    if (naflCount > 0) {
      final a = await _tryGrant(
        'fasting_nafl',
        l10n.achievementFastingNaflTitle,
        l10n.achievementFastingNaflDesc,
        '🌙',
        40,
      );
      if (a != null) newAchievements.add(a);
    }

    // Ramadan Knight Check (10 days of fard fasting)
    final fardCountExp = dailyRecords.id.count();
    final ramadanDays =
        await (selectOnly(dailyRecords)
              ..addColumns([fardCountExp])
              ..where(dailyRecords.fastingType.equals(FastingType.fard.index)))
            .map((row) => row.read(fardCountExp) ?? 0)
            .getSingle();
    if (ramadanDays >= 10) {
      final a = await _tryGrant(
        'ramadan_knight',
        l10n.achievementRamadanKnightTitle,
        l10n.achievementRamadanKnightDesc,
        '✨',
        100,
      );
      if (a != null) newAchievements.add(a);
    }

    // Total Lifetime Points Check
    final totalPointsExp = dailyRecords.netPoints.sum();
    final totalPoints =
        await (selectOnly(dailyRecords)..addColumns([totalPointsExp]))
            .map((row) => row.read(totalPointsExp) ?? 0)
            .getSingle();
    if (totalPoints >= 100) {
      final a = await _tryGrant(
        'points_100',
        l10n.achievementPoints100Title,
        l10n.achievementPoints100Desc,
        '🎖️',
        50,
      );
      if (a != null) newAchievements.add(a);
    }
    if (totalPoints >= 1000) {
      final a = await _tryGrant(
        'points_1000',
        l10n.achievementPoints1000Title,
        l10n.achievementPoints1000Desc,
        '🏆',
        500,
      );
      if (a != null) newAchievements.add(a);
    }

    return newAchievements;
  }

  Future<Achievement?> _tryGrant(
    String type,
    String title,
    String desc,
    String emoji,
    int pts,
  ) async {
    final exists = await (select(
      achievements,
    )..where((a) => a.type.equals(type))).getSingleOrNull();
    if (exists == null) {
      final id = await into(achievements).insert(
        AchievementsCompanion(
          type: Value(type),
          titleAr: Value(title),
          descAr: Value(desc),
          emoji: Value(emoji),
          pointsReward: Value(pts),
          earnedAt: Value(DateTime.now()),
        ),
      );
      return (select(achievements)..where((a) => a.id.equals(id))).getSingle();
    }
    return null;
  }
}

// ─────────────────────────────────────────
//  DAO 3: SettingsDao
// ─────────────────────────────────────────
@DriftAccessor(tables: [UserSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> get(String key) async {
    final row = await (select(
      userSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion(key: Value(key), value: Value(value)),
    );
  }

  Future<bool> getBool(String key, {bool defaultVal = false}) async {
    final v = await get(key);
    return v == null ? defaultVal : v == 'true';
  }

  Future<void> setBool(String key, bool value) => set(key, value.toString());

  Stream<String?> watch(String key) {
    return (select(userSettings)..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((r) => r?.value);
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(userSettings).get();
    return {for (var row in rows) row.key: row.value};
  }

  Future<void> upsertFromRemote(Map<String, dynamic> data) async {
    // Map every Supabase column name → local SQLite key used by SettingsDao.set()
    // Local keys use snake_case to match what UserPreferences.fromMap() looks up
    // via map['snake_case'] ?? map['camelCase'] fallback.
    final mapping = <String, String>{
      // ── Prayer calculation ──────────────────────────────────────
      'madhab': 'madhab',
      'calc_method': 'calc_method',
      'high_latitude_rule': 'high_latitude_rule',
      'fajr_offset': 'fajr_offset',
      'sunrise_offset': 'sunrise_offset',
      'dhuhr_offset': 'dhuhr_offset',
      'asr_offset': 'asr_offset',
      'maghrib_offset': 'maghrib_offset',
      'isha_offset': 'isha_offset',

      // ── General toggles ─────────────────────────────────────────
      'prayer_reminder': 'prayer_reminder',
      'pre_adhan_notif': 'pre_adhan_notif',
      'iqama_notif': 'iqama_notif',

      // ── Wake-up before Fajr ─────────────────────────────────────
      'wake_up_before_fajr': 'wake_up_before_fajr',
      'wake_up_time': 'wake_up_time',

      // ── Adhkar reminders ────────────────────────────────────────
      'morning_adhkar_reminder': 'morning_adhkar_reminder',
      'evening_adhkar_reminder': 'evening_adhkar_reminder',
      'adhkar_notif_enabled': 'adhkar_notif_enabled',
      'morning_adhkar_time': 'morning_adhkar_time',
      'evening_adhkar_time': 'evening_adhkar_time',
      'sleep_adhkar_time': 'sleep_adhkar_time',
      'after_fajr_adhkar': 'after_fajr_adhkar',
      'after_asr_adhkar': 'after_asr_adhkar',

      // ── Muhasaba ────────────────────────────────────────────────
      // FIX: was mapped to 'eveningMuhasabaReminder' — fromMap reads 'muhasaba_reminder'
      'muhasaba_reminder': 'muhasaba_reminder',
      'evening_reminder_time': 'evening_reminder_time',

      // ── Extra reminders ─────────────────────────────────────────
      'daily_duas_on': 'daily_duas_on',
      'special_reminders_on': 'special_reminders_on',
      'fasting_reminders_on': 'fasting_reminders_on',

      // ── Appearance / mode ───────────────────────────────────────
      'ramadan_mode': 'ramadan_mode',
      'theme_mode': 'theme_mode',
      'language': 'language',

      // ── Adhan sound ─────────────────────────────────────────────
      'adhan_sound': 'adhan_sound',

      // ── Adhan mode & volume ─────────────────────────────────────
      // FIX: these were completely missing from the mapping
      'adhan_mode': 'adhan_mode',
      'adhan_volume_level': 'adhan_volume_level',
      'vibrate_with_adhan': 'vibrate_with_adhan',

      // ── Overlay / screen settings ───────────────────────────────
      'overlay_popups_enabled': 'overlay_popups_enabled',
      // 'adhan_sound_enabled' intentionally dropped from this mapping too —
      // UserPreferences no longer has a field for it (see
      // docs/specs/settings-notifications-improvements.md R1); any
      // lingering remote rows for old accounts are simply ignored on pull.
      'adhan_screen_enabled': 'adhan_screen_enabled',
      'popup_interval_minutes': 'popup_interval_minutes',

      // ── System notification flags ───────────────────────────────
      // FIX: these were completely missing from the mapping
      'adhan_alarm_enabled': 'adhan_alarm_enabled',
      'ongoing_notif_enabled': 'ongoing_notif_enabled',
      'wake_screen_enabled': 'wake_screen_enabled',
      'flip_to_silence_enabled': 'flip_to_silence_enabled',

      // ── Silent mode ─────────────────────────────────────────────
      // FIX: these were completely missing from the mapping
      'silent_mode_enabled': 'silent_mode_enabled',
      'silent_duration_mins': 'silent_duration_mins',
      'silent_mode_alert_style': 'silent_mode_alert_style',
      'silent_vibration_enabled': 'silent_vibration_enabled',
      'silent_adhan_prayers': 'silent_adhan_prayers',
      'silent_notif_prayers': 'silent_notif_prayers',
      'auto_silent_after_adhan': 'auto_silent_after_adhan',
      // 'adhan_in_silent_enabled'/'notifs_in_silent_enabled' intentionally
      // dropped from this mapping — UserPreferences no longer has a field
      // for them (see docs/specs/settings-notifications-improvements.md
      // R3/R5); any lingering remote rows for old accounts are simply
      // ignored on pull now.
    };

    for (final entry in mapping.entries) {
      if (data.containsKey(entry.key) && data[entry.key] != null) {
        await set(entry.value, data[entry.key].toString());
      }
    }
  }
}

// ─────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────

class WeeklyPoint {
  final DateTime date;
  final int points;
  WeeklyPoint({required this.date, required this.points});

  // Value equality lets the `watch*` streams below `.distinct()` — a write
  // to `daily_records` on some other date still re-runs these queries (see
  // the Performance audit note on `customSelect(readsFrom:)` granularity),
  // but an unchanged result no longer re-emits and triggers a UI rebuild.
  @override
  bool operator ==(Object other) =>
      other is WeeklyPoint && other.date == date && other.points == points;

  @override
  int get hashCode => Object.hash(date, points);

  // Same DB-layer-can't-use-BuildContext situation as
  // checkAndGrantAchievements() — see that method's comment.
  static final _l10n = lookupAppLocalizations(const Locale('ar'));

  /// Two-letter weekday abbreviation, e.g. "أح" for Sunday.
  String get dayLabel {
    final days = [
      _l10n.weekdayShortSunday,
      _l10n.weekdayShortMonday,
      _l10n.weekdayShortTuesday,
      _l10n.weekdayShortWednesday,
      _l10n.weekdayShortThursday,
      _l10n.weekdayShortFriday,
      _l10n.weekdayShortSaturday,
    ];
    return days[date.weekday % 7];
  }

  String get fullDayName {
    final days = [
      _l10n.weekdayFullSunday,
      _l10n.weekdayFullMonday,
      _l10n.weekdayFullTuesday,
      _l10n.weekdayFullWednesday,
      _l10n.weekdayFullThursday,
      _l10n.weekdayFullFriday,
      _l10n.weekdayFullSaturday,
    ];
    return days[date.weekday % 7];
  }

  /// Single-letter weekday initial, e.g. "ح" for Sunday.
  String get shortDayName {
    final days = [
      _l10n.weekdayInitialSunday,
      _l10n.weekdayInitialMonday,
      _l10n.weekdayInitialTuesday,
      _l10n.weekdayInitialWednesday,
      _l10n.weekdayInitialThursday,
      _l10n.weekdayInitialFriday,
      _l10n.weekdayInitialSaturday,
    ];
    return days[date.weekday % 7];
  }
}

/// Per-prayer attendance rate for a given date range.
class PrayerRateData {
  final String name;
  final String emoji;
  final double rate;
  const PrayerRateData({
    required this.name,
    required this.emoji,
    required this.rate,
  });

  @override
  bool operator ==(Object other) =>
      other is PrayerRateData &&
      other.name == name &&
      other.emoji == emoji &&
      other.rate == rate;

  @override
  int get hashCode => Object.hash(name, emoji, rate);
}

class MonthStats {
  final int totalPoints;
  final int longestStreak;
  final int currentStreak;
  final double prayerRate;
  final int quranPages;

  MonthStats({
    required this.totalPoints,
    required this.longestStreak,
    required this.currentStreak,
    required this.prayerRate,
    required this.quranPages,
  });

  TaqwaLevel get level => taqwaLevelFor(totalPoints);

  int get prayerPercent => (prayerRate * 100).round();

  @override
  bool operator ==(Object other) =>
      other is MonthStats &&
      other.totalPoints == totalPoints &&
      other.longestStreak == longestStreak &&
      other.currentStreak == currentStreak &&
      other.prayerRate == prayerRate &&
      other.quranPages == quranPages;

  @override
  int get hashCode => Object.hash(
    totalPoints,
    longestStreak,
    currentStreak,
    prayerRate,
    quranPages,
  );
}

// ─────────────────────────────────────────
//  DAO 4: RemindersDao
// ─────────────────────────────────────────
@DriftAccessor(tables: [Reminders])
class RemindersDao extends DatabaseAccessor<AppDatabase>
    with _$RemindersDaoMixin {
  RemindersDao(super.db);

  /// Watch all reminders ordered by creation date
  Stream<List<Reminder>> watchAll() {
    return (select(
      reminders,
    )..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).watch();
  }

  /// Insert a new reminder
  Future<int> addReminder({
    required String title,
    required String iconName,
    required String time,
  }) {
    return into(reminders).insert(
      RemindersCompanion(
        title: Value(title),
        iconName: Value(iconName),
        time: Value(time),
      ),
    );
  }

  /// Toggle enabled / disabled for a reminder
  Future<void> toggleEnabled(int id, bool isEnabled) {
    return (update(reminders)..where((r) => r.id.equals(id))).write(
      RemindersCompanion(isEnabled: Value(isEnabled)),
    );
  }

  /// Delete a reminder by id
  Future<int> deleteReminder(int id) {
    return (delete(reminders)..where((r) => r.id.equals(id))).go();
  }

  /// Sync from remote Supabase record
  Future<void> upsertFromRemote(Map<String, dynamic> data) async {
    final companion = RemindersCompanion(
      title: Value(data['title'] as String),
      iconName: Value(data['icon_name'] as String? ?? 'favorite_rounded'),
      time: Value(data['time'] as String),
      isEnabled: Value(data['is_enabled'] as bool? ?? true),
      // We don't necessarily want to force the ID from remote if it's auto-incrementing locally,
      // but we need a way to link them. For now, we'll use the local_id if provided.
    );

    final localId = data['local_id'] as int?;
    if (localId != null) {
      await into(
        reminders,
      ).insertOnConflictUpdate(companion.copyWith(id: Value(localId)));
    } else {
      await into(reminders).insert(companion);
    }
  }
}

@DriftAccessor(tables: [CustomIbadah, CustomIbadahLog, DailyRecords])
class CustomIbadahDao extends DatabaseAccessor<AppDatabase>
    with _$CustomIbadahDaoMixin {
  CustomIbadahDao(super.db);

  // --- Ibadah Defs ---
  Stream<List<CustomIbadahData>> watchActiveIbadat(bool isPositive) {
    return (select(customIbadah)
          ..where(
            (i) => i.isActive.equals(true) & i.isPositive.equals(isPositive),
          )
          ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
        .watch();
  }

  Stream<List<CustomIbadahData>> watchAllIbadat(bool isPositive) {
    return (select(customIbadah)
          ..where((i) => i.isPositive.equals(isPositive))
          ..orderBy([
            (i) => OrderingTerm.desc(i.isActive),
            (i) => OrderingTerm.asc(i.sortOrder),
          ]))
        .watch();
  }

  Future<List<CustomIbadahData>> getAllIbadat() {
    return select(customIbadah).get();
  }

  Future<int> addIbadah(CustomIbadahCompanion comp) {
    return into(customIbadah).insert(comp);
  }

  Future<void> updateIbadah(CustomIbadahCompanion comp) {
    return (update(
      customIbadah,
    )..where((t) => t.id.equals(comp.id.value))).write(comp);
  }

  Future<void> deleteIbadah(int id) {
    return (delete(customIbadah)..where((t) => t.id.equals(id))).go();
  }

  // --- Syncing (Remote -> Local) ---
  Future<void> upsertCustomIbadahFromRemote(Map<String, dynamic> data) async {
    final id = data['id'] as int;
    final companion = CustomIbadahCompanion(
      id: Value(id),
      nameAr: Value(data['name_ar'] as String),
      emoji: Value(data['emoji'] as String? ?? '⭐'),
      isPositive: Value(data['is_positive'] as bool? ?? true),
      points: Value(data['points'] as int? ?? 5),
      isActive: Value(data['is_active'] as bool? ?? true),
      sortOrder: Value(data['sort_order'] as int? ?? 0),
    );
    await into(customIbadah).insertOnConflictUpdate(companion);
  }

  Future<void> upsertCustomIbadahLogFromRemote(
    Map<String, dynamic> data,
  ) async {
    final dateStr = data['date'] as String;
    final date = DateTime.parse(dateStr);

    final dr = await (select(
      dailyRecords,
    )..where((r) => r.date.equals(date))).getSingleOrNull();
    int drId;
    if (dr == null) {
      drId = await into(dailyRecords).insert(
        DailyRecordsCompanion(date: Value(date)),
        mode: InsertMode.insertOrIgnore,
      );
      if (drId == 0 || drId == -1) {
        final existingDr = await (select(
          dailyRecords,
        )..where((r) => r.date.equals(date))).getSingle();
        drId = existingDr.id;
      }
    } else {
      drId = dr.id;
    }

    final ibadahId = data['ibadah_id'] as int;
    final companion = CustomIbadahLogCompanion(
      ibadahId: Value(ibadahId),
      recordId: Value(drId),
      date: Value(date),
      done: Value(data['done'] as bool? ?? false),
      count: Value(data['count'] as int? ?? 1),
    );

    final existing =
        await (select(customIbadahLog)..where(
              (l) => l.recordId.equals(drId) & l.ibadahId.equals(ibadahId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      await (update(
        customIbadahLog,
      )..where((l) => l.id.equals(existing.id))).write(companion);
    } else {
      await into(customIbadahLog).insert(companion);
    }
    await DailyRecordDao(db).recalcPoints(drId);
  }

  // --- Logging (Local -> Remote later) ---
  Stream<List<CustomIbadahLogData>> watchLogsForDate(DateTime date) {
    return (select(customIbadahLog)..where((t) => t.date.equals(date))).watch();
  }

  Future<List<CustomIbadahLogData>> getLogsForDate(DateTime date) {
    return (select(customIbadahLog)..where((t) => t.date.equals(date))).get();
  }

  /// Looks up a single log row by its local id — used by
  /// `SyncManager._syncCustomIbadah` to retry a push that's pending in the
  /// `SyncOutbox` (see achievements-statistics-db-persistence-fix.md R2).
  Future<CustomIbadahLogData?> getLogById(int id) {
    return (select(customIbadahLog)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> logIbadah(
    int ibadahId,
    DateTime date,
    bool done,
    int count,
  ) async {
    final dr = await (select(
      dailyRecords,
    )..where((r) => r.date.equals(date))).getSingleOrNull();
    int drId;
    if (dr == null) {
      drId = await into(dailyRecords).insert(
        DailyRecordsCompanion(date: Value(date)),
        mode: InsertMode.insertOrIgnore,
      );
      if (drId == 0 || drId == -1) {
        final existingDr = await (select(
          dailyRecords,
        )..where((r) => r.date.equals(date))).getSingle();
        drId = existingDr.id;
      }
    } else {
      drId = dr.id;
    }

    final existing =
        await (select(customIbadahLog)..where(
              (l) => l.recordId.equals(drId) & l.ibadahId.equals(ibadahId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      await (update(
        customIbadahLog,
      )..where((l) => l.id.equals(existing.id))).write(
        CustomIbadahLogCompanion(done: Value(done), count: Value(count)),
      );
    } else {
      await into(customIbadahLog).insert(
        CustomIbadahLogCompanion(
          ibadahId: Value(ibadahId),
          recordId: Value(drId),
          date: Value(date),
          done: Value(done),
          count: Value(count),
        ),
      );
    }
    await DailyRecordDao(db).recalcPoints(drId);
  }
}

// ─────────────────────────────────────────
//  DAO 6: PrayerTimesCacheDao
// ─────────────────────────────────────────
@DriftAccessor(tables: [PrayerTimesCache])
class PrayerTimesCacheDao extends DatabaseAccessor<AppDatabase>
    with _$PrayerTimesCacheDaoMixin {
  PrayerTimesCacheDao(super.db);

  Future<PrayerTimesCacheData?> getForDate(DateTime date) {
    return (select(
      prayerTimesCache,
    )..where((t) => t.date.equals(date))).getSingleOrNull();
  }

  Future<void> insertOrUpdate(PrayerTimesCacheCompanion companion) {
    return into(prayerTimesCache).insertOnConflictUpdate(companion);
  }

  Future<void> clearAll() {
    return delete(prayerTimesCache).go();
  }
}

// ─────────────────────────────────────────
//  DAO 7: RamadanProgressDao
// ─────────────────────────────────────────
@DriftAccessor(tables: [RamadanProgress, DailyRecords])
class RamadanProgressDao extends DatabaseAccessor<AppDatabase>
    with _$RamadanProgressDaoMixin {
  RamadanProgressDao(super.db);

  Future<RamadanProgressData?> getProgress(int year, int day) {
    return (select(ramadanProgress)
          ..where((t) => t.year.equals(year) & t.dayNumber.equals(day)))
        .getSingleOrNull();
  }

  Future<void> updateProgress(RamadanProgressCompanion companion) {
    return into(ramadanProgress).insertOnConflictUpdate(companion);
  }

  Future<void> upsertFromRemote(Map<String, dynamic> data) async {
    final year = data['year'] as int;
    final dayNum = data['day_number'] as int;

    final existing = await getProgress(year, dayNum);
    int? recordId;
    if (data['record_id'] != null) {
      recordId = data['record_id'] as int;
    }

    final companion = RamadanProgressCompanion(
      year: Value(year),
      dayNumber: Value(dayNum),
      recordId: recordId != null ? Value(recordId) : const Value.absent(),
      duaOfDay: Value(data['dua_of_day'] as String?),
      iHyaLayl: Value(data['i_hya_layl'] as bool? ?? false),
      totalPoints: Value(data['total_points'] as int? ?? 0),
    );

    if (existing != null) {
      await (update(
        ramadanProgress,
      )..where((t) => t.id.equals(existing.id))).write(companion);
    } else {
      await into(ramadanProgress).insert(companion);
    }
  }
}

// ─────────────────────────────────────────
//  DAO 8: UserAdhkarDao
// ─────────────────────────────────────────
@DriftAccessor(tables: [UserAdhkar])
class UserAdhkarDao extends DatabaseAccessor<AppDatabase>
    with _$UserAdhkarDaoMixin {
  UserAdhkarDao(super.db);

  Future<List<UserAdhkarData>> getAll() {
    return select(userAdhkar).get();
  }

  Future<void> insertOrUpdate(UserAdhkarCompanion companion) {
    return into(userAdhkar).insertOnConflictUpdate(companion);
  }

  Future<void> insertItem(UserAdhkarData item) {
    return into(userAdhkar).insertOnConflictUpdate(item);
  }

  Future<void> deleteItem(String id) {
    return (delete(userAdhkar)..where((t) => t.id.equals(id))).go();
  }

  Future<void> upsertFromRemote(Map<String, dynamic> data) async {
    final item = UserAdhkarCompanion(
      id: Value(data['id'] as String),
      textAr: Value(data['text_ar'] as String),
      count: Value(data['count'] as int? ?? 1),
      categoryHint: Value(data['category_hint'] as String?),
      createdAt: data['created_at'] != null
          ? Value(DateTime.parse(data['created_at'] as String))
          : const Value.absent(),
    );
    await insertOrUpdate(item);
  }
}

// ─────────────────────────────────────────
//  DAO 9: UserDuasDao
// ─────────────────────────────────────────
@DriftAccessor(tables: [UserDuas])
class UserDuasDao extends DatabaseAccessor<AppDatabase>
    with _$UserDuasDaoMixin {
  UserDuasDao(super.db);

  Future<List<UserDua>> getAll() {
    return select(userDuas).get();
  }

  Future<void> insertOrUpdate(UserDuasCompanion companion) {
    return into(userDuas).insertOnConflictUpdate(companion);
  }

  Future<void> insertItem(UserDua item) {
    return into(userDuas).insertOnConflictUpdate(item);
  }

  Future<void> deleteItem(String id) {
    return (delete(userDuas)..where((t) => t.id.equals(id))).go();
  }

  Future<void> upsertFromRemote(Map<String, dynamic> data) async {
    final item = UserDuasCompanion(
      id: Value(data['id'] as String),
      titleAr: Value(data['title_ar'] as String),
      textAr: Value(data['text_ar'] as String),
      occasion: Value(data['occasion'] as String?),
      source: Value(data['source'] as String?),
      emoji: Value(data['emoji'] as String?),
      createdAt: data['created_at'] != null
          ? Value(DateTime.parse(data['created_at'] as String))
          : const Value.absent(),
    );
    await insertOrUpdate(item);
  }
}

// ─────────────────────────────────────────
//  DAO 10: BookProgressDao
// ─────────────────────────────────────────
@DriftAccessor(tables: [BookReadingProgress])
class BookProgressDao extends DatabaseAccessor<AppDatabase>
    with _$BookProgressDaoMixin {
  BookProgressDao(super.db);

  /// Get progress for a specific book (returns null if never opened).
  Future<BookReadingProgressData?> getProgress(String bookId) {
    return (select(
      bookReadingProgress,
    )..where((t) => t.bookId.equals(bookId))).getSingleOrNull();
  }

  /// Get progress for all books at once.
  Future<List<BookReadingProgressData>> getAll() {
    return select(bookReadingProgress).get();
  }

  /// Upsert progress for a book (local writes).
  Future<void> upsertProgress(BookReadingProgressCompanion companion) {
    return into(bookReadingProgress).insertOnConflictUpdate(companion);
  }

  /// Helper: mark a page as read and update chapter/page position.
  Future<void> markPage({
    required String bookId,
    required int chapterIndex,
    required int pageIndex,
    required Set<int> readPages,
  }) async {
    await into(bookReadingProgress).insertOnConflictUpdate(
      BookReadingProgressCompanion(
        bookId: Value(bookId),
        chapterIndex: Value(chapterIndex),
        pageIndex: Value(pageIndex),
        readPages: Value(readPages.join(',')),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Helper: save PDF session data.
  Future<void> savePdfSession({
    required String bookId,
    required int pdfPage,
    required int totalPdfPages,
    required int readingSeconds,
  }) async {
    final existing = await getProgress(bookId);
    await into(bookReadingProgress).insertOnConflictUpdate(
      BookReadingProgressCompanion(
        bookId: Value(bookId),
        pdfPage: Value(pdfPage),
        totalPdfPages: Value(totalPdfPages),
        readingSeconds: Value(readingSeconds),
        // Preserve existing chapter/page/readPages
        chapterIndex: Value(existing?.chapterIndex ?? 0),
        pageIndex: Value(existing?.pageIndex ?? 0),
        readPages: Value(existing?.readPages ?? ''),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Upsert progress received from Supabase remote.
  Future<void> upsertFromRemote(Map<String, dynamic> data) async {
    final readPagesRaw = data['read_pages'];
    String readPagesStr = '';
    if (readPagesRaw is List) {
      readPagesStr = readPagesRaw.map((e) => e.toString()).join(',');
    } else if (readPagesRaw is String) {
      readPagesStr = readPagesRaw;
    }

    await into(bookReadingProgress).insertOnConflictUpdate(
      BookReadingProgressCompanion(
        bookId: Value(data['book_id'] as String),
        chapterIndex: Value(data['chapter_index'] as int? ?? 0),
        pageIndex: Value(data['page_index'] as int? ?? 0),
        readPages: Value(readPagesStr),
        pdfPage: Value(data['pdf_page'] as int? ?? 0),
        totalPdfPages: Value(data['total_pdf_pages'] as int? ?? 0),
        readingSeconds: Value(data['reading_seconds'] as int? ?? 0),
        updatedAt: data['updated_at'] != null
            ? Value(DateTime.parse(data['updated_at'] as String))
            : Value(DateTime.now()),
      ),
    );
  }

  /// Delete progress for a book.
  Future<void> deleteProgress(String bookId) {
    return (delete(
      bookReadingProgress,
    )..where((t) => t.bookId.equals(bookId))).go();
  }
}
