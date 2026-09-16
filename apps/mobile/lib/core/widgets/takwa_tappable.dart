import 'package:flutter/material.dart';
import 'package:takwa_ui/takwa_ui.dart';

/// One pressable wrapper for the ~130 bare `GestureDetector`s across the app
/// that currently give the user zero visual acknowledgement of a tap —
/// ripples are globally disabled on this theme's `tabBarTheme`/dialogs, and
/// `GestureDetector` itself never had one to begin with. Wrapping something
/// in this instead of a raw `GestureDetector` gets you, for free:
///
/// - a small scale-down on press (1.0 → 0.97) so *something* visibly happens
///   even where a ripple would look wrong (a card, a custom-painted row)
/// - a subtle pressed-state tint over [child]
/// - `Semantics(button: true)` and (by default) a 48dp minimum tap target —
///   the two accessibility properties a raw `GestureDetector` never had
/// - `HitTestBehavior.opaque`, so the transparent parts of [child] (e.g. the
///   padding around an icon+label `Row`) are tappable too, not just its
///   painted pixels
///
/// The 3% press-scale runs unconditionally, not gated behind
/// [prefersReducedMotion]: that setting targets large or looping motion
/// (parallax, ambient loops), not a sub-200ms functional press response —
/// suppressing it here would remove the tap feedback this widget exists to
/// add, for a class of animation reduce-motion isn't concerned with.
class TakwaTappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  /// Announced by screen readers. Omit when [child] already carries its own
  /// (a row with visible, readable text) — passing one here on top would
  /// duplicate it in the semantics tree.
  final String? semanticLabel;

  /// False for a decorative wrapper whose child supplies its own semantics
  /// node (e.g. an icon button that already wraps `Semantics(button: true)`)
  /// — avoids two overlapping "button" nodes for one tap target.
  final bool isSemanticButton;

  /// Clips the press-tint and bounds the scale transform to this shape.
  /// Defaults to a 12px radius — pass the same radius as [child]'s own
  /// decoration (or `BorderRadius.zero` for a full-bleed row) so the tint
  /// doesn't spill past a rounded card's corners or, worse, past a *smaller*
  /// radius than the child actually paints with.
  final BorderRadius borderRadius;

  /// Minimum width/height enforced via a `ConstrainedBox`. Defaults to 48
  /// (the platform tap-target floor) for a standalone control. Pass `null`
  /// for something that sits inline in a `Row`/`Wrap` alongside other
  /// content at a fixed compact size (a 24-26px inline checkbox, a small
  /// trailing icon) — forcing 48dp there doesn't enlarge the tap target so
  /// much as blow out the layout around it, since `Row`/`Wrap` size each
  /// child to its own requested size. Still gets press-scale, the tint,
  /// `Semantics`, and opaque hit-testing either way.
  final double? minTapSize;

  const TakwaTappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.semanticLabel,
    this.isSemanticButton = true,
    this.minTapSize = 48,
    BorderRadius? borderRadius,
  }) : borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(12));

  @override
  State<TakwaTappable> createState() => _TakwaTappableState();
}

class _TakwaTappableState extends State<TakwaTappable> {
  bool _pressed = false;

  bool get _enabled =>
      widget.onTap != null || widget.onLongPress != null || widget.onDoubleTap != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tintColor = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: widget.isSemanticButton,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        // Deliberately opaque: the default (deferToChild) only registers a
        // hit where the child actually painted a pixel, which is why a lot
        // of the 132 existing GestureDetectors have dead zones in their own
        // padding.
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onDoubleTap: widget.onDoubleTap,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        child: _wrapMinSize(
          AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  widget.child,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _pressed ? 0.06 : 0.0,
                        duration: AppMotion.fast,
                        curve: AppMotion.standard,
                        child: ColoredBox(color: tintColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wrapMinSize(Widget child) {
    final size = widget.minTapSize;
    if (size == null) return child;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      child: child,
    );
  }
}
