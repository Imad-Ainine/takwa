import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:takwa/core/theme/app_theme.dart';

/// A premium, reusable leading button for AppBars.
/// Designed to improve routing and visual consistency.
class CustomLeadingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isClose;
  final double size;

  const CustomLeadingButton({
    super.key,
    this.onPressed,
    this.icon,
    this.isClose = false,
    this.size = 40,
  });

  @override
  State<CustomLeadingButton> createState() => _CustomLeadingButtonState();
}

class _CustomLeadingButtonState extends State<CustomLeadingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward().then((_) => _controller.reverse());
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Icon selection
    final IconData effectiveIcon =
        widget.icon ??
        (widget.isClose
            ? Icons.close_rounded
            : Icons.arrow_back_ios_new_rounded);

    return Center(
      child: GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: colors.goldDim,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.gold.withValues(alpha: 0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              effectiveIcon,
              size: widget.size * 0.5,
              color: colors.gold,
            ),
          ),
        ),
      ),
    );
  }
}
