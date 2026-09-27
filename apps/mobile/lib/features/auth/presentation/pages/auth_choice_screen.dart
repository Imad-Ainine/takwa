import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/features/auth/presentation/widgets/auth_scaffold.dart';
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

    return AuthScaffold(
      children: [
        Hero(
          tag: 'app_logo',
          child: Center(child: AuthEmblem.moon(size: 110)),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AuthGoldTitle(l10n.authChoiceAppName, fontSize: 48),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.authChoiceTagline,
          textAlign: TextAlign.center,
          style: typography.bodyLarge.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.huge),
        PrimaryButton(
          label: l10n.authChoiceSignInButton,
          icon: Icons.login_rounded,
          onTap: () async => Navigator.pushNamed(context, Routes.auth),
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
        const SizedBox(height: AppSpacing.xxl),
        Text(
          l10n.authChoiceSyncNote,
          textAlign: TextAlign.center,
          style: typography.caption.copyWith(color: colors.textDim),
        ),
      ],
    );
  }
}
