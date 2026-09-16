import 'package:flutter/material.dart';

/// Predictable animation durations and easing curves across Takwa UI.
abstract final class AppMotion {
  /// Press/selection feedback, toggle and switch transitions (180ms).
  static const Duration fast = Duration(milliseconds: 180);

  /// Card and section enter/exit, crossfades, default transitions (280ms).
  static const Duration base = Duration(milliseconds: 280);

  /// Page-level transitions, sheet/drawer slide animations (420ms).
  static const Duration slow = Duration(milliseconds: 420);

  /// Default decelerating easing curve for natural entrance.
  static const Curve standard = Curves.easeOutCubic;

  /// Emphasized ease-in-out curve for midpoint morphing or expanding.
  static const Curve emphasized = Curves.easeInOutCubic;
}

/// Helper returning whether the user prefers reduced motion.
bool prefersReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Extension on [AnimationController] respecting reduced motion preferences.
extension ReducedMotionRepeat on AnimationController {
  /// Starts or maintains an infinite loop unless reduced-motion is requested.
  void repeatUnlessReducedMotion(
    BuildContext context, {
    bool reverse = false,
    double restingValue = 0.0,
    double? min,
    double? max,
    Duration? period,
  }) {
    if (prefersReducedMotion(context)) {
      if (isAnimating) stop();
      value = restingValue;
    } else if (!isAnimating) {
      repeat(reverse: reverse, min: min, max: max, period: period);
    }
  }
}
