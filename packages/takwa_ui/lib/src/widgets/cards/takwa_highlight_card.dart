import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../theme/context_extensions.dart';

/// Elevated card featuring gold gradient styling and ambient glow for prominent features.
class TakwaHighlightCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isGlowing;

  const TakwaHighlightCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.isGlowing = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadows = context.shadows;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        gradient: colors.cardGradient,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: colors.gold.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: isGlowing ? shadows.goldGlow : shadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          child: Padding(
            padding: padding ?? AppSpacing.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
