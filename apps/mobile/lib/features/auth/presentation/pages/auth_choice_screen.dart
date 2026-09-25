import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ══════════════════════════════════════════════════════
//  AUTH CHOICE SCREEN – Refined Islamic
// ══════════════════════════════════════════════════════
class AuthChoiceScreen extends ConsumerWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      body: Stack(
        children: [
          // Soft geometric Islamic pattern
          const Positioned.fill(
            child: CustomPatternBackground(
              pattern: BackgroundPattern.adhkar,
              opacity: 0.09,
            ),
          ),

          // Soft gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.background.withValues(alpha: 0.1),
                    colors.background.withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo & Name – refined gold ring
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.gold.withValues(alpha: 0.16),
                          colors.gold.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                        color: colors.gold.withValues(alpha: 0.38),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.gold.withValues(alpha: 0.18),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Text('🌙', style: TextStyle(fontSize: 62)),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        colors.goldGradient.createShader(bounds),
                    child: Text(
                      l10n.authChoiceAppName,
                      style: typography.displayLarge.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.authChoiceTagline,
                    textAlign: TextAlign.center,
                    style: typography.bodyLarge.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Actions
                  Column(
                    children: [
                      PrimaryButton(
                        label: l10n.authChoiceSignInButton,
                        icon: Icons.login_rounded,
                        onTap: () async =>
                            Navigator.pushNamed(context, Routes.auth),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: l10n.authChoiceGuestButton,
                        icon: Icons.person_outline_rounded,
                        isOutline: true,
                        onTap: () async {
                          // تفعيل وضع الضيف
                          ref.read(guestModeProvider.notifier).state = true;
                          Navigator.pushReplacementNamed(context, Routes.home);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.huge),

                  Text(
                    l10n.authChoiceSyncNote,
                    textAlign: TextAlign.center,
                    style: typography.caption.copyWith(
                      color: colors.textDim,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}