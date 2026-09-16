import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../theme/context_extensions.dart';

/// Base surface container for content blocks with hairline borders and optional tap response.
class TakwaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const TakwaCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadows = context.shadows;

    return Container(
      decoration: BoxDecoration(
        color: color ?? colors.card,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: borderColor ?? colors.border,
          width: borderWidth,
        ),
        boxShadow: boxShadow ?? shadows.card,
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
