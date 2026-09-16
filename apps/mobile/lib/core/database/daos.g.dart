// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$DailyRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyRecordsTable get dailyRecords => attachedDatabase.dailyRecords;
  $ProhibitionsLogTable get prohibitionsLog => attachedDatabase.prohibitionsLog;
  $CustomIbadahTable get customIbadah => attachedDatabase.customIbadah;
  $CustomIbadahLogTable get customIbadahLog => attachedDatabase.customIbadahLog;
  $SyncOutboxTable get syncOutbox => attachedDatabase.syncOutbox;
  DailyRecordDaoManager get managers => DailyRecordDaoManager(this);
}

class DailyRecordDaoManager {
  final _$DailyRecordDaoMixin _db;
  DailyRecordDaoManager(this._db);
  $$DailyRecordsTableTableManager get dailyRecords =>
      $$DailyRecordsTableTableManager(_db.attachedDatabase, _db.dailyRecords);
  $$ProhibitionsLogTableTableManager get prohibitionsLog =>
      $$ProhibitionsLogTableTableManager(
        _db.attachedDatabase,
        _db.prohibitionsLog,
      );
  $$CustomIbadahTableTableManager get customIbadah =>
      $$CustomIbadahTableTableManager(_db.attachedDatabase, _db.customIbadah);
  $$CustomIbadahLogTableTableManager get customIbadahLog =>
      $$CustomIbadahLogTableTableManager(
        _db.attachedDatabase,
        _db.customIbadahLog,
      );
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db.attachedDatabase, _db.syncOutbox);
}

mixin _$SyncOutboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncOutboxTable get syncOutbox => attachedDatabase.syncOutbox;
  SyncOutboxDaoManager get managers => SyncOutboxDaoManager(this);
}

class SyncOutboxDaoManager {
  final _$SyncOutboxDaoMixin _db;
  SyncOutboxDaoManager(this._db);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db.attachedDatabase, _db.syncOutbox);
}

mixin _$StatsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyRecordsTable get dailyRecords => attachedDatabase.dailyRecords;
  $ProhibitionsLogTable get prohibitionsLog => attachedDatabase.prohibitionsLog;
  $AchievementsTable get achievements => attachedDatabase.achievements;
  StatsDaoManager get managers => StatsDaoManager(this);
}

class StatsDaoManager {
  final _$StatsDaoMixin _db;
  StatsDaoManager(this._db);
  $$DailyRecordsTableTableManager get dailyRecords =>
      $$DailyRecordsTableTableManager(_db.attachedDatabase, _db.dailyRecords);
  $$ProhibitionsLogTableTableManager get prohibitionsLog =>
      $$ProhibitionsLogTableTableManager(
        _db.attachedDatabase,
        _db.prohibitionsLog,
      );
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db.attachedDatabase, _db.achievements);
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserSettingsTable get userSettings => attachedDatabase.userSettings;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db.attachedDatabase, _db.userSettings);
}

mixin _$RemindersDaoMixin on DatabaseAccessor<AppDatabase> {
  $RemindersTable get reminders => attachedDatabase.reminders;
  RemindersDaoManager get managers => RemindersDaoManager(this);
}

class RemindersDaoManager {
  final _$RemindersDaoMixin _db;
  RemindersDaoManager(this._db);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db.attachedDatabase, _db.reminders);
}

mixin _$CustomIbadahDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomIbadahTable get customIbadah => attachedDatabase.customIbadah;
  $DailyRecordsTable get dailyRecords => attachedDatabase.dailyRecords;
  $CustomIbadahLogTable get customIbadahLog => attachedDatabase.customIbadahLog;
  CustomIbadahDaoManager get managers => CustomIbadahDaoManager(this);
}

class CustomIbadahDaoManager {
  final _$CustomIbadahDaoMixin _db;
  CustomIbadahDaoManager(this._db);
  $$CustomIbadahTableTableManager get customIbadah =>
      $$CustomIbadahTableTableManager(_db.attachedDatabase, _db.customIbadah);
  $$DailyRecordsTableTableManager get dailyRecords =>
      $$DailyRecordsTableTableManager(_db.attachedDatabase, _db.dailyRecords);
  $$CustomIbadahLogTableTableManager get customIbadahLog =>
      $$CustomIbadahLogTableTableManager(
        _db.attachedDatabase,
        _db.customIbadahLog,
      );
}

mixin _$PrayerTimesCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $PrayerTimesCacheTable get prayerTimesCache =>
      attachedDatabase.prayerTimesCache;
  PrayerTimesCacheDaoManager get managers => PrayerTimesCacheDaoManager(this);
}

class PrayerTimesCacheDaoManager {
  final _$PrayerTimesCacheDaoMixin _db;
  PrayerTimesCacheDaoManager(this._db);
  $$PrayerTimesCacheTableTableManager get prayerTimesCache =>
      $$PrayerTimesCacheTableTableManager(
        _db.attachedDatabase,
        _db.prayerTimesCache,
      );
}

mixin _$RamadanProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyRecordsTable get dailyRecords => attachedDatabase.dailyRecords;
  $RamadanProgressTable get ramadanProgress => attachedDatabase.ramadanProgress;
  RamadanProgressDaoManager get managers => RamadanProgressDaoManager(this);
}

class RamadanProgressDaoManager {
  final _$RamadanProgressDaoMixin _db;
  RamadanProgressDaoManager(this._db);
  $$DailyRecordsTableTableManager get dailyRecords =>
      $$DailyRecordsTableTableManager(_db.attachedDatabase, _db.dailyRecords);
  $$RamadanProgressTableTableManager get ramadanProgress =>
      $$RamadanProgressTableTableManager(
        _db.attachedDatabase,
        _db.ramadanProgress,
      );
}

mixin _$UserAdhkarDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserAdhkarTable get userAdhkar => attachedDatabase.userAdhkar;
  UserAdhkarDaoManager get managers => UserAdhkarDaoManager(this);
}

class UserAdhkarDaoManager {
  final _$UserAdhkarDaoMixin _db;
  UserAdhkarDaoManager(this._db);
  $$UserAdhkarTableTableManager get userAdhkar =>
      $$UserAdhkarTableTableManager(_db.attachedDatabase, _db.userAdhkar);
}

mixin _$UserDuasDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserDuasTable get userDuas => attachedDatabase.userDuas;
  UserDuasDaoManager get managers => UserDuasDaoManager(this);
}

class UserDuasDaoManager {
  final _$UserDuasDaoMixin _db;
  UserDuasDaoManager(this._db);
  $$UserDuasTableTableManager get userDuas =>
      $$UserDuasTableTableManager(_db.attachedDatabase, _db.userDuas);
}

mixin _$BookProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookReadingProgressTable get bookReadingProgress =>
      attachedDatabase.bookReadingProgress;
  BookProgressDaoManager get managers => BookProgressDaoManager(this);
}

class BookProgressDaoManager {
  final _$BookProgressDaoMixin _db;
  BookProgressDaoManager(this._db);
  $$BookReadingProgressTableTableManager get bookReadingProgress =>
      $$BookReadingProgressTableTableManager(
        _db.attachedDatabase,
        _db.bookReadingProgress,
      );
}
