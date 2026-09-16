import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/app_radii.dart';
import '../../theme/context_extensions.dart';

/// Button visual variants in the Takwa Design System.
enum TakwaButtonVariant {
  /// Gold primary fill for primary actions.
  primary,

  /// Soft teal dim background with high-contrast teal text.
  secondary,

  /// Transparent background with 1.5px hairline border.
  outline,

  /// Borderless ghost button for subtle actions.
  ghost,

  /// Danger tinted background with high-contrast red text.
  destructive,
}

/// Accessible, state-aware button adhering to WCAG 48dp minimum bounds and haptic guidelines.
class TakwaButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TakwaButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const TakwaButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = TakwaButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;
    Gradient? gradient;

    switch (variant) {
      case TakwaButtonVariant.primary:
        gradient = colors.goldGradient;
        bg = colors.gold;
        fg = const Color(0xFF241B05); // High contrast on gold
        break;
      case TakwaButtonVariant.secondary:
        bg = colors.tealDim;
        fg = colors.tealText;
        break;
      case TakwaButtonVariant.outline:
        bg = Colors.transparent;
        fg = colors.goldText;
        border = BorderSide(color: colors.goldText, width: 1.5);
        break;
      case TakwaButtonVariant.ghost:
        bg = Colors.transparent;
        fg = colors.textSecondary;
        break;
      case TakwaButtonVariant.destructive:
        bg = colors.dangerDim;
        fg = colors.dangerText;
        break;
    }

    final buttonContent = Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: typography.labelLarge.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 48.0, // Minimum touch target height
        minWidth: width ?? 88.0,
      ),
      child: SizedBox(
        width: width,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isEnabled ? 1.0 : 0.45,
          child: Material(
            color: gradient == null ? bg : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.button,
              side: border,
            ),
            child: Ink(
              decoration: gradient != null
                  ? BoxDecoration(
                      gradient: isEnabled ? gradient : null,
                      color: isEnabled ? null : bg,
                      borderRadius: AppRadius.button,
                      border: border != BorderSide.none
                          ? Border.fromBorderSide(border)
                          : null,
                    )
                  : null,
              child: InkWell(
                borderRadius: AppRadius.button,
                onTap: isEnabled
                    ? () {
                        HapticFeedback.lightImpact();
                        onPressed!();
                      }
                    : null,
                child: buttonContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
