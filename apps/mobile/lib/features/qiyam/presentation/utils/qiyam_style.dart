import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class QiyamStyle {
  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: context.colors.card,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: context.colors.border),
    );
  }

  static BoxDecoration highlightedCardDecoration(
    BuildContext context,
    Color highlightColor,
  ) {
    return BoxDecoration(
      color: context.colors.card,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: highlightColor.withValues(alpha: 0.5), width: 2),
      boxShadow: [
        BoxShadow(
          color: highlightColor.withValues(alpha: 0.1),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static LinearGradient qiyamActionGradient(BuildContext context) {
    return LinearGradient(colors: [context.colors.gold, context.colors.teal]);
  }
}
