import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/database/daos.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/utils/prayer_display.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Lifetime "missed prayers owed" counter, per prayer. See
/// docs/specs/qada-prayer-tracker.md — deliberately unrelated to
/// PrayerStatus.qadaa, which marks a single same-day prayer as done late.
class QadaTrackerScreen extends ConsumerWidget {
  const QadaTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final countersAsync = ref.watch(qadaCountersProvider);

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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(
                    l10n.qadaIntroText,
                    style: context.typography.caption,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // R6.1 — Summary row at the top
                const _SummaryRow(),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: countersAsync.when(
                    loading: () =>
                        const Center(child: TakwaLoadingIndicator()),
                    error: (_, _) => const SizedBox(),
                    data: (rows) {
                      final byPrayer = {
                        for (final r in rows) r.prayerName: r,
                      };
                      return ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        children: QadaDao.prayerNames
                            .map(
                              (name) => _PrayerCounterCard(
                                prayerName: name,
                                counter: byPrayer[name],
                                l10n: l10n,
                              ),
                            )
                            .toList(),
                      );
                    },
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
              l10n.qadaAppBarTitle,
              style: context.typography.headingMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary row showing the aggregate totals across all prayers (R6.1, R6.4).
class _SummaryRow extends ConsumerWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(qadaSummaryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (summary) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryStat(
                  label: l10n.qadaSummaryTotalOwed(summary.totalOwed),
                  color: context.colors.warning,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: context.colors.border,
                ),
                _SummaryStat(
                  label: l10n.qadaSummaryTotalCompleted(summary.totalCompleted),
                  color: context.colors.success,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryStat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.typography.labelLarge.copyWith(color: color),
    );
  }
}

class _PrayerCounterCard extends ConsumerWidget {
  final String prayerName;
  final QadaCounter? counter;
  final AppLocalizations l10n;

  const _PrayerCounterCard({
    required this.prayerName,
    required this.counter,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owed = counter?.owedCount ?? 0;
    final completed = counter?.completedCount ?? 0;

    // R6.2 — progress = completedCount / (owedCount + completedCount), clamped
    // R6.3 — when both are 0, result is exactly 0.0 (no division by zero)
    final total = owed + completed;
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IslamicGlyph(prayerEmoji(prayerName), size: 26),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  prayerLocalizedName(l10n, prayerName),
                  style: context.typography.labelLarge,
                ),
              ),
              _statChip(context, l10n.qadaOwedLabel, owed.toString(), context.colors.warning),
              const SizedBox(width: AppSpacing.sm),
              _statChip(
                context,
                l10n.qadaCompletedLabel,
                completed.toString(),
                context.colors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // R6.2, R6.3 — per-card linear progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: context.colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: l10n.qadaMarkOneDoneButton,
                  isOutline: true,
                  onTap: owed <= 0
                      ? null
                      : () => ref
                            .read(qadaDaoProvider)
                            .markOneCompleted(prayerName),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () => _showSetOwedDialog(context, ref, owed),
                child: Text(l10n.qadaSetOwedButton),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: context.typography.labelLarge.copyWith(color: color),
          ),
          Text(label, style: context.typography.caption),
        ],
      ),
    );
  }

  Future<void> _showSetOwedDialog(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _SetOwedDialog(
        l10n: l10n,
        currentValue: current,
      ),
    );
    if (result == null) return;
    await ref.read(qadaDaoProvider).setOwed(prayerName, result);
  }
}

/// Stateful dialog for setting the owed count on a prayer (R7.1, R7.2, R7.3).
///
/// - Allows 0 as a valid value (R7.1)
/// - Shows an inline error and keeps the dialog open for negative or
///   non-numeric input without calling any DAO method (R7.3)
class _SetOwedDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final int currentValue;

  const _SetOwedDialog({required this.l10n, required this.currentValue});

  @override
  State<_SetOwedDialog> createState() => _SetOwedDialogState();
}

class _SetOwedDialogState extends State<_SetOwedDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final raw = _controller.text.trim();
    final parsed = int.tryParse(raw);

    // R7.3 — reject non-numeric or negative; keep dialog open
    if (parsed == null || parsed < 0) {
      setState(() {
        _errorText = widget.l10n.qadaSetOwedErrorInvalid;
        // Restore the previous valid value in the field
        _controller.text = widget.currentValue.toString();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
      return;
    }

    // R7.1 — 0 is valid
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.qadaSetOwedDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        onChanged: (_) {
          // Clear error as the user starts typing
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        decoration: InputDecoration(
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('—'),
        ),
        TextButton(
          onPressed: _onConfirm,
          child: Text(widget.l10n.qadaSetOwedConfirm),
        ),
      ],
    );
  }
}
