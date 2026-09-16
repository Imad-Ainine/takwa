import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Totals + history for Sadaqah logged via the daily checklist. See
/// docs/specs/sadaqah-tracker.md — this is a read-only view over
/// `DailyRecords.sadaqah`/`sadaqahAmount`, no new table.
class SadaqahTrackerScreen extends ConsumerWidget {
  const SadaqahTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

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
                _buildAppBar(context, l10n),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TotalsRow(l10n: l10n),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.sadaqahHistoryTitle,
                          style: context.typography.headingMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _HistoryList(l10n: l10n),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
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

  Widget _buildAppBar(BuildContext context, AppLocalizations l10n) {
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
              l10n.sadaqahTrackerAppBarTitle,
              style: context.typography.headingMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends ConsumerWidget {
  final AppLocalizations l10n;
  const _TotalsRow({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(sadaqahTotalsProvider);

    return totalsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: TakwaLoadingIndicator()),
      ),
      error: (_, _) => const SizedBox(),
      data: (totals) {
        final (week, month, allTime) = totals;
        return Row(
          children: [
            Expanded(
              child: _totalCard(context, l10n.sadaqahTotalsWeekLabel, week),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _totalCard(context, l10n.sadaqahTotalsMonthLabel, month),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _totalCard(
                context,
                l10n.sadaqahTotalsAllTimeLabel,
                allTime,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _totalCard(BuildContext context, String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Text(
            value > 0 ? value.toStringAsFixed(0) : '—',
            style: context.typography.headingMedium.copyWith(
              color: context.colors.gold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.typography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final AppLocalizations l10n;
  const _HistoryList({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sadaqahHistoryProvider);

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: TakwaLoadingIndicator()),
      ),
      error: (_, _) => const SizedBox(),
      data: (records) {
        if (records.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                l10n.sadaqahHistoryEmpty,
                style: context.typography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          );
        }
        final dateFmt = DateFormat.yMMMd();
        return Column(
          children: records
              .map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFmt.format(r.date),
                        style: context.typography.bodyMedium,
                      ),
                      Text(
                        r.sadaqahAmount > 0
                            ? r.sadaqahAmount.toStringAsFixed(2)
                            : l10n.sadaqahLoggedNoAmount,
                        style: context.typography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: r.sadaqahAmount > 0
                              ? context.colors.textPrimary
                              : context.colors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
