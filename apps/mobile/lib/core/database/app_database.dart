import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:takwa_core/takwa_core.dart';

import 'daos.dart';

// ─────────────────────────────────────────
//  ENUMS
// ─────────────────────────────────────────
//
// PrayerStatus / FastingType / ProhibitionCategory / TaqwaLevel now live in
// packages/takwa_core (shared, storage-agnostic domain logic — see the
// audit's "Architecture & Code Quality" section) and are re-exported here
// so every existing `import 'app_database.dart'` across the app keeps
// working unchanged.
export 'package:takwa_core/takwa_core.dart';

part 'app_database.g.dart';

// ─────────────────────────────────────────
//  TABLE: daily_records
// ─────────────────────────────────────────
class DailyRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();

  // ── الصلوات ──
  IntColumn get fajrStatus =>
      intEnum<PrayerStatus>().withDefault(const Constant(0))();
  IntColumn get dhuhrStatus =>
      intEnum<PrayerStatus>().withDefault(const Constant(0))();
  IntColumn get asrStatus =>
      intEnum<PrayerStatus>().withDefault(const Constant(0))();
  IntColumn get maghribStatus =>
      intEnum<PrayerStatus>().withDefault(const Constant(0))();
  IntColumn get ishaStatus =>
      intEnum<PrayerStatus>().withDefault(const Constant(0))();
  BoolColumn get nightPrayer => boolean().withDefault(const Constant(false))();
  BoolColumn get witr => boolean().withDefault(const Constant(false))();
  IntColumn get rawatib => integer().withDefault(const Constant(0))();

  // ── القرآن ──
  IntColumn get quranPages => integer().withDefault(const Constant(0))();
  IntColumn get quranVerses => integer().withDefault(const Constant(0))();
  RealColumn get quranJuzaa => real().withDefault(const Constant(0.0))();

  // ── الأذكار ──
  BoolColumn get morningAdhkar =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get eveningAdhkar =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get afterPrayerAdhkar =>
      boolean().withDefault(const Constant(false))();
  IntColumn get tasbeehCount => integer().withDefault(const Constant(0))();

  // ── الصيام ──
  IntColumn get fastingType =>
      intEnum<FastingType>().withDefault(const Constant(0))();

  // ── الصدقة ──
  BoolColumn get sadaqah => boolean().withDefault(const Constant(false))();
  RealColumn get sadaqahAmount => real().withDefault(const Constant(0.0))();

  // ── غضّ البصر ──
  BoolColumn get ghadhBasar => boolean().withDefault(const Constant(false))();

  // ── النقاط المحسوبة ──
  IntColumn get taqwaPoints => integer().withDefault(const Constant(0))();
  IntColumn get deductedPoints => integer().withDefault(const Constant(0))();
  IntColumn get netPoints => integer().withDefault(const Constant(0))();

  // ── الملاحظات ──
  TextColumn get notes => text().withLength(max: 500).nullable()();
  TextColumn get mood => text().withLength(max: 50).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────
//  TABLE: prohibitions_log
// ─────────────────────────────────────────
@TableIndex(name: 'idx_prohibitions_log_record', columns: {#recordId})
class ProhibitionsLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recordId => integer().references(DailyRecords, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get category => intEnum<ProhibitionCategory>()();
  TextColumn get customName => text().withLength(max: 100).nullable()();
  BoolColumn get committed => boolean().withDefault(const Constant(false))();
  IntColumn get timesCount => integer().withDefault(const Constant(0))();
  IntColumn get deductPoints => integer().withDefault(const Constant(10))();
  TextColumn get notes => text().withLength(max: 200).nullable()();
}

// ─────────────────────────────────────────
//  TABLE: prayer_times_cache
// ─────────────────────────────────────────
class PrayerTimesCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  TextColumn get fajr => text()();
  TextColumn get sunrise => text()();
  TextColumn get dhuhr => text()();
  TextColumn get asr => text()();
  TextColumn get maghrib => text()();
  TextColumn get isha => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get method => text().withDefault(const Constant('MWL'))();
}

// ─────────────────────────────────────────
//  TABLE: achievements
// ─────────────────────────────────────────
class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get titleAr => text()();
  TextColumn get descAr => text()();
  TextColumn get emoji => text()();
  IntColumn get pointsReward => integer().withDefault(const Constant(0))();
  DateTimeColumn get earnedAt => dateTime()();
  BoolColumn get seen => boolean().withDefault(const Constant(false))();
}

// ─────────────────────────────────────────
//  TABLE: custom_ibadah
// ─────────────────────────────────────────
class CustomIbadah extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nameAr => text()();
  TextColumn get emoji => text().withDefault(const Constant('⭐'))();
  BoolColumn get isPositive => boolean().withDefault(const Constant(true))();
  IntColumn get points => integer().withDefault(const Constant(5))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

// ─────────────────────────────────────────
//  TABLE: custom_ibadah_log
// ─────────────────────────────────────────
@TableIndex(
  name: 'idx_custom_ibadah_log_record_ibadah',
  columns: {#recordId, #ibadahId},
)
class CustomIbadahLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ibadahId => integer().references(CustomIbadah, #id)();
  IntColumn get recordId => integer().references(DailyRecords, #id)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get count => integer().withDefault(const Constant(1))();
}

// ─────────────────────────────────────────
//  TABLE: reminders
// ─────────────────────────────────────────
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(max: 200)();
  TextColumn get iconName =>
      text().withDefault(const Constant('favorite_rounded'))();
  TextColumn get time => text()(); // stored as "HH:mm" 24h
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────
//  TABLE: user_settings
// ─────────────────────────────────────────
class UserSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ─────────────────────────────────────────
//  TABLE: ramadan_progress
// ─────────────────────────────────────────
@TableIndex(name: 'idx_ramadan_progress_record', columns: {#recordId})
class RamadanProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get dayNumber => integer()();
  IntColumn get recordId =>
      integer().references(DailyRecords, #id).nullable()();
  TextColumn get duaOfDay => text().nullable()();
  BoolColumn get iHyaLayl => boolean().withDefault(const Constant(false))();
  IntColumn get totalPoints => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {year, dayNumber},
  ];
}

// ─────────────────────────────────────────
//  TABLE: user_adhkar
// ─────────────────────────────────────────
class UserAdhkar extends Table {
  TextColumn get id => text()(); // UUID String
  TextColumn get textAr => text()();
  IntColumn get count => integer().withDefault(const Constant(1))();
  TextColumn get categoryHint => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────
//  TABLE: user_duas
// ─────────────────────────────────────────
class UserDuas extends Table {
  TextColumn get id => text()(); // UUID String
  TextColumn get titleAr => text()();
  TextColumn get textAr => text()();
  TextColumn get occasion => text().nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get emoji => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────
//  TABLE: book_reading_progress
// ─────────────────────────────────────────
class BookReadingProgress extends Table {
  TextColumn get bookId => text()();
  IntColumn get chapterIndex => integer().withDefault(const Constant(0))();
  IntColumn get pageIndex => integer().withDefault(const Constant(0))();

  /// Comma-separated list of read page indices, e.g. "0,1,3,7"
  TextColumn get readPages => text().withDefault(const Constant(''))();

  /// PDF page (if applicable)
  IntColumn get pdfPage => integer().withDefault(const Constant(0))();
  IntColumn get totalPdfPages => integer().withDefault(const Constant(0))();
  IntColumn get readingSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {bookId};
}

// ─────────────────────────────────────────
//  TABLE: sync_outbox
// ─────────────────────────────────────────
//
// A generic "pending push" outbox, added to fix docs/specs/
// achievements-statistics-db-persistence-fix.md R2/R3: a row here means the
// last push of that entity to Supabase failed (or hasn't been attempted
// yet), so:
//   - SyncManager retries every pending row on the next fullSync() instead
//     of only ever pushing the last few days once and silently giving up
//     on failure (R2).
//   - A pull for that same entity is skipped while it's pending, so a
//     stale/absent remote copy can never race ahead and clobber the (still
//     un-pushed, but correct) local row (R3).
// One table covers `daily_records` (key: ISO date string), `achievements`,
// `custom_ibadah_log` and `prohibitions_log` (key: local row id as string)
// rather than a separate boolean column per table, per the spec's own
// recommendation.
@TableIndex(
  name: 'idx_sync_outbox_table_key',
  columns: {#entityTable, #entityKey},
)
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityTable => text()();
  TextColumn get entityKey => text()();
  TextColumn get lastError => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {entityTable, entityKey},
  ];
}

// ─────────────────────────────────────────
//  DATABASE CLASS
// ─────────────────────────────────────────
@DriftDatabase(
  tables: [
    DailyRecords,
    ProhibitionsLog,
    PrayerTimesCache,
    Achievements,
    CustomIbadah,
    CustomIbadahLog,
    UserSettings,
    RamadanProgress,
    Reminders,
    UserAdhkar,
    UserDuas,
    BookReadingProgress,
    SyncOutbox,
  ],
  daos: [
    DailyRecordDao,
    StatsDao,
    SettingsDao,
    RemindersDao,
    CustomIbadahDao,
    PrayerTimesCacheDao,
    RamadanProgressDao,
    UserAdhkarDao,
    UserDuasDao,
    BookProgressDao,
    SyncOutboxDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor allowing a custom [QueryExecutor] to be injected
  /// (e.g. `NativeDatabase.memory()` in unit tests) instead of the real
  /// on-disk database file.
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedDefaultData();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 9) {
        await m.createTable(syncOutbox);
        await m.createIndex(idxSyncOutboxTableKey);
      }
      if (from < 8) {
        // RamadanProgress.recordId isn't filtered on by any query today,
        // but it's a FK like the other two indexed below — indexing it now
        // avoids a silent full-table scan the day a lookup-by-record query
        // gets added, for the cost of one small index.
        await m.createIndex(idxRamadanProgressRecord);
      }
      if (from < 7) {
        // Missing indexes on FK columns that are actually filtered on
        // (ProhibitionsLog.recordId, and the CustomIbadahLog record+ibadah
        // lookup used by recalcPoints()/logIbadah()) — previously full
        // table scans as history grew.
        await m.createIndex(idxProhibitionsLogRecord);
        await m.createIndex(idxCustomIbadahLogRecordIbadah);
      }
      if (from < 2) {
        await m.createTable(reminders);
      }
      if (from < 3) {
        await m.addColumn(dailyRecords, dailyRecords.ghadhBasar);
      }
      if (from < 4) {
        // Rename all legacy camelCase setting keys → snake_case
        // so that UserPreferences.fromMap() and SettingsDao.get() use
        // a single consistent key format matching the Supabase columns.
        const renames = [
          ('calcMethod', 'calc_method'),
          ('ramadanMode', 'ramadan_mode'),
          ('prayerReminder', 'prayer_reminder'),
          ('preAdhanNotif', 'pre_adhan_notif'),
          ('iqamaNotif', 'iqama_notif'),
          ('wakeUpBeforeFajr', 'wake_up_before_fajr'),
          ('wakeUpTime', 'wake_up_time'),
          ('morningAdhkarReminder', 'morning_adhkar_reminder'),
          ('eveningAdhkarReminder', 'evening_adhkar_reminder'),
          ('adhkarNotifEnabled', 'adhkar_notif_enabled'),
          ('morningAdhkarTime', 'morning_adhkar_time'),
          ('eveningAdhkarTime', 'evening_adhkar_time'),
          ('sleepAdhkarTime', 'sleep_adhkar_time'),
          ('afterFajrAdhkar', 'after_fajr_adhkar'),
          ('afterAsrAdhkar', 'after_asr_adhkar'),
          ('eveningMuhasabaReminder', 'muhasaba_reminder'),
          ('eveningReminderTime', 'evening_reminder_time'),
          ('dailyDuasOn', 'daily_duas_on'),
          ('specialRemindersOn', 'special_reminders_on'),
          ('fastingRemindersOn', 'fasting_reminders_on'),
          ('ramadanMode', 'ramadan_mode'),
          ('themeMode', 'theme_mode'),
          ('adhanSound', 'adhan_sound'),
          ('overlayEnabled', 'overlay_popups_enabled'),
          ('adhanSoundEnabled', 'adhan_sound_enabled'),
          ('adhanScreenEnabled', 'adhan_screen_enabled'),
          ('popupIntervalMins', 'popup_interval_minutes'),
          ('adhanMode', 'adhan_mode'),
          ('adhanVolumeLevel', 'adhan_volume_level'),
          ('silentModeEnabled', 'silent_mode_enabled'),
          ('silentDurationMins', 'silent_duration_mins'),
          ('silentModeAlertStyle', 'silent_mode_alert_style'),
          ('silentVibrationEnabled', 'silent_vibration_enabled'),
          ('silentAdhanPrayers', 'silent_adhan_prayers'),
          ('silentNotifPrayers', 'silent_notif_prayers'),
          ('autoSilentAfterAdhan', 'auto_silent_after_adhan'),
          ('adhanInSilentEnabled', 'adhan_in_silent_enabled'),
          ('notifsInSilentEnabled', 'notifs_in_silent_enabled'),
          ('flipToSilenceEnabled', 'flip_to_silence_enabled'),
          ('wakeScreenEnabled', 'wake_screen_enabled'),
          ('vibrateWithAdhan', 'vibrate_with_adhan'),
          ('adhanAlarmEnabled', 'adhan_alarm_enabled'),
          ('ongoingNotifEnabled', 'ongoing_notif_enabled'),
        ];
        final db = m.database;
        for (final (oldKey, newKey) in renames) {
          // Copy old value into new key (if new key doesn't exist yet)
          await db.customStatement(
            'INSERT OR IGNORE INTO user_settings (key, value) '
            'SELECT ?, value FROM user_settings WHERE key = ?',
            [newKey, oldKey],
          );
          // Remove the old camelCase row
          await db.customStatement('DELETE FROM user_settings WHERE key = ?', [
            oldKey,
          ]);
        }
      }
      if (from < 5) {
        await m.createTable(userAdhkar);
        await m.createTable(userDuas);
      }
      if (from < 6) {
        await m.createTable(bookReadingProgress);
      }
    },
  );

  Future<void> _seedDefaultData() async {
    // All keys are snake_case to match Supabase columns and UserPreferences.fromMap()
    await _insertSetting('madhab', 'shafi');
    await _insertSetting('calc_method', 'MWL');
    await _insertSetting('ramadan_mode', 'false');
    await _insertSetting('prayer_reminder', 'true');
    await _insertSetting('muhasaba_reminder', 'true');
    await _insertSetting('evening_reminder_time', '21:00');
    await _insertSetting('language', 'ar');

    final defaultIbadaat = [
      ('قراءة حديث', '📚', true, 3),
      ('دعاء مخصص', '🤲', true, 5),
      ('صلة الرحم', '👨‍👩‍👧', true, 10),
      ('غضّ البصر', '👁️', true, 10),
      ('الغيبة', '🗣️', false, -10),
      ('النميمة', '🗣️', false, -10),
      ('الكذب', '🗣️', false, -10),
      ('السب', '🗣️', false, -10),
      ('الشتم', '🗣️', false, -10),
      ('اللعن', '🗣️', false, -10),
    ];
    for (final item in defaultIbadaat) {
      await into(customIbadah).insert(
        CustomIbadahCompanion(
          nameAr: Value(item.$1),
          emoji: Value(item.$2),
          isPositive: Value(item.$3),
          points: Value(item.$4),
        ),
      );
    }
  }

  Future<void> _insertSetting(String key, String value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion(key: Value(key), value: Value(value)),
    );
  }
}

// ─────────────────────────────────────────
//  DATABASE CONNECTION
// ─────────────────────────────────────────
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'takwa.db'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL;');
        db.execute('PRAGMA busy_timeout=5000;');
      },
    );
  });
}
