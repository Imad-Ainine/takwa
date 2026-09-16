import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/achievements/domain/models/achievement_definition.dart';
import 'package:takwa/features/achievements/presentation/widgets/achievement_card.dart';
import 'package:takwa/features/achievements/providers/achievements_providers.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/app/animated_drawer.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/l10n/app_localizations.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;
  static const _sectionCount = 5; // Header + 4 categories

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnims = List.generate(_sectionCount, (i) {
      final s = i * 0.12, e = (s + 0.40).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_sectionCount, (i) {
      final s = i * 0.12, e = (s + 0.40).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );
    });

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fadeAnims[i.clamp(0, _sectionCount - 1)],
    child: SlideTransition(
      position: _slideAnims[i.clamp(0, _sectionCount - 1)],
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final achievementsAsync = ref.watch(achievementsProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),

              achievementsAsync.when(
                data: (list) => _buildContent(context, list),
                loading: () => const SliverFillRemaining(
                  child: Center(child: TakwaLoadingIndicator()),
                ),
                error: (e, s) => SliverFillRemaining(
                  child: Center(child: Text(l10n.checklistErrorPrefix('$e'))),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final earnedCount = ref.watch(earnedAchievementsCountProvider);
    final totalCount = AchievementDefinition.all.length;
    final progress = totalCount > 0 ? earnedCount / totalCount : 0.0;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: const DrawerMenuButton(),
      title: Text(
        l10n.achievementsScreenTitle,
        style: context.typography.headingLarge.copyWith(
          color: colors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.gold.withValues(alpha: 0.15),
                colors.background.withValues(alpha: 0),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _anim(
                0,
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.xl,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: colors.cardGradient,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.gold.withValues(alpha: 0.2),
                    ),
                    boxShadow: context.shadows.card,
                  ),
                  child: Row(
                    children: [
                      // Level Icon
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: colors.goldGradient,
                          shape: BoxShape.circle,
                          boxShadow: context.shadows.goldGlow,
                        ),
                        child: const Icon(
                          Icons.military_tech,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      // Progress Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.achievementsProgressLabel,
                                  style: context.typography.labelLarge.copyWith(
                                    color: colors.gold,
                                  ),
                                ),
                                Text(
                                  '$earnedCount / $totalCount',
                                  style: context.typography.labelLarge.copyWith(
                                    color: colors.gold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  Container(height: 8, color: colors.border),
                                  FractionallySizedBox(
                                    widthFactor: progress,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: colors.goldGradient,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<AchievementView> list) {
    final l10n = AppLocalizations.of(context)!;
    const categories = AchievementCategory.values;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final cat = categories[index];
        final catItems = list
            .where((a) => a.definition.category == cat)
            .toList();
        if (catItems.isEmpty) return const SizedBox.shrink();

        return _anim(
          index + 1,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: context.colors.goldGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _getCategoryTitle(l10n, cat),
                      style: context.typography.headingMedium.copyWith(
                        fontSize: 18,
                        color: context.colors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: catItems.length,
                itemBuilder: (context, i) {
                  return AchievementCard(
                    achievement: catItems[i],
                    onTap: () => _showAchievementDetails(context, catItems[i]),
                  );
                },
              ),
            ],
          ),
        );
      }, childCount: categories.length),
    );
  }

  String _getCategoryTitle(AppLocalizations l10n, AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.daily:
        return l10n.achievementsCategoryDaily;
      case AchievementCategory.milestone:
        return l10n.achievementsCategoryMilestone;
      case AchievementCategory.ibadah:
        return l10n.achievementsCategoryIbadah;
      case AchievementCategory.special:
        return l10n.achievementsCategorySpecial;
    }
  }

  void _showAchievementDetails(BuildContext context, AchievementView a) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final def = a.definition;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(
              color: colors.gold.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: colors.goldDim,
                shape: BoxShape.circle,
                boxShadow: context.shadows.goldGlow,
              ),
              child: Text(def.emoji, style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              def.titleAr,
              textAlign: TextAlign.center,
              style: context.typography.headingLarge.copyWith(
                color: colors.gold,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              def.descAr,
              textAlign: TextAlign.center,
              style: context.typography.bodyLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            if (a.isEarned) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: colors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: colors.success),
                    const SizedBox(width: 10),
                    Text(
                      l10n.achievementsAchievedOnLabel(_formatDate(a.earnedAt)),
                      style: context.typography.labelMedium.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: colors.gold.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: colors.gold.withValues(alpha: 0.2)),
                ),
                child: Text(
                  l10n.achievementsEncourageMessage,
                  textAlign: TextAlign.center,
                  style: context.typography.labelMedium.copyWith(
                    color: colors.gold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: l10n.achievementsGotItButton,
              onTap: () async => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}/${date.month}/${date.day}';
  }
}
