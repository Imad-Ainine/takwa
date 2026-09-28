import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:takwa/core/theme/app_theme.dart';

/// Short success moment shown after sign-in before the app reveals itself.
/// With [confetti] the celebration is a full-screen exploding ribbon and
/// confetti burst (Lotties "Exploding Ribbon and Confetti"); otherwise it
/// stays the calm gold ring over a frosted scrim. The future resolves once
/// the overlay is gone, so callers navigate right after.
Future<void> showAuthSuccess(
  BuildContext context, {
  bool confetti = false,
}) async {
  if (!context.mounted) return;
  final reduced = prefersReducedMotion(context);
  final hold = reduced
      ? const Duration(milliseconds: 500)
      : confetti
      ? const Duration(milliseconds: 2600)
      : const Duration(milliseconds: 1500);

  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'auth-success',
    barrierColor: Colors.black.withValues(alpha: confetti ? 0.35 : 0.28),
    transitionDuration: reduced ? Duration.zero : AppMotion.base,
    pageBuilder: (dialogContext, _, __) {
      Future.delayed(hold, () {
        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      });
      return _AuthSuccessView(reduced: reduced, confetti: confetti);
    },
    transitionBuilder: (dialogContext, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppMotion.emphasized);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _AuthSuccessView extends StatelessWidget {
  final bool reduced;
  final bool confetti;
  const _AuthSuccessView({required this.reduced, this.confetti = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badge = SizedBox(
      width: 168,
      height: 168,
      child: reduced
          ? Icon(Icons.check_circle_rounded, size: 96, color: colors.success)
          : Lottie.asset(
              'assets/lottie/success_animation.json',
              repeat: false,
              errorBuilder: (_, __, ___) => Icon(
                Icons.check_circle_rounded,
                size: 96,
                color: colors.success,
              ),
            ),
    );

    if (confetti) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (!reduced)
            IgnorePointer(
              child: Transform.scale(
                scale: 1.3,
                child: Transform.translate(
                  offset: const Offset(60, -110),
                  child: Lottie.asset(
                    'assets/lottie/auth_confetti_burst.json',
                    repeat: false,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: badge,
      ),
    );
  }
}
