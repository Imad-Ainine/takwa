import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/database/daos.dart';

// ── Singleton database ──
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── DAOs ──
final dailyRecordDaoProvider = Provider<DailyRecordDao>((ref) {
  return DailyRecordDao(ref.watch(appDatabaseProvider));
});

final statsDaoProvider = Provider<StatsDao>((ref) {
  return StatsDao(ref.watch(appDatabaseProvider));
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(appDatabaseProvider));
});

final customIbadahDaoProvider = Provider<CustomIbadahDao>((ref) {
  return CustomIbadahDao(ref.watch(appDatabaseProvider));
});

final prayerTimesCacheDaoProvider = Provider<PrayerTimesCacheDao>((ref) {
  return PrayerTimesCacheDao(ref.watch(appDatabaseProvider));
});

final ramadanProgressDaoProvider = Provider<RamadanProgressDao>((ref) {
  return RamadanProgressDao(ref.watch(appDatabaseProvider));
});

final userAdhkarDaoProvider = Provider<UserAdhkarDao>((ref) {
  return UserAdhkarDao(ref.watch(appDatabaseProvider));
});

final userDuasDaoProvider = Provider<UserDuasDao>((ref) {
  return UserDuasDao(ref.watch(appDatabaseProvider));
});

final bookProgressDaoProvider = Provider<BookProgressDao>((ref) {
  return BookProgressDao(ref.watch(appDatabaseProvider));
});

final syncOutboxDaoProvider = Provider<SyncOutboxDao>((ref) {
  return SyncOutboxDao(ref.watch(appDatabaseProvider));
});

// ── سجل اليوم (Stream) ──
final todayRecordProvider = StreamProvider<DailyRecord?>((ref) {
  return ref.watch(dailyRecordDaoProvider).watchTodayRecord();
});

// ── نقاط الأسبوع ──
final weeklyPointsProvider = StreamProvider<List<WeeklyPoint>>((ref) {
  return ref.watch(statsDaoProvider).watchWeeklyPoints();
});

// ── إحصائيات الشهر الحالي ──
final monthStatsProvider = StreamProvider<MonthStats>((ref) {
  final now = DateTime.now();
  return ref.watch(statsDaoProvider).watchMonthStats(now.year, now.month);
});

// ── السلسلة الحالية ──
final currentStreakProvider = StreamProvider<int>((ref) {
  return ref.watch(statsDaoProvider).watchCurrentStreak();
});

// ── إعداد معين ──
final settingProvider = FutureProvider.family<String?, String>((ref, key) {
  return ref.watch(settingsDaoProvider).get(key);
});

final settingStreamProvider = StreamProvider.family<String?, String>((
  ref,
  key,
) {
  return ref.watch(settingsDaoProvider).watch(key);
});

// ── وضع رمضان ──
final ramadanModeProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(settingsDaoProvider)
      .watch('ramadan_mode')
      .map((v) => v == 'true');
});

// ── فحص إكمال التهيئة ──
final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final v = await ref.watch(settingsDaoProvider).get('onboardingDone');
  return v == 'true';
});

// ── التذكيرات ──
final remindersDaoProvider = Provider<RemindersDao>((ref) {
  return RemindersDao(ref.watch(appDatabaseProvider));
});

final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(remindersDaoProvider).watchAll();
});

// ── Period-aware family providers (driven by the stats period selector) ──

/// Stats aggregated over a (from, to) date range.
final periodStatsProvider =
    StreamProvider.family<MonthStats, (DateTime, DateTime)>((ref, range) {
      return ref.watch(statsDaoProvider).watchStatsForRange(range.$1, range.$2);
    });

/// Daily point totals for every day in a (from, to) range (for bar chart).
final periodChartPointsProvider =
    StreamProvider.family<List<WeeklyPoint>, (DateTime, DateTime)>((
      ref,
      range,
    ) {
      return ref.watch(statsDaoProvider).watchPointsPerDay(range.$1, range.$2);
    });

/// Per-prayer attendance rates for a (from, to) date range.
final periodPrayerRatesProvider =
    StreamProvider.family<List<PrayerRateData>, (DateTime, DateTime)>((
      ref,
      range,
    ) {
      return ref
          .watch(statsDaoProvider)
          .watchPerPrayerRates(range.$1, range.$2);
    });
