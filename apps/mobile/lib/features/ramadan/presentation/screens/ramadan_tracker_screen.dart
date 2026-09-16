import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_switch.dart';
import 'package:takwa/core/widgets/takwa_error_state.dart';
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
          _FastingStatusCard(l10n: l10n),
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
//  Suhoor / Iftar countdown
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
        error: (_, _) => TakwaErrorState(
          onRetry: () => ref.invalidate(prayerTimesProvider),
          message: l10n.ramadanPrayerTimesUnavailable,
          compact: true,
        ),
        data: (times) {
          final fajr = times.where((p) => p.name == 'fajr').firstOrNull;
          final maghrib = times.where((p) => p.name == 'maghrib').firstOrNull;
          if (fajr == null || maghrib == null) {
            return TakwaErrorState(
              onRetry: () => ref.invalidate(prayerTimesProvider),
              message: l10n.ramadanPrayerTimesUnavailable,
              compact: true,
            );
          }

          final now = DateTime.now();
          final DateTime target;
          final String label;
          final bool reached;

          if (now.isBefore(fajr.time)) {
            target = fajr.time;
            label = l10n.ramadanSuhoorEndsIn;
            reached = false;
          } else if (now.isBefore(maghrib.time)) {
            target = maghrib.time;
            label = l10n.ramadanIftarIn;
            reached = false;
          } else {
            target = fajr.time.add(const Duration(days: 1));
            label = l10n.ramadanIftarTimeReached;
            reached = true;
          }

          final remaining = target.difference(DateTime.now());

          return Column(
            children: [
              Text(
                label,
                style: context.typography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!reached)
                Text(
                  _formatDuration(remaining),
                  style: context.typography.displayMedium.copyWith(
                    color: context.colors.gold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
              else
                Text('🌙', style: context.typography.displayLarge),
            ],
          );
        },
      ),
    );
  }

  static String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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
//  Today's fasting status (read-only here — logging stays on the checklist,
//  the single source of truth for `DailyRecords.fastingType`)
// ─────────────────────────────────────────
class _FastingStatusCard extends ConsumerWidget {
  final AppLocalizations l10n;
  const _FastingStatusCard({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(todayRecordProvider).valueOrNull;
    final fastingType = record?.fastingType ?? FastingType.none;

    final String statusText;
    final Color statusColor;
    switch (fastingType) {
      case FastingType.fard:
        statusText = l10n.ramadanFastingDoneFard;
        statusColor = context.colors.success;
      case FastingType.nafl:
        statusText = l10n.ramadanFastingDoneNafl;
        statusColor = context.colors.success;
      case FastingType.none:
      case FastingType.makruh:
        statusText = l10n.ramadanFastingNotLogged;
        statusColor = context.colors.textSecondary;
    }

    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ramadanFastingStatusTitle,
                  style: context.typography.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: context.typography.bodyMedium.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (fastingType == FastingType.none)
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.checklist),
              child: Text(l10n.ramadanLogFastingButton),
            ),
        ],
      ),
    );
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

        final Color bg;
        final Color fg;
        if (fasted) {
          bg = context.colors.gold;
          fg = context.colors.background;
        } else if (isFuture) {
          bg = context.colors.card2;
          fg = context.colors.textDim;
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
