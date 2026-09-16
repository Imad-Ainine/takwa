import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/l10n/app_localizations.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  int _selectedMethod = 0; // 0: Edahabia/CIB, 1: Visa/Mastercard

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // AppBarWidget instead of a one-off Row(CustomLeadingButton + title)
      // (audit item 29) — consistent with the rest of the app's app bars.
      appBar: AppBarWidget(
        title: l10n.paymentMethodsScreenTitle,
        leading: CustomLeadingButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildSupportMessage(context),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildMethodCard(
                          index: 0,
                          title: l10n.paymentMethodEdahabiaTitle,
                          subtitle: '100.00 DZD',
                          icon: '💳',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildMethodCard(
                          index: 1,
                          title: l10n.paymentMethodVisaTitle,
                          subtitle: '€10.00',
                          icon: '🌍',
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required int index,
    required String title,
    required String subtitle,
    required String icon,
  }) {
    final isSelected = _selectedMethod == index;
    return TakwaTappable(
      onTap: () => setState(() => _selectedMethod = index),
      semanticLabel: '$title. $subtitle',
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.gold.withValues(alpha: 0.08)
              : context.colors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected ? context.colors.gold : context.colors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.colors.gold.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _buildRadioIndicator(isSelected),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.typography.labelLarge.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: context.typography.caption.copyWith(
                      color: isSelected
                          ? context.colors.gold
                          : context.colors.textDim,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: context.colors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: context.colors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.gold.withValues(alpha: 0.12),
            context.colors.gold.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.gold.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.colors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: context.colors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.paymentSupportTitle,
                style: context.typography.labelLarge.copyWith(
                  color: context.colors.gold,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.paymentSupportMessage,
            style: context.typography.bodyMedium.copyWith(
              color: context.colors.textPrimary.withValues(alpha: 0.9),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioIndicator(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? context.colors.gold : context.colors.textDim,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.gold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: PrimaryButton(
        label: l10n.paymentContinueButton,
        onTap: () {
          // Implementation for actual payment would go here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.paymentComingSoonMessage)),
          );
        },
      ),
    );
  }
}
