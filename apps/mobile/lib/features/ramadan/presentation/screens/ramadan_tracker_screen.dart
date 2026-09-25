import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_switch.dart';
import 'package:takwa/core/widgets/takwa_error_state.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';
import 'package:takwa/features/ramadan/data/ramadan_duas_data.dart';
import 'package:takwa/features/ramadan/providers/ramadan_providers.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Ramadan-specific tracker: Suhoor/Iftar countdown, the day's curated dua,
/// a Qiyam al-layl toggle, today's fasting status (logged from the existing
/// daily checklist — this screen links to it rather than duplicating the
/// `_FastingSelector` UI/logic), and a 30-day progress strip.
///
/// See docs/specs/ramadan-fasting-tracker.md for the full spec this
/// implements.
class RamadanTrackerScreen extends ConsumerStatefulWidget {
  const RamadanTrackerScreen({super.key});

  @override
  ConsumerState<RamadanTrackerScreen> createState() =>
      _RamadanTrackerScreenState();
}

class _RamadanTrackerScreenState extends ConsumerState<RamadanTrackerScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Only the countdown text needs a per-second refresh; everything else
    // on this screen is provider-driven and rebuilds on its own.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = ref.watch(ramadanInfoProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, l10n, info),
                Expanded(
                  child: info.isRamadan
                      ? _buildContent(context, l10n, info)
                      : Center(
                          child: Text(
                            l10n.ramadanNotRamadanMessage,
                            style: context.typography.bodyLarge,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    RamadanInfo info,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          CustomLeadingButton(onPressed: () => Navigator.pop(context)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.ramadanTrackerAppBarTitle,
              style: context.typography.headingMedium,
            ),
          ),
          if (info.isRamadan)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: context.colors.goldDim,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                l10n.statsRamadanDayOf30(info.dayNumber),
                style: context.typography.labelMedium.copyWith(
                  color: context.colors.goldText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    RamadanInfo info,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CountdownCard(l10n: l10n),
          const SizedBox(height: AppSpacing.lg),
          _DuaOfDayCard(l10n: l10n, info: info),
          const SizedBox(height: AppSpacing.lg),
          _QiyamToggleCard(l10n: l10n, info: info),
          const SizedBox(height: AppSpacing.lg),
          _FastingLogCard(l10n: l10n, info: info),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.ramadanProgressStripTitle,
            style: context.typography.headingMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressStrip(info: info),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Suhoor / Iftar countdowns
// ─────────────────────────────────────────
class _CountdownCard extends ConsumerWidget {
  final AppLocalizations l10n;
  const _CountdownCard({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayers = ref.watch(prayerTimesProvider);

    return _Card(
      child: prayers.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
        // Same fallback shape as prayer_screen.dart's own _ErrorView (this
        // is almost always a missing/denied location permission, since
        // prayerTimesProvider needs a location to compute anything) — see
        // docs/specs/ramadan-fasting-tracker.md R7.
        error: (_, _) => _UnavailableTimes(l10n: l10n),
        data: (times) {
          final fajr = times.where((p) => p.name == 'fajr').firstOrNull;
          final maghrib = times.where((p) => p.name == 'maghrib').firstOrNull;
          if (fajr == null || maghrib == null) {
            return _UnavailableTimes(l10n: l10n);
          }

          final now = DateTime.now();
          // Both countdowns stay on screen at once (spec R2): the day's
          // Suhoor cutoff and its Iftar time are the two numbers a fasting
          // user wants together, not one at the user's expense.
          final fasting = now.isBefore(maghrib.time);

          return Row(
            children: [
              Expanded(
                child: _CountdownItem(
                  label: l10n.ramadanSuhoorEndsIn,
                  clock: _formatClock(fajr.time),
                  remaining: _until(now, fajr.time),
                ),
              ),
              Container(width: 1, height: 64, color: context.colors.border),
              Expanded(
                child: _CountdownItem(
                  label: fasting
                      ? l10n.ramadanIftarIn
                      : l10n.ramadanIftarTimeReached,
                  clock: _formatClock(maghrib.time),
                  remaining: fasting ? _until(now, maghrib.time) : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Time until the next occurrence of a daily clock time — today while it is
  /// still ahead, otherwise tomorrow, so Suhoor keeps counting after Fajr
  /// instead of going negative.
  static Duration _until(DateTime now, DateTime todayTarget) {
    final target = now.isBefore(todayTarget)
        ? todayTarget
        : todayTarget.add(const Duration(days: 1));
    return target.difference(now);
  }

  static String _formatClock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _CountdownItem extends StatelessWidget {
  final String label;
  final String clock;

  /// `null` once the moment has passed — the label then carries the news.
  final Duration? remaining;
  const _CountdownItem({
    required this.label,
    required this.clock,
    this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.typography.bodyMedium.copyWith(
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (remaining != null)
          Text(
            _CountdownCard._formatDuration(remaining!),
            style: context.typography.displayMedium.copyWith(
              fontSize: 26,
              color: context.colors.gold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        else
          IslamicGlyph(
            '🌙',
            size: 34,
            color: context.typography.displayLarge.color,
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          clock,
          style: context.typography.caption.copyWith(
            color: context.colors.textDim,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _UnavailableTimes extends ConsumerWidget {
  final AppLocalizations l10n;
  const _UnavailableTimes({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TakwaErrorState(
      onRetry: () => ref.invalidate(prayerTimesProvider),
      message: l10n.ramadanPrayerTimesUnavailable,
      compact: true,
    );
  }
}

// ─────────────────────────────────────────
//  Dua of the day
// ─────────────────────────────────────────
class _DuaOfDayCard extends StatelessWidget {
  final AppLocalizations l10n;
  final RamadanInfo info;
  const _DuaOfDayCard({required this.l10n, required this.info});

  @override
  Widget build(BuildContext context) {
    final dua = ramadanDuaForDay(info.dayNumber);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.ramadanDuaOfDayTitle,
            style: context.typography.labelLarge.copyWith(
              color: context.colors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dua.arabic,
            textAlign: TextAlign.center,
            style: context.typography.quranicVerse,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            dua.source,
            textAlign: TextAlign.center,
            style: context.typography.caption,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Qiyam al-layl toggle
// ─────────────────────────────────────────
class _QiyamToggleCard extends ConsumerWidget {
  final AppLocalizations l10n;
  final RamadanInfo info;
  const _QiyamToggleCard({required this.l10n, required this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(ramadanTodayProgressProvider).valueOrNull;
    final todayRecord = ref.watch(todayRecordProvider).valueOrNull;
    final value = progress?.iHyaLayl ?? false;

    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ramadanIhyaLaylLabel,
                  style: context.typography.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.ramadanIhyaLaylSublabel,
                  style: context.typography.caption,
                ),
              ],
            ),
          ),
          PrimarySwitch(
            value: value,
            onChanged: (v) {
              ref
                  .read(ramadanProgressDaoProvider)
                  .updateProgress(
                    RamadanProgressCompanion(
                      year: Value(info.hijriYear),
                      dayNumber: Value(info.dayNumber),
                      recordId: todayRecord != null
                          ? Value(todayRecord.id)
                          : const Value.absent(),
                      iHyaLayl: Value(v),
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Today's fasting log
//
//  `DailyRecords.fastingType` stays the single source of truth (points,
//  statistics and sync all read it); the tracker writes it directly and
//  links the day's `RamadanProgress` row to the same record, so logging
//  here and logging from the checklist are the same fact.
// ─────────────────────────────────────────
class _FastingLogCard extends ConsumerWidget {
  final AppLocalizations l10n;
  final RamadanInfo info;
  const _FastingLogCard({required this.l10n, required this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(todayRecordProvider).valueOrNull;
    final current = record?.fastingType ?? FastingType.none;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ramadanFastingStatusTitle,
                  style: context.typography.labelLarge,
                ),
              ),
              const IslamicGlyph('🌙', size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.ramadanFastingLogHint,
            style: context.typography.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _FastingChip(
                label: l10n.fastingTypeFard,
                value: FastingType.fard,
                current: current,
                color: context.colors.gold,
                info: info,
              ),
              const SizedBox(width: 6),
              _FastingChip(
                label: l10n.fastingTypeNafl,
                value: FastingType.nafl,
                current: current,
                color: context.colors.teal,
                info: info,
              ),
              const SizedBox(width: 6),
              _FastingChip(
                label: l10n.fastingTypeMakruh,
                value: FastingType.makruh,
                current: current,
                color: context.colors.warning,
                info: info,
              ),
              const SizedBox(width: 6),
              _FastingChip(
                label: l10n.fastingTypeNone,
                value: FastingType.none,
                current: current,
                color: context.colors.textDim,
                info: info,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FastingChip extends ConsumerWidget {
  final String label;
  final FastingType value;
  final FastingType current;
  final Color color;
  final RamadanInfo info;
  const _FastingChip({
    required this.label,
    required this.value,
    required this.current,
    required this.color,
    required this.info,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _logFasting(ref, context, value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : context.colors.card2,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.45)
                  : context.colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.typography.caption.copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Local write first, cloud second: the Drift row is what this screen and
  /// the checklist render from, so a sync failure must not look like the tap
  /// did nothing.
  Future<void> _logFasting(
    WidgetRef ref,
    BuildContext context,
    FastingType value,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final dao = ref.read(dailyRecordDaoProvider);
    final DailyRecord record;
    try {
      final today = await dao.getOrCreateToday();
      await dao.updateFasting(today.id, value);
      await ref
          .read(ramadanProgressDaoProvider)
          .updateProgress(
            RamadanProgressCompanion(
              year: Value(info.hijriYear),
              dayNumber: Value(info.dayNumber),
              recordId: Value(today.id),
            ),
          );
      // `updateFasting` doesn't return the row, and sync needs the post-write
      // values (points changed along with the fasting type).
      record = await dao.getOrCreateToday();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checklistSaveError)),
        );
      }
      return;
    }
    try {
      await ref.read(syncManagerProvider).syncDailyRecord(record);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checklistSyncError)),
        );
      }
    }
  }
}

// ─────────────────────────────────────────
//  30-day progress strip
// ─────────────────────────────────────────
class _ProgressStrip extends ConsumerWidget {
  final RamadanInfo info;
  const _ProgressStrip({required this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(ramadanMonthRecordsProvider).valueOrNull ?? [];
    final byDate = {
      for (final r in records) DateTime(r.date.year, r.date.month, r.date.day): r,
    };
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(info.totalDays, (i) {
        final date = info.gregorianStart.add(Duration(days: i));
        final record = byDate[date];
        final isToday = date == todayOnly;
        final isFuture = date.isAfter(todayOnly);
        final fasted =
            record != null &&
            record.fastingType != FastingType.none &&
            record.fastingType != FastingType.makruh;
        // "أفطر بعذر" is its own state, not a missed day: it must not read as
        // a failure in the strip, and it never counts toward 30/30.
        final excused = record?.fastingType == FastingType.makruh;

        final Color bg;
        final Color fg;
        if (fasted) {
          bg = context.colors.gold;
          fg = context.colors.background;
        } else if (isFuture) {
          bg = context.colors.card2;
          fg = context.colors.textDim;
        } else if (excused) {
          bg = context.colors.warning.withValues(alpha: 0.18);
          fg = context.colors.warningText;
        } else {
          bg = context.colors.dangerDim;
          fg = context.colors.dangerText;
        }

        return Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: context.colors.teal, width: 2)
                : null,
          ),
          child: Text(
            '${i + 1}',
            style: context.typography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────
//  Shared card shell
// ─────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}
