import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/features/reminders/presentation/widgets/advice_card.dart';
import 'package:takwa/features/reminders/presentation/widgets/reminder_card.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/features/reminders/presentation/widgets/add_reminder_bottom_sheet.dart';
import 'package:takwa/l10n/app_localizations.dart';

class RemindersListScreen extends ConsumerWidget {
  const RemindersListScreen({super.key});

  void _showAddReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddReminderBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29).
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildAddReminderButton(context),
                    const SizedBox(height: 28),
                    remindersAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxxl),
                          child: TakwaLoadingIndicator(size: 32),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          l10n.adhkarGenericError(e.toString()),
                          style: context.typography.bodySmall,
                        ),
                      ),
                      data: (reminders) => reminders.isEmpty
                          ? _buildEmptyState(context)
                          : _buildRemindersList(context, ref, reminders),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AdviceCard(
                      title: l10n.remindersAdviceTitle,
                      description: l10n.remindersAdviceDesc,
                    ),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AppBarWidget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppBarWidget(
      leading: const CustomLeadingButton(),
      title: l10n.remindersScreenTitle,
    );
  }

  Widget _buildAddReminderButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => _showAddReminderSheet(context),
      borderRadius: AppRadius.card,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: context.colors.card.withValues(alpha: 0.85),
          borderRadius: AppRadius.card,
          border: Border.all(
            color: context.colors.teal.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.tealDim,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: context.colors.teal,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.remindersAddButtonTitle,
              style: context.typography.headingMedium.copyWith(
                color: context.colors.teal,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.remindersAddButtonSubtitle,
              style: context.typography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: context.colors.textDim,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.remindersEmptyTitle,
            style: context.typography.headingMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.remindersEmptySubtitle,
            style: context.typography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList(
    BuildContext context,
    WidgetRef ref,
    List<Reminder> reminders,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.remindersMyRemindersTitle, style: context.typography.headingMedium),
            const Spacer(),
            TaqwaBadge(
              label: l10n.remindersCountBadge(reminders.length),
              color: context.colors.teal,
              bgColor: context.colors.tealDim,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...reminders.map(
          (reminder) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Dismissible(
              key: ValueKey(reminder.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsetsDirectional.only(end: 20),
                decoration: BoxDecoration(
                  color: context.colors.dangerDim,
                  borderRadius: AppRadius.card,
                  border: Border.all(
                    color: context.colors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: context.colors.danger,
                ),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.remindersDeleteDialogTitle),
                    content: Text(
                      l10n.remindersDeleteDialogConfirm(reminder.title),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.adhkarCancelButton),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          l10n.adhkarDeleteTooltip,
                          style: TextStyle(color: context.colors.danger),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) {
                ref.read(remindersDaoProvider).deleteReminder(reminder.id);
                ref.read(syncManagerProvider).deleteReminder(reminder.id);
              },
              child: ReminderCard(
                title: reminder.title,
                time: _formatTime(context, reminder.time),
                iconKey: reminder.iconName,
                isEnabled: reminder.isEnabled,
                onToggle: (val) {
                  ref
                      .read(remindersDaoProvider)
                      .toggleEnabled(reminder.id, val);
                  // Sync updated reminder
                  ref
                      .read(syncManagerProvider)
                      .syncReminder(reminder.copyWith(isEnabled: val));
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Convert 24h "HH:mm" stored time to a localized display string
  String _formatTime(BuildContext context, String time24) {
    try {
      final l10n = AppLocalizations.of(context)!;
      final parts = time24.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final period = h >= 12 ? l10n.timePeriodPm : l10n.timePeriodAm;
      final displayH = h % 12 == 0 ? 12 : h % 12;
      return '$displayH:${m.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return time24;
    }
  }
}
