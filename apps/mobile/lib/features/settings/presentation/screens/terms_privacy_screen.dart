import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/l10n/app_localizations.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSectionTitle(
                        context,
                        l10n.termsPrivacyTermsSectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildTermsContent(context),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSectionTitle(
                        context,
                        l10n.termsPrivacyPolicySectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildPrivacyContent(context),
                      const SizedBox(height: 40),
                      _buildFooter(context),
                      const SizedBox(height: AppSpacing.lg),
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
      title: l10n.termsPrivacyScreenTitle,
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: context.decorations.goldCard.copyWith(
        color: context.colors.card.withValues(alpha: 0.85),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.gold.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.gavel_rounded,
              color: context.colors.gold,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.termsPrivacyAppName,
            style: context.typography.headingLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          Text(
            l10n.termsPrivacySubtitle,
            style: context.typography.labelMedium.copyWith(
              fontSize: 14,
              color: context.colors.goldLight,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.typography.headingMedium.copyWith(
        color: context.colors.teal,
      ),
    );
  }

  Widget _buildTermsContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: context.decorations.card.copyWith(
        color: context.colors.card.withValues(alpha: 0.85),
      ),
      child: Text(
        l10n.termsPrivacyTermsBody,
        style: context.typography.bodyMedium.copyWith(height: 1.8),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildPrivacyContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: context.decorations.card.copyWith(
        color: context.colors.card.withValues(alpha: 0.85),
      ),
      child: Text(
        l10n.termsPrivacyPolicyBody,
        style: context.typography.bodyMedium.copyWith(height: 1.8),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        children: [
          Container(height: 1, width: 80, color: context.colors.border),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.termsPrivacyFooterThanks,
            style: context.typography.headingMedium.copyWith(
              color: context.colors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.termsPrivacyFooterDua,
            style: context.typography.caption.copyWith(
              color: context.colors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
