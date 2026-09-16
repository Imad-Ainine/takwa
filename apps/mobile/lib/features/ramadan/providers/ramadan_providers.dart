import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/utils/ramadan_info.dart';

export 'package:takwa/core/utils/ramadan_info.dart';

/// Not a StreamProvider — the underlying value only changes once a day (at
/// most), so recomputing it once per screen visit is enough; there is no
/// Hijri-calendar "ticker" to watch.
final ramadanInfoProvider = Provider<RamadanInfo>((ref) => computeRamadanInfo());

/// Live `RamadanProgress` row (currently just `iHyaLayl`) for today's Hijri
/// Ramadan day.
final ramadanTodayProgressProvider = StreamProvider.autoDispose<RamadanProgressData?>((
  ref,
) {
  final info = ref.watch(ramadanInfoProvider);
  if (!info.isRamadan) return Stream.value(null);
  return ref
      .watch(ramadanProgressDaoProvider)
      .watchProgress(info.hijriYear, info.dayNumber);
});

/// `DailyRecords` for every day in the current Ramadan range, for the
/// tracker's 30-day fasting strip.
final ramadanMonthRecordsProvider =
    StreamProvider.autoDispose<List<DailyRecord>>((ref) {
      final info = ref.watch(ramadanInfoProvider);
      if (!info.isRamadan) return Stream.value(const <DailyRecord>[]);
      return ref
          .watch(ramadanProgressDaoProvider)
          .watchRecordsForRange(info.gregorianStart, info.gregorianEnd);
    });
