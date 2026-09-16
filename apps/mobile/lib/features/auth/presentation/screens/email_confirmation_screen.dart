import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

class EmailConfirmationScreen extends StatelessWidget {
  final String email;

  const EmailConfirmationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.goldDim,
                      border: Border.all(color: context.colors.gold, width: 2),
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 50,
                      color: context.colors.gold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    l10n.emailConfirmationTitle,
                    style: context.typography.headingLarge.copyWith(
                      color: context.colors.gold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.emailConfirmationLinkSentLabel(email),
                    style: context.typography.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.emailConfirmationInstructions,
                    style: context.typography.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  PrimaryButton(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/auth'),
                    label: l10n.emailConfirmationBackToSignInButton,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
