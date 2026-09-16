import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_pattern_background.dart';
import '../../../../core/widgets/custom_leading_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

class QiyamSunnahGuideScreen extends StatelessWidget {
  const QiyamSunnahGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off Row(CustomLeadingButton + title)
      // (audit item 29) — consistent with the rest of the app's app bars.
      appBar: AppBarWidget(
        title: l10n.qiyamSunnahGuideTitle,
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
                      _buildGuideHeader(context),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildStepCard(
                        context,
                        number: '1',
                        title: l10n.qiyamSunnahStep1Title,
                        content: l10n.qiyamSunnahStep1Content,
                      ),
                      _buildStepCard(
                        context,
                        number: '2',
                        title: l10n.qiyamSunnahStep2Title,
                        content: l10n.qiyamSunnahStep2Content,
                      ),
                      _buildStepCard(
                        context,
                        number: '3',
                        title: l10n.qiyamSunnahStep3Title,
                        content: l10n.qiyamSunnahStep3Content,
                      ),
                      _buildStepCard(
                        context,
                        number: '4',
                        title: l10n.qiyamSunnahStep4Title,
                        content: l10n.qiyamSunnahStep4Content,
                      ),
                      _buildStepCard(
                        context,
                        number: '5',
                        title: l10n.qiyamSunnahStep5Title,
                        content: l10n.qiyamSunnahStep5Content,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildQuoteSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: context.colors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 40),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.qiyamSunnahGuideHeaderTitle,
            style: context.typography.displayMedium.copyWith(
              fontSize: 20,
              color: context.colors.gold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.qiyamSunnahGuideHeaderSubtitle,
            style: context.typography.bodyLarge.copyWith(
              color: context.colors.textPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String number,
    required String title,
    required String content,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.colors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                            color: context.colors.gold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          content,
                          style: context.typography.bodyLarge.copyWith(
                            color: context.colors.textSecondary,
                            height: 1.6,
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

  Widget _buildQuoteSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.teal.withValues(alpha: 0.2)),
      ),
      child: Text(
        'عن عائشة رضي الله عنها قالت: "كان النبي ﷺ يصلي من الليل إحدى عشرة ركعة، يوتر منها بواحدة".',
        style: context.typography.bodyLarge.copyWith(
          color: context.colors.textSecondary,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
