import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:takwa/core/theme/app_theme.dart';

/// Short, calm success moment shown after sign-in before the app reveals
/// itself: a gold ring completion animation over a frosted scrim. The future
/// resolves once the overlay is gone, so callers navigate right after.
Future<void> showAuthSuccess(
  BuildContext context, {
  required String label,
}) async {
  if (!context.mounted) return;
  final reduced = prefersReducedMotion(context);
  final hold = reduced
      ? const Duration(milliseconds: 500)
      : const Duration(milliseconds: 1500);

  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'auth-success',
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: reduced ? Duration.zero : AppMotion.base,
    pageBuilder: (dialogContext, _, __) {
      Future.delayed(hold, () {
        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      });
      return _AuthSuccessView(label: label, reduced: reduced);
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
  const _AuthSuccessView({required this.label, required this.reduced});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 168,
              height: 168,
              child: reduced
                  ? Icon(
                      Icons.check_circle_rounded,
                      size: 96,
                      color: colors.success,
                    )
                  : Lottie.asset(
                      'assets/lottie/auth_success.json',
                      repeat: false,
                      // A bad asset must never block entry into the app.
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.check_circle_rounded,
                        size: 96,
                        color: colors.success,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ShaderMask(
              shaderCallback: (bounds) =>
                  colors.goldGradient.createShader(bounds),
              child: Text(
                label,
                style: context.typography.headingMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
