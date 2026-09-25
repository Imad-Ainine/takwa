import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/payments/payment_config.dart';
import 'package:takwa/core/payments/subscription_store.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Visa / Mastercard support via a direct transfer to the developer's Wise
/// account. The app never touches card data: it shows the public recipient
/// details, optionally deep-links into the Wise app, and records the
/// user-declared transfer in [SubscriptionStore] (reconciled manually
/// against the account statement — the honest honor-system model).
///
/// Recipient details come from the `WISE_*` keys in `.env` (see
/// [WiseConfig]). Until they are filled, the screen shows a "not configured
/// yet" notice instead of an empty/broken flow.
class WisePaymentScreen extends ConsumerStatefulWidget {
  const WisePaymentScreen({super.key});

  @override
  ConsumerState<WisePaymentScreen> createState() => _WisePaymentScreenState();
}

enum _WiseStage { instructions, sent }

class _WisePaymentScreenState extends ConsumerState<WisePaymentScreen> {
  _WiseStage _stage = _WiseStage.instructions;

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.wiseCopiedMessage(label),
        ),
      ),
    );
  }

  Future<void> _openWise() async {
    final url = Uri.parse(
      WiseConfig.profileLink.isNotEmpty
          ? WiseConfig.profileLink
          : 'https://app.wise.com',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing else to do: the recipient details are on screen anyway.
    }
  }

  Future<void> _markSent() async {
    await ref.read(subscriptionStoreProvider).recordPayment(
      SupportPayment(
        channel: SupportChannel.wise,
        status: 'user_declared',
        amountMinor: (WiseConfig.monthlyEur * 100).round(),
        currency: 'eur',
        at: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() => _stage = _WiseStage.sent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarWidget(
        title: l10n.wiseScreenTitle,
        leading: CustomLeadingButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: _stage == _WiseStage.sent
                  ? _buildThanks(context, l10n)
                  : _buildInstructions(context, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThanks(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.successDim,
              border: Border.all(color: context.colors.gold, width: 2),
              boxShadow: AppShadows.goldGlow,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 46,
              color: context.colors.successText,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          l10n.wiseThanksTitle,
          textAlign: TextAlign.center,
          style: context.typography.headingLarge.copyWith(
            color: context.colors.successText,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.wiseThanksSubtitle,
          textAlign: TextAlign.center,
          style: context.typography.bodyMedium.copyWith(
            color: context.colors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        PrimaryButton(
          label: l10n.paymentDoneButton,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context, AppLocalizations l10n) {
    if (!WiseConfig.isConfigured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Icon(
            Icons.info_outline_rounded,
            size: 46,
            color: context.colors.gold,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.paymentComingSoonMessage,
            textAlign: TextAlign.center,
            style: context.typography.bodyMedium.copyWith(
              color: context.colors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: l10n.paymentDoneButton,
            isOutline: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      );
    }

    final eur = WiseConfig.monthlyEur;
    final amount = '${eur.toStringAsFixed(2)} EUR';
    final details = <(String, String)>[
      if (WiseConfig.holderName.isNotEmpty)
        (l10n.wiseHolderLabel, WiseConfig.holderName),
      if (WiseConfig.iban.isNotEmpty)
        (l10n.wiseIbanLabel, WiseConfig.iban),
      if (WiseConfig.accountNumber.isNotEmpty)
        (l10n.wiseAccountLabel, WiseConfig.accountNumber),
      if (WiseConfig.sortCode.isNotEmpty)
        (l10n.wiseSortCodeLabel, WiseConfig.sortCode),
      if (WiseConfig.bankName.isNotEmpty)
        (l10n.wiseBankLabel, WiseConfig.bankName),
      (l10n.wiseAmountLabel, amount),
      (l10n.wiseReferenceLabel, WiseConfig.paymentReference),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.wiseIntroMessage,
          style: context.typography.bodyMedium.copyWith(
            color: context.colors.textPrimary.withValues(alpha: 0.9),
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            children: [
              for (final (label, value) in details)
                _DetailRow(
                  label: label,
                  value: value,
                  onCopy: () => _copy(label, value),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: l10n.wiseOpenButton,
          icon: Icons.open_in_new_rounded,
          onTap: _openWise,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.wiseSentButton,
          icon: Icons.done_rounded,
          isOutline: true,
          onTap: _markSent,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.typography.caption.copyWith(
                    color: context.colors.textDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.typography.bodyMedium.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: Icon(
              Icons.copy_rounded,
              size: 20,
              color: context.colors.gold,
            ),
            tooltip: label,
          ),
        ],
      ),
    );
  }
}
