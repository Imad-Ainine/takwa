import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/app/main_shell.dart' show currentTabProvider;
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/l10n/app_localizations.dart';

class GuestModeGuard extends ConsumerWidget {
  final Widget child;

  const GuestModeGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authStatus = ref.watch(authStatusProvider);

    if (authStatus == AuthStatus.authenticated) {
      return child;
    }

    return Stack(
      children: [
        // The actual screen content blur/darkened. ExcludeSemantics matters as
        // much as AbsorbPointer: without it a screen reader still walks the
        // locked screen behind the overlay.
        ExcludeSemantics(
          child: Opacity(opacity: 0.3, child: AbsorbPointer(child: child)),
        ),

        // Restricted access overlay
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.colors.card.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.colors.gold.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with pulse effect decoration
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.gold.withValues(alpha: 0.1),
                      border: Border.all(
                        color: context.colors.gold.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      color: context.colors.gold,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.guestGuardTitle,
                    style: context.typography.headingLarge.copyWith(
                      color: context.colors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.guestGuardMessage,
                    textAlign: TextAlign.center,
                    style: context.typography.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  PrimaryButton(
                    label: l10n.guestGuardSignInButton,
                    icon: Icons.login_rounded,
                    onTap: () async {
                      ref.read(guestModeProvider.notifier).state = false;
                      Navigator.pushNamed(context, Routes.auth);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () {
                      // Was Navigator.pop(context): this guard only ever
                      // wraps a MainShell tab (Checklist, Statistics), not a
                      // pushed route, so pop() popped the shell itself off
                      // the navigator instead of taking the user anywhere
                      // sensible. Switching to Home is always available,
                      // guest or not.
                      ref.read(currentTabProvider.notifier).state = 0;
                    },
                    child: Text(
                      l10n.guestGuardBackButton,
                      style: context.typography.labelLarge.copyWith(
                        color: context.colors.textDim,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
