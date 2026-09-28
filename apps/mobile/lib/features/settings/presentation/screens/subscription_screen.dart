import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:takwa/core/payments/entitlement_providers.dart';
import 'package:takwa/core/payments/freemius_service.dart';
import 'package:takwa/core/payments/premium_entitlement.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/utils/app_logger.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        _buildHeader(context),
                        const SizedBox(height: 40),
                        _buildStatusCard(context, ref),
                        _buildContent(context),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          CustomLeadingButton(onPressed: () => Navigator.pop(context)),
          const Spacer(),
        ],
      ),
    );
  }

  /// Server-side Freemius entitlement for the signed-in user; hidden
  /// entirely when there is nothing to report (guests, honor-system-only
  /// supporters), so the screen reads exactly like before for them.
  Widget _buildStatusCard(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(premiumEntitlementProvider).valueOrNull;
    if (entitlement == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final display = entitlement.display;
    final end = entitlement.currentPeriodEnd;
    final endText = end == null
        ? ''
        : DateFormat.yMMMEd(l10n.localeName).format(end);

    final (title, subtitle, color, icon) = switch (display) {
      PremiumDisplay.active => (
        l10n.subscriptionStatusActive,
        end == null ? '' : l10n.subscriptionStatusRenews(endText),
        context.colors.successText,
        Icons.verified_rounded,
      ),
      PremiumDisplay.trial => (
        l10n.subscriptionStatusActive,
        end == null ? '' : l10n.subscriptionStatusTrialUntil(endText),
        context.colors.gold,
        Icons.bolt_rounded,
      ),
      PremiumDisplay.pastDue => (
        l10n.subscriptionStatusPastDue,
        '',
        context.colors.dangerText,
        Icons.error_outline_rounded,
      ),
      PremiumDisplay.canceling => (
        l10n.subscriptionStatusCancelingUntil(endText),
        '',
        context.colors.gold,
        Icons.hourglass_bottom_rounded,
      ),
      PremiumDisplay.refunded => (
        l10n.subscriptionStatusRefunded,
        '',
        context.colors.textSecondary,
        Icons.undo_rounded,
      ),
      _ => (
        l10n.subscriptionStatusExpired,
        '',
        context.colors.textSecondary,
        Icons.lock_outline_rounded,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.typography.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: context.typography.caption.copyWith(
                  color: context.colors.textDim,
                ),
              ),
            ],
            if (entitlement.source == 'freemius') ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: l10n.subscriptionManageButton,
                icon: Icons.settings_rounded,
                isOutline: true,
                onTap: () => _openPortal(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Cancel / resume / card updates happen in the Freemius customer portal,
  /// which the proxy builds server-side — the app never sees Freemius keys.
  Future<void> _openPortal(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final token =
          SupabaseConfig.client.auth.currentSession?.accessToken ?? '';
      final portal = await FreemiusService().portal(accessToken: token);
      final opened = await launchUrl(
        portal.url,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.subscriptionPortalError)),
        );
      }
    } catch (e, st) {
      AppLogger.warning('Freemius portal open failed', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.subscriptionPortalError)),
        );
      }
    }
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.subscriptionScreenTitle,
          style: context.typography.displayMedium.copyWith(
            color: context.colors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            color: context.colors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.subscriptionIntroText,
          textAlign: TextAlign.center,
          style: context.typography.headingMedium.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          l10n.subscriptionFreeAccessNote,
          textAlign: TextAlign.center,
          style: context.typography.bodyLarge.copyWith(
            color: context.colors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          l10n.subscriptionHonorSystemNote,
          textAlign: TextAlign.center,
          style: context.typography.bodyMedium.copyWith(
            color: context.colors.textDim,
            height: 1.6,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          PrimaryButton(
            label: l10n.subscriptionPayMonthlyButton,
            onTap: () => Navigator.pushNamed(context, Routes.paymentMethods),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.subscriptionUseFreeButton,
            isOutline: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
