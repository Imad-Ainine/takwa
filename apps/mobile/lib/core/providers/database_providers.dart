import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/database/daos.dart';
import 'package:takwa/core/updates/update_check_service.dart';

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

final zakatDaoProvider = Provider<ZakatDao>((ref) {
  return ZakatDao(ref.watch(appDatabaseProvider));
});

/// History stream — automatically refreshes via Drift's reactive stream
/// whenever a new calculation is saved (R1.1, R1.4).
final zakatHistoryProvider = StreamProvider<List<ZakatCalculation>>((ref) {
  return ref.watch(zakatDaoProvider).watchHistory();
});

final qadaDaoProvider = Provider<QadaDao>((ref) {
  return QadaDao(ref.watch(appDatabaseProvider));
});

final qadaCountersProvider = StreamProvider<List<QadaCounter>>((ref) {
  return ref.watch(qadaDaoProvider).watchAll();
});

/// Reactive sum of all prayers' owedCount and completedCount — backs the
/// summary row in QadaTrackerScreen (R6.1, R6.4).
final qadaSummaryProvider =
    StreamProvider<({int totalOwed, int totalCompleted})>((ref) {
      return ref.watch(qadaDaoProvider).watchSummary();
    });

final updateCheckServiceProvider = Provider<UpdateCheckService>((ref) {
  return UpdateCheckService(ref.watch(settingsDaoProvider));
});

// ── سجل الصدقات ──
final sadaqahHistoryProvider = StreamProvider<List<DailyRecord>>((ref) {
  return ref.watch(dailyRecordDaoProvider).watchSadaqahHistory();
});

final sadaqahTotalsProvider = FutureProvider.autoDispose<(double, double, double)>((
  ref,
) async {
  final dao = ref.watch(dailyRecordDaoProvider);
  final now = DateTime.now();
  final weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);
  final today = DateTime(now.year, now.month, now.day);

  final week = await dao.getSadaqahTotal(from: weekStart, to: today);
  final month = await dao.getSadaqahTotal(from: monthStart, to: today);
  final allTime = await dao.getSadaqahTotal();
  return (week, month, allTime);
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
