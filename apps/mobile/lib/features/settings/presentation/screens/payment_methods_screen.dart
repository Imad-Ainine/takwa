import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/payments/payment_config.dart';
import 'package:takwa/core/payments/payment_router.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/settings/presentation/screens/chargily_payment_screen.dart';
import 'package:takwa/features/settings/presentation/screens/freemius_payment_screen.dart';
import 'package:takwa/l10n/app_localizations.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  /// 0: Edahabia/CIB (Chargily), 1: Visa/Mastercard (Freemius). Defaults to
  /// the country-detected rail; a manual tap always wins over the default.
  int _selectedMethod = 0;
  String? _regionOverride; // null/'' = auto, 'dz', 'intl'

  @override
  void initState() {
    super.initState();
    _loadRegionPreference();
  }

  Future<void> _loadRegionPreference() async {
    final raw = await ref
        .read(settingsDaoProvider)
        .get(PaymentRouting.settingsOverrideKey);
    if (!mounted) return;
    setState(() {
      _regionOverride = (raw == null || raw.isEmpty) ? null : raw;
      _selectedMethod =
          _suggestedRail() == PaymentRail.chargily ? 0 : 1;
    });
  }

  PaymentRail _suggestedRail() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return PaymentRouting.suggest(
      countryCode: locale.countryCode,
      languageCode: locale.languageCode,
      overrideValue: _regionOverride,
    );
  }

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
                        const SizedBox(height: AppSpacing.lg),
                        _buildRegionRow(context),
                        const SizedBox(height: AppSpacing.xl),
                        _buildMethodCard(
                          index: 0,
                          title: l10n.paymentMethodEdahabiaTitle,
                          subtitle: '200.00 DZD',
                          recommended: _suggestedRail() == PaymentRail.chargily,
                          icon: Image.asset(
                            'assets/images/edahabia.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.credit_card, size: 24),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildMethodCard(
                          index: 1,
                          title: l10n.paymentMethodVisaTitle,
                          subtitle: FreemiusConfig.monthlyDisplay,
                          recommended: _suggestedRail() == PaymentRail.freemius,
                          icon: Image.asset(
                            'assets/images/visa_mastercard.webp',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.credit_card, size: 24),
                          ),
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
  required Widget icon, // <-- was: required String icon (fed to IslamicGlyph)
  bool recommended = false,
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
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
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
                    if (recommended) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.paymentRecommendedBadge,
                          style: context.typography.caption.copyWith(
                            color: context.colors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(10), // breathing room for logos
            decoration: BoxDecoration(
              // Card logos (Visa/Mastercard/Edahabia) are usually designed
              // for white backgrounds — keep this white regardless of theme
              // so they don't look muddy in dark mode.
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 4),
              child: icon,
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

  String _detectedRegionLabel(AppLocalizations l10n) {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return (locale.countryCode ?? '').toUpperCase() == 'DZ'
        ? l10n.paymentRegionDetectedDz
        : l10n.paymentRegionDetectedIntl;
  }

  Widget _buildRegionRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detected = _detectedRegionLabel(l10n);
    final String current = switch (_regionOverride) {
      'dz' => l10n.paymentRegionAlgeria,
      'intl' => l10n.paymentRegionInternational,
      _ => l10n.paymentRegionAuto(detected),
    };
    return TakwaTappable(
      onTap: _pickRegion,
      semanticLabel: '${l10n.paymentRegionLabel}: $current',
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.public_rounded,
              size: 18,
              color: context.colors.textDim,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.paymentRegionLabel,
              style: context.typography.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              current,
              style: context.typography.bodyMedium.copyWith(
                color: context.colors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: context.colors.gold,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRegion() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.paymentRegionLabel,
                style: context.typography.labelLarge.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final (value, label) in [
              ('', l10n.paymentRegionAuto(_detectedRegionLabel(l10n))),
              ('dz', l10n.paymentRegionAlgeria),
              ('intl', l10n.paymentRegionInternational),
            ])
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                title: Text(label),
                trailing: (_regionOverride ?? '') == value
                    ? Icon(Icons.check_rounded, color: context.colors.gold)
                    : null,
                onTap: () => Navigator.pop(sheetContext, value),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    await ref
        .read(settingsDaoProvider)
        .set(PaymentRouting.settingsOverrideKey, choice);
    if (!mounted) return;
    setState(() {
      _regionOverride = choice.isEmpty ? null : choice;
      _selectedMethod = _suggestedRail() == PaymentRail.chargily ? 0 : 1;
    });
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
        onTap: _continue,
      ),
    );
  }

  void _continue() {
    if (_selectedMethod == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FreemiusPaymentScreen(),
        ),
      );
      return;
    }
    _pickChargilyCard();
  }

  /// Edahabia and CIB both go through the same Chargily hosted checkout;
  /// the choice only preselects the card network on the payment page.
  Future<void> _pickChargilyCard() async {
    final l10n = AppLocalizations.of(context)!;
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.paymentChooseCardSheetTitle,
                style: context.typography.labelLarge.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              leading: Icon(
                Icons.credit_card_rounded,
                color: context.colors.gold,
              ),
              title: Text(l10n.paymentMethodEdahabiaOnly),
              onTap: () => Navigator.pop(sheetContext, 'edahabia'),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              leading: Icon(
                Icons.account_balance_rounded,
                color: context.colors.gold,
              ),
              title: Text(l10n.paymentChargilyCibTitle),
              onTap: () => Navigator.pop(sheetContext, 'cib'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (method == null) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChargilyPaymentScreen(paymentMethod: method),
      ),
    );
  }
}
