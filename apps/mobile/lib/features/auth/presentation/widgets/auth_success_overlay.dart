import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:takwa/core/theme/app_theme.dart';

/// Short success moment shown after sign-in before the app reveals itself.
/// With [confetti] the celebration is a full-screen exploding ribbon and
/// confetti burst (LottieFiles "Exploding Ribbon and Confetti" by Lexi
/// Michel); otherwise it stays the calm gold ring over a frosted scrim. The
/// future resolves once the overlay is gone, so callers navigate right after.
Future<void> showAuthSuccess(
  BuildContext context, {
  required String label,
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
      return _AuthSuccessView(
        label: label,
        reduced: reduced,
        confetti: confetti,
      );
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
  final String label;
  final bool reduced;
  final bool confetti;
  const _AuthSuccessView({
    required this.label,
    required this.reduced,
    this.confetti = false,
  });

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
              // A bad asset must never block entry into the app.
              errorBuilder: (_, __, ___) => Icon(
                Icons.check_circle_rounded,
                size: 96,
                color: colors.success,
              ),
            ),
    );
    final title = ShaderMask(
      shaderCallback: (bounds) =>
          colors.goldGradient.createShader(bounds),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.typography.headingMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    if (confetti) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                badge,
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: title,
                ),
              ],
            ),
          ),
          if (!reduced)
            IgnorePointer(
              // The source animation is 16:9 with the burst starting at the
              // top-left; contain-fitting it on a phone leaves the confetti
              // raining from off-frame, so pull it in and scale it up.
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge,
            const SizedBox(height: AppSpacing.lg),
            title,
          ],
        ),
      ),
    );
  }
}
