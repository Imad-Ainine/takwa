import 'package:flutter/material.dart';

/// Responsive layout breakpoints supporting mobile, foldable, tablet, and desktop views.
enum AppBreakpoint {
  /// Handheld mobile (<600dp)
  compact(0, 599),

  /// Foldable unfolded or tablet portrait (600dp - 839dp)
  medium(600, 839),

  /// Tablet landscape, desktop, or large display (>=840dp)
  expanded(840, double.infinity);

  final double minWidth;
  final double maxWidth;

  const AppBreakpoint(this.minWidth, this.maxWidth);

  static AppBreakpoint of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 840) return AppBreakpoint.expanded;
    if (width >= 600) return AppBreakpoint.medium;
    return AppBreakpoint.compact;
  }
}

/// Convenience extensions on [BuildContext] for responsive queries.
extension ResponsiveContextExt on BuildContext {
  AppBreakpoint get breakpoint => AppBreakpoint.of(this);
  bool get isCompact => breakpoint == AppBreakpoint.compact;
  bool get isMedium => breakpoint == AppBreakpoint.medium;
  bool get isExpanded => breakpoint == AppBreakpoint.expanded;
}
