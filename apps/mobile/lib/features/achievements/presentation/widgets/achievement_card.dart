import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/achievements/providers/achievements_providers.dart';
import 'package:intl/intl.dart' as intl;
import 'package:takwa/l10n/app_localizations.dart';

class AchievementCard extends ConsumerStatefulWidget {
  final AchievementView achievement;
  final VoidCallback onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.onTap,
  });

  @override
  ConsumerState<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends ConsumerState<AchievementCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _unlockCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  // Captured once at mount so a mid-animation rebuild (e.g. the provider
  // refetching) can't restart or cancel a celebration already in flight.
  late final bool _celebrating;

  @override
  void initState() {
    super.initState();
    _celebrating = widget.achievement.isNewlyUnlocked;

    _unlockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_unlockCtrl);
    _glow = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _unlockCtrl, curve: Curves.easeOut));

    if (_celebrating) {
      _unlockCtrl.forward();
      // Fire-and-forget: don't block the animation on the write, and a
      // failure here just means the celebration replays next visit —
      // harmless, not worth surfacing to the user.
      ref
          .read(statsDaoProvider)
          .markAchievementSeen(widget.achievement.definition.id)
          .catchError((_) {});
    } else {
      _unlockCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _unlockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;
    final achievement = widget.achievement;
    final isEarned = achievement.isEarned;
    final def = achievement.definition;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _unlockCtrl,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isEarned ? colors.card : colors.card.withValues(alpha: 0.5),
            gradient: isEarned ? colors.cardGradient : null,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isEarned
                  ? colors.gold.withValues(alpha: 0.4)
                  : colors.border.withValues(alpha: 0.6),
              width: isEarned ? 1.5 : 1,
            ),
            boxShadow: isEarned
                ? [
                    ...context.shadows.card,
                    if (_celebrating)
                      BoxShadow(
                        color: colors.gold.withValues(alpha: 0.55 * _glow.value),
                        blurRadius: 32 * _glow.value,
                        spreadRadius: 4 * _glow.value,
                      ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji / Badge Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isEarned
                      ? colors.gold.withValues(alpha: 0.12)
                      : colors.border.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: isEarned ? context.shadows.goldGlow : null,
                  border: isEarned
                      ? Border.all(color: colors.gold.withValues(alpha: 0.2))
                      : null,
                ),
                child: Opacity(
                  opacity: isEarned ? 1.0 : 0.4,
                  child: Text(def.emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                def.titleAr,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.labelLarge.copyWith(
                  color: isEarned ? colors.gold : colors.textDim,
                  fontWeight: isEarned ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 6),

              // Points Reward (only if earned or descriptive)
              if (isEarned) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.achievementPointsRewardLabel(def.pointsReward),
                    style: typography.caption.copyWith(
                      color: colors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  intl.DateFormat('yyyy/MM/dd').format(achievement.earnedAt!),
                  style: typography.caption.copyWith(
                    fontSize: 10,
                    color: colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ] else ...[
                Text(
                  l10n.achievementPendingLabel,
                  style: typography.caption.copyWith(
                    color: colors.textDim.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
