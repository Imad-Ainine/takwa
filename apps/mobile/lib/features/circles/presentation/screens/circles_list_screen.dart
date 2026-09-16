import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/guest_mode_guard.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/takwa_error_state.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/features/circles/domain/circle_models.dart';
import 'package:takwa/features/circles/presentation/screens/circle_detail_screen.dart';
import 'package:takwa/features/circles/providers/circles_providers.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Entry screen for family/community accountability circles.
/// See docs/specs/family-community-features.md.
class CirclesListScreen extends ConsumerWidget {
  const CirclesListScreen({super.key});

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
            child: GuestModeGuard(
              child: Column(
                children: [
                  _buildAppBar(context, l10n),
                  Expanded(child: _buildBody(context, ref, l10n)),
                  _buildActions(context, ref, l10n),
                ],
              ),
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
              l10n.circlesAppBarTitle,
              style: context.typography.headingMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final circlesAsync = ref.watch(myCirclesProvider);

    return circlesAsync.when(
      loading: () => const Center(child: TakwaLoadingIndicator()),
      error: (_, _) => TakwaErrorState(
        onRetry: () => ref.invalidate(myCirclesProvider),
        message: l10n.circleErrorGeneric,
      ),
      data: (circles) {
        if (circles.isEmpty) {
          return _EmptyState(l10n: l10n);
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(myCirclesProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: circles.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) => _CircleCard(circle: circles[i]),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: l10n.circlesJoinButton,
              isOutline: true,
              onTap: () => _showJoinDialog(context, ref, l10n),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PrimaryButton(
              label: l10n.circlesCreateButton,
              onTap: () => _showCreateDialog(context, ref, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.circlesCreateDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.circlesCreateNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('—'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.circlesCreateConfirm),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      await ref.read(myCirclesProvider.notifier).create(name);
    } catch (_) {
      if (context.mounted) _showError(context, l10n);
    }
  }

  Future<void> _showJoinDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.circlesJoinDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: l10n.circlesJoinCodeLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('—'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.circlesJoinConfirm),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !context.mounted) return;
    try {
      await ref.read(myCirclesProvider.notifier).join(code);
    } catch (_) {
      if (context.mounted) _showError(context, l10n);
    }
  }

  void _showError(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.circleErrorGeneric)));
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👨‍👩‍👧‍👦', style: context.typography.displayLarge),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.circlesEmptyTitle,
              style: context.typography.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.circlesEmptyBody,
              style: context.typography.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  final CircleSummary circle;
  const _CircleCard({required this.circle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CircleDetailScreen(circle: circle),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(circle.name, style: context.typography.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      l10n.circlesMemberCount(circle.memberCount),
                      style: context.typography.caption,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
