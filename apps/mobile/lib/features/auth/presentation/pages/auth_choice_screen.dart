import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

class AuthChoiceScreen extends ConsumerWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(
              pattern: BackgroundPattern.adhkar,
              opacity: 0.1,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo & Name
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.gold.withValues(alpha: 0.1),
                      border: Border.all(
                        color: context.colors.gold.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.gold.withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Text('🌙', style: TextStyle(fontSize: 60)),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [style.gold, style.gold],
                    ).createShader(bounds),
                    child: Text(
                      l10n.authChoiceAppName,
                      style: style
                          .amiri(48, weight: FontWeight.w800)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.authChoiceTagline,
                    textAlign: TextAlign.center,
                    style: context.typography.bodyLarge.copyWith(
                      color: context.colors.textSecondary,
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

                  const SizedBox(height: 40),

                  Text(
                    l10n.authChoiceSyncNote,
                    textAlign: TextAlign.center,
                    style: context.typography.caption.copyWith(
                      color: context.colors.textDim,
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
