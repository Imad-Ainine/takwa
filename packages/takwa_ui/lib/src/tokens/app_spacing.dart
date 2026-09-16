import 'package:flutter/material.dart';

/// Standard 4dp/8dp spatial increments for the Takwa Design System.
abstract final class AppSpacing {
  /// 2dp - Micro adjustments, hairline offsets
  static const double xxs = 2.0;

  /// 4dp - Tight element spacing, inner badge padding
  static const double xs = 4.0;

  /// 8dp - Compact item spacing, icon-to-label gaps
  static const double sm = 8.0;

  /// 12dp - Standard component internal spacing
  static const double md = 12.0;

  /// 16dp - Standard screen horizontal gutter and card padding
  static const double lg = 16.0;

  /// 20dp - Generous card padding, section gap
  static const double xl = 20.0;

  /// 24dp - Major container padding, hero margins
  static const double xxl = 24.0;

  /// 32dp - Section vertical separations
  static const double xxxl = 32.0;

  /// 48dp - Major block margins, bottom sheet top offsets
  static const double huge = 48.0;

  // ── Predefined Insets ──
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: 6.0,
  );
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: 14.0,
  );
}
