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
              Text(prayerEmoji(prayerName), style: const TextStyle(fontSize: 26)),
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
    final controller = TextEditingController(text: current.toString());
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.qadaSetOwedDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('—'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.qadaSetOwedConfirm),
          ),
        ],
      ),
    );
    if (result == null) return;
    final parsed = int.tryParse(result);
    if (parsed == null) return;
    await ref.read(qadaDaoProvider).setOwed(prayerName, parsed);
  }
}
