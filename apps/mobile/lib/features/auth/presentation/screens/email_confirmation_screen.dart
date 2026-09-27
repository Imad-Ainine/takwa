import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:takwa/l10n/app_localizations.dart';

class EmailConfirmationScreen extends StatelessWidget {
  final String email;

  const EmailConfirmationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;

    return AuthScaffold(
      showBack: true,
      children: [
        AuthGlassCard(
          child: Column(
            children: [
              Center(
                child: AuthEmblem.icon(
                  size: 96,
                  icon: Icons.mark_email_read_outlined,
                ),
              ),              const SizedBox(height: AppSpacing.xxl),
              Text(
                l10n.emailConfirmationTitle,
                style: typography.displayLarge.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // The address, on a chip — the one detail worth isolating.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.goldDim.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: colors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  email,
                  style: typography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.goldText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.emailConfirmationInstructions,
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 14,
                    color: colors.textDim,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.emailConfirmationSpamHint,
                      style: typography.caption.copyWith(
                        color: colors.textDim,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.huge),
              PrimaryButton(
                onTap: () => Navigator.pushReplacementNamed(context, '/auth'),
                label: l10n.emailConfirmationBackToSignInButton,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
