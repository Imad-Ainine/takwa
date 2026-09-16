import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_leading_button.dart';
import '../../../../core/widgets/custom_pattern_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/takwa_error_state.dart';
import '../../../../core/widgets/takwa_loading_indicator.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/database/daos.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/supabase/supabase_config.dart';
import 'package:takwa/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(monthStatsProvider);
    final streakAsync = ref.watch(currentStreakProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29).
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // Background Pattern
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Profile Header Card
                      _buildProfileHeader(context, ref, profileAsync),
                      const SizedBox(height: AppSpacing.xxl),

                      // Stats Row
                      _buildStatsGrid(context, ref, statsAsync, streakAsync),
                      const SizedBox(height: AppSpacing.xxl),

                      // Quick Actions / Menu
                      _buildProfileMenu(context),

                      const SizedBox(height: 40),

                      // Logout Button
                      _buildLogoutButton(context, ref),

                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
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
      title: l10n.profileScreenTitle,
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>?> profileAsync,
  ) {
    return profileAsync.when(
      loading: () => const Center(child: TakwaLoadingIndicator()),
      error: (e, _) => TakwaErrorState(
        onRetry: () => ref.invalidate(userProfileProvider),
      ),
      data: (profile) {
        final l10n = AppLocalizations.of(context)!;
        final username = profile?['username'] ?? l10n.profileDefaultUsername;
        final avatar = profile?['avatar_emoji'] ?? '🌙';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: context.decorations.goldCard.copyWith(
            color: context.colors.card.withValues(alpha: 0.8),
          ),
          child: Column(
            children: [
              // Avatar with glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.goldDim,
                  border: Border.all(
                    color: context.colors.gold.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.gold.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(avatar, style: const TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                username,
                style: context.typography.headingLarge.copyWith(
                  fontSize: 24,
                  color: context.colors.gold,
                ),
              ),
              if (profile?['gender'] != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(
                      color: context.colors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    profile!['gender'] == 'male'
                        ? l10n.profileGenderMale
                        : l10n.profileGenderFemale,
                    style: context.typography.caption.copyWith(
                      color: context.colors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                profile?['email'] ?? '',
                style: context.typography.caption.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TaqwaBadge(label: l10n.profileMemberBadge),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<MonthStats> statsAsync,
    AsyncValue<int> streakAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: statsAsync.when(
            data: (s) => _StatCard(
              label: l10n.profileTaqwaPointsLabel,
              value: '${s.totalPoints}',
              icon: '🌟',
              color: context.colors.gold,
            ),
            loading: () => const SizedBox(height: 100),
            error: (_, _) => TakwaInlineError(
              height: 100,
              onRetry: () => ref.invalidate(monthStatsProvider),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: streakAsync.when(
            data: (s) => _StatCard(
              label: l10n.profileStreakDaysLabel,
              value: '$s',
              icon: '🔥',
              color: context.colors.success,
            ),
            loading: () => const SizedBox(height: 100),
            error: (_, _) => TakwaInlineError(
              height: 100,
              onRetry: () => ref.invalidate(currentStreakProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _MenuTile(
          icon: Icons.emoji_events_outlined,
          title: l10n.profileAchievementsMenuTitle,
          onTap: () => Navigator.pushNamed(context, '/achievements'),
        ),
        _MenuTile(
          icon: Icons.history_rounded,
          title: l10n.profileAccountingLogMenuTitle,
          onTap: () => Navigator.pushNamed(context, '/checklist'),
        ),
        _MenuTile(
          icon: Icons.settings_outlined,
          title: l10n.profileAccountSettingsMenuTitle,
          onTap: () => Navigator.pushNamed(context, '/account-settings'),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final supabaseService = ref.read(supabaseServiceProvider);
    return PrimaryButton(
      onTap: () async {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.profileLogoutDialogTitle),
            content: Text(l10n.profileLogoutDialogConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.adhkarCancelButton),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.profileLogoutConfirmButton),
              ),
            ],
          ),
        );

        if (proceed == true) {
          await supabaseService.signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        }
      },
      icon: Icons.logout_rounded,
      label: l10n.profileLogoutDialogTitle,
      isOutline: true,
      baseColor: Colors.redAccent,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: context.decorations.card.copyWith(
        color: context.colors.card.withValues(alpha: 0.9),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: context.typography.taqwaScore.copyWith(
              color: color,
              fontSize: 22,
            ),
          ),
          Text(
            label,
            style: context.typography.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: context.decorations.card.copyWith(
        color: context.colors.card.withValues(alpha: 0.6),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ListTile(
          onTap: onTap,
          dense: true,
          leading: Icon(icon, color: context.colors.gold, size: 22),
          title: Text(title, style: context.typography.labelLarge),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: context.colors.textDim,
          ),
        ),
      ),
    );
  }
}
