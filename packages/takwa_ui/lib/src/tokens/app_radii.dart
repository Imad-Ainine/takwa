import 'package:flutter/material.dart';

/// Corner radius values for cards, buttons, dialogs, and pills.
abstract final class AppRadius {
  /// 4dp - Small tags, mini badges, progress tracks
  static const double xs = 4.0;

  /// 8dp - Micro chips, inner badges, tooltips
  static const double sm = 8.0;

  /// 12dp - Standard inputs, buttons, filter chips
  static const double md = 12.0;

  /// 16dp - Standard cards, dialogs, alert containers
  static const double lg = 16.0;

  /// 20dp - Large feature blocks, hero containers
  static const double xl = 20.0;

  /// 24dp - Bottom sheets top corner radius
  static const double xxl = 24.0;

  /// 999dp - Fully rounded pills and circular action targets
  static const double full = 999.0;

  // ── Predefined BorderRadius ──
  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get button => BorderRadius.circular(full);
  static BorderRadius get chip => BorderRadius.circular(full);
  static BorderRadius get input => BorderRadius.circular(md);
  static BorderRadius get bottomSheet => const BorderRadius.only(
    topLeft: Radius.circular(xxl),
    topRight: Radius.circular(xxl),
  );
}
