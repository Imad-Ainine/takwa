import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_pattern_background.dart';
import '../../../../core/widgets/custom_leading_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

class QiyamBeginnerGuideScreen extends StatelessWidget {
  const QiyamBeginnerGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off Row(CustomLeadingButton + title)
      // (audit item 29) — consistent with the rest of the app's app bars.
      appBar: AppBarWidget(
        title: l10n.qiyamDashboardBeginnerGuideTool,
        leading: const CustomLeadingButton(),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                      _buildIntroHeader(context, l10n),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildTipSection(
                        context,
                        title: l10n.qiyamGuideTip1Title,
                        content: l10n.qiyamGuideTip1Content,
                        icon: Icons.lightbulb_outline,
                      ),
                      _buildTipSection(
                        context,
                        title: l10n.qiyamGuideTip2Title,
                        content: l10n.qiyamGuideTip2Content,
                        icon: Icons.bedtime_outlined,
                      ),
                      _buildTipSection(
                        context,
                        title: l10n.qiyamGuideTip3Title,
                        content: l10n.qiyamGuideTip3Content,
                        icon: Icons.water_drop_outlined,
                      ),
                      _buildTipSection(
                        context,
                        title: l10n.qiyamGuideTip4Title,
                        content: l10n.qiyamGuideTip4Content,
                        icon: Icons.repeat,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildQASection(context),
                      const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Icon(Icons.rocket_launch, size: 60, color: context.colors.gold),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.qiyamGuideIntroTitle,
          style: context.typography.displayMedium.copyWith(
            fontSize: 24,
            color: context.colors.gold,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.qiyamGuideIntroSubtitle,
          style: context.typography.bodyLarge.copyWith(
            color: context.colors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTipSection(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colors.gold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: context.colors.gold),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.typography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          content,
                          style: context.typography.caption.copyWith(
                            color: context.colors.textDim,
                            fontSize: 14,
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
    );
  }

  Widget _buildQASection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questions = [
      {'q': l10n.qiyamGuideFaqQ1, 'a': l10n.qiyamGuideFaqA1},
      {'q': l10n.qiyamGuideFaqQ2, 'a': l10n.qiyamGuideFaqA2},
      {'q': l10n.qiyamGuideFaqQ3, 'a': l10n.qiyamGuideFaqA3},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.qiyamGuideFaqTitle,
          style: context.typography.displayMedium.copyWith(
            fontSize: 20,
            color: context.colors.gold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...questions.map(
          (qa) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.gold.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.colors.gold.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qa['q']!,
                  style: context.typography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.gold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  qa['a']!,
                  style: context.typography.bodyLarge.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
