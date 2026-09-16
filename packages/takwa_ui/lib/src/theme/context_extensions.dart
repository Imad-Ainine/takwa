import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_typography.dart';

/// Convenient build-context accessors for theme extensions.
extension ThemeContextExt on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.dark;

  AppTypographyExtension get typography =>
      Theme.of(this).extension<AppTypographyExtension>() ??
      AppTypographyExtension.fromColors(colors);

  AppDecorationsExtension get decorations =>
      Theme.of(this).extension<AppDecorationsExtension>() ??
      AppDecorationsExtension.fromColors(colors, shadows);

  AppShadowsExtension get shadows =>
      Theme.of(this).extension<AppShadowsExtension>() ??
      AppShadowsExtension.fromColors(colors);
}
