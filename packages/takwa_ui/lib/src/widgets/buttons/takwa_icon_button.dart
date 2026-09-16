import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/app_radii.dart';
import '../../theme/context_extensions.dart';

/// Accessible Icon button guaranteeing a 48x48dp touch bounding box, tooltip semantics, and optional RTL mirroring.
class TakwaIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final bool autoMirrorRtl;

  const TakwaIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 22.0,
    this.autoMirrorRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget iconWidget = IconTheme(
      data: IconThemeData(
        color: color ?? colors.textPrimary,
        size: size,
      ),
      child: icon,
    );

    if (autoMirrorRtl && isRtl) {
      iconWidget = Transform.rotate(
        angle: math.pi,
        child: iconWidget,
      );
    }

    final button = Material(
      color: backgroundColor ?? Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: AppRadius.chip,
        onTap: onPressed != null
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 48.0,
            minHeight: 48.0,
          ),
          child: Center(child: iconWidget),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
