import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_switch.dart';
import 'package:takwa/core/widgets/takwa_error_state.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/features/circles/domain/circle_models.dart';
import 'package:takwa/features/circles/providers/circles_providers.dart';
import 'package:takwa/l10n/app_localizations.dart';

class CircleDetailScreen extends ConsumerWidget {
  final CircleSummary circle;
  const CircleDetailScreen({super.key, required this.circle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myUserId = ref.watch(supabaseUserProvider).value?.id;

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
                        _InviteCodeCard(circle: circle, l10n: l10n),
                        const SizedBox(height: AppSpacing.lg),
                        if (myUserId != null)
                          _SharingSettingsCard(
                            circleId: circle.id,
                            myUserId: myUserId,
                            l10n: l10n,
                          ),
                        if (myUserId != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _ReceivedReactions(
                            circleId: circle.id,
                            myUserId: myUserId,
                            l10n: l10n,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.circleLeaderboardTitle,
                          style: context.typography.headingMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _Leaderboard(
                          circleId: circle.id,
                          myUserId: myUserId,
                          l10n: l10n,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _LeaveButton(circle: circle, l10n: l10n),
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
            child: Text(circle.name, style: context.typography.headingMedium),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final CircleSummary circle;
  final AppLocalizations l10n;
  const _InviteCodeCard({required this.circle, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.goldDim,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.circlesInviteCodeLabel, style: context.typography.caption),
                const SizedBox(height: 2),
                Text(
                  circle.inviteCode,
                  style: context.typography.headingLarge.copyWith(
                    color: context.colors.goldText,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.share_rounded, color: context.colors.gold),
            tooltip: l10n.circlesShareInviteButton,
            onPressed: () {
              HapticFeedback.lightImpact();
              SharePlus.instance.share(
                ShareParams(text: circle.inviteCode),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SharingSettingsCard extends ConsumerWidget {
  final String circleId;
  final String myUserId;
  final AppLocalizations l10n;
  const _SharingSettingsCard({
    required this.circleId,
    required this.myUserId,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRow = ref.watch(
      myCircleMembershipProvider((circleId: circleId, myUserId: myUserId)),
    );

    // Non-null value on the leaderboard row means "this signal is shared"
    // — see myCircleMembershipProvider's own comment for why that's a safe
    // inference from get_circle_leaderboard()'s null-when-not-shared shape.
    final shareStreak = myRow?.currentStreak != null;
    final sharePoints = myRow?.totalPoints != null;
    final shareChecklist = myRow?.checklistDoneToday != null;
    final shareQuran = myRow?.quranPages != null;

    Future<void> update({
      bool? streak,
      bool? points,
      bool? checklist,
      bool? quran,
    }) async {
      await ref
          .read(supabaseServiceProvider)
          .updateCircleSharing(
            circleId: circleId,
            shareStreak: streak ?? shareStreak,
            sharePoints: points ?? sharePoints,
            shareChecklistDone: checklist ?? shareChecklist,
            shareQuranPages: quran ?? shareQuran,
          );
      ref.invalidate(circleLeaderboardProvider(circleId));
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.circleSharingSectionTitle, style: context.typography.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          _toggleRow(
            context,
            l10n.circleShareStreakLabel,
            shareStreak,
            (v) => update(streak: v),
          ),
          _toggleRow(
            context,
            l10n.circleSharePointsLabel,
            sharePoints,
            (v) => update(points: v),
          ),
          _toggleRow(
            context,
            l10n.circleShareChecklistLabel,
            shareChecklist,
            (v) => update(checklist: v),
          ),
          _toggleRow(
            context,
            l10n.circleShareQuranLabel,
            shareQuran,
            (v) => update(quran: v),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.typography.bodyMedium)),
          PrimarySwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ReceivedReactions extends ConsumerWidget {
  final String circleId;
  final String myUserId;
  final AppLocalizations l10n;
  const _ReceivedReactions({
    required this.circleId,
    required this.myUserId,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactionsAsync = ref.watch(
      circleReactionsReceivedProvider((circleId: circleId, myUserId: myUserId)),
    );
    // Reuses the leaderboard's already-fetched rows to resolve a sender's
    // display name instead of a second query — see the provider's own doc
    // comment on circleReactionsReceivedProvider.
    final members = ref.watch(circleLeaderboardProvider(circleId)).valueOrNull;

    return reactionsAsync.maybeWhen(
      data: (reactions) {
        if (reactions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.circleReactionsReceivedTitle,
              style: context.typography.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...reactions.map((r) {
              final phrase = ReactionPhrase.fromKey(r.phraseKey);
              final sender = members
                  ?.where((m) => m.userId == r.fromUserId)
                  .firstOrNull;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.colors.successDim,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Text(
                      phrase?.emoji ?? '💌',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        phrase != null
                            ? '${sender?.username ?? ''} — ${reactionPhraseLabel(l10n, phrase)}'
                            : sender?.username ?? '',
                        style: context.typography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

enum _SortMetric { points, streak }

/// Which metric a circle's member list is currently sorted by. `family`
/// scopes it per-circle rather than app-wide — StateProvider.family caches
/// one value per circleId, defaulting to points.
final _leaderboardSortProvider = StateProvider.family<_SortMetric, String>(
  (ref, circleId) => _SortMetric.points,
);

class _Leaderboard extends ConsumerWidget {
  final String circleId;
  final String? myUserId;
  final AppLocalizations l10n;
  const _Leaderboard({
    required this.circleId,
    required this.myUserId,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(circleLeaderboardProvider(circleId));
    final sortMetric = ref.watch(_leaderboardSortProvider(circleId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SortSelector(circleId: circleId, l10n: l10n),
        const SizedBox(height: AppSpacing.sm),
        rowsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: TakwaLoadingIndicator()),
          ),
          error: (_, _) => TakwaErrorState(
            onRetry: () => ref.invalidate(circleLeaderboardProvider(circleId)),
            message: l10n.circleErrorGeneric,
            compact: true,
          ),
          data: (rows) {
            final sorted = [...rows]..sort((a, b) {
              final aVal = sortMetric == _SortMetric.streak
                  ? a.currentStreak
                  : a.totalPoints;
              final bVal = sortMetric == _SortMetric.streak
                  ? b.currentStreak
                  : b.totalPoints;
              return (bVal ?? -1).compareTo(aVal ?? -1);
            });
            return Column(
              children: sorted
                  .map(
                    (row) => _MemberTile(
                      row: row,
                      isMe: row.userId == myUserId,
                      circleId: circleId,
                      l10n: l10n,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SortSelector extends ConsumerWidget {
  final String circleId;
  final AppLocalizations l10n;
  const _SortSelector({required this.circleId, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(_leaderboardSortProvider(circleId));
    return Row(
      children: [
        Expanded(
          child: _option(
            context,
            ref,
            l10n.circleSortByPoints,
            _SortMetric.points,
            current,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _option(
            context,
            ref,
            l10n.circleSortByStreak,
            _SortMetric.streak,
            current,
          ),
        ),
      ],
    );
  }

  Widget _option(
    BuildContext context,
    WidgetRef ref,
    String label,
    _SortMetric metric,
    _SortMetric current,
  ) {
    final selected = metric == current;
    return GestureDetector(
      onTap: () =>
          ref.read(_leaderboardSortProvider(circleId).notifier).state = metric,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.colors.tealDim : context.colors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? context.colors.teal : context.colors.border,
          ),
        ),
        child: Text(
          label,
          style: context.typography.labelMedium.copyWith(
            color: selected ? context.colors.tealText : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final CircleMemberRow row;
  final bool isMe;
  final String circleId;
  final AppLocalizations l10n;
  const _MemberTile({
    required this.row,
    required this.isMe,
    required this.circleId,
    required this.l10n,
  });

  static const _hidden = '—';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Text(row.avatarEmoji ?? '🙂', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.username ?? '—',
                  style: context.typography.labelLarge,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _stat(context, '🔥', row.currentStreak?.toString() ?? _hidden),
                    const SizedBox(width: AppSpacing.md),
                    _stat(context, '⭐', row.totalPoints?.toString() ?? _hidden),
                    const SizedBox(width: AppSpacing.md),
                    _stat(context, '📖', row.quranPages?.toString() ?? _hidden),
                    const SizedBox(width: AppSpacing.md),
                    _stat(
                      context,
                      row.checklistDoneToday == null
                          ? '✅'
                          : (row.checklistDoneToday! ? '✅' : '⬜'),
                      row.checklistDoneToday == null ? _hidden : '',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMe)
            IconButton(
              icon: const Icon(Icons.favorite_border_rounded),
              tooltip: l10n.circleSendReactionTooltip,
              color: context.colors.gold,
              onPressed: () => _showReactionSheet(context, ref),
            ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(value, style: context.typography.caption),
      ],
    );
  }

  Future<void> _showReactionSheet(BuildContext context, WidgetRef ref) async {
    final phrase = await showModalBottomSheet<ReactionPhrase>(
      context: context,
      builder: (context) => _ReactionPicker(l10n: l10n),
    );
    if (phrase == null || !context.mounted) return;
    try {
      await ref
          .read(supabaseServiceProvider)
          .sendCircleReaction(
            circleId: circleId,
            toUserId: row.userId,
            phraseKey: phrase.key,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.circleReactionSentMessage)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.circleErrorGeneric)),
        );
      }
    }
  }
}

String reactionPhraseLabel(AppLocalizations l10n, ReactionPhrase p) => switch (p) {
  ReactionPhrase.duaForYou => l10n.reactionPhraseDuaForYou,
  ReactionPhrase.keepGoing => l10n.reactionPhraseKeepGoing,
  ReactionPhrase.proudOfYou => l10n.reactionPhraseProudOfYou,
  ReactionPhrase.youCanDoIt => l10n.reactionPhraseYouCanDoIt,
  ReactionPhrase.mashallah => l10n.reactionPhraseMashallah,
};

class _ReactionPicker extends StatelessWidget {
  final AppLocalizations l10n;
  const _ReactionPicker({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.circleReactionSheetTitle, style: context.typography.headingMedium),
            const SizedBox(height: AppSpacing.md),
            ...ReactionPhrase.values.map(
              (p) => ListTile(
                leading: Text(p.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(reactionPhraseLabel(l10n, p)),
                onTap: () => Navigator.pop(context, p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveButton extends ConsumerWidget {
  final CircleSummary circle;
  final AppLocalizations l10n;
  const _LeaveButton({required this.circle, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.circlesLeaveConfirmTitle),
            content: Text(l10n.circlesLeaveConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('—'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.circlesLeaveButton),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(myCirclesProvider.notifier).leave(circle.id);
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Text(
        l10n.circlesLeaveButton,
        style: TextStyle(color: context.colors.danger),
      ),
    );
  }
}
