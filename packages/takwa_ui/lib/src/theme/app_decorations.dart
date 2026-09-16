import 'package:flutter/material.dart';
import '../tokens/app_radii.dart';
import 'app_colors.dart';

/// Semantic shadows for elevation and warm glowing accents.
@immutable
class AppShadowsExtension extends ThemeExtension<AppShadowsExtension> {
  final List<BoxShadow> card;
  final List<BoxShadow> goldGlow;
  final List<BoxShadow> tealGlow;

  const AppShadowsExtension({
    required this.card,
    required this.goldGlow,
    required this.tealGlow,
  });

  @override
  AppShadowsExtension copyWith({
    List<BoxShadow>? card,
    List<BoxShadow>? goldGlow,
    List<BoxShadow>? tealGlow,
  }) => AppShadowsExtension(
    card: card ?? this.card,
    goldGlow: goldGlow ?? this.goldGlow,
    tealGlow: tealGlow ?? this.tealGlow,
  );

  @override
  ThemeExtension<AppShadowsExtension> lerp(
    ThemeExtension<AppShadowsExtension>? other,
    double t,
  ) {
    if (other is! AppShadowsExtension) return this;
    return AppShadowsExtension(
      card: _lerpShadowList(card, other.card, t),
      goldGlow: _lerpShadowList(goldGlow, other.goldGlow, t),
      tealGlow: _lerpShadowList(tealGlow, other.tealGlow, t),
    );
  }

  static List<BoxShadow> _lerpShadowList(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    final len = a.length < b.length ? a.length : b.length;
    return [for (var i = 0; i < len; i++) BoxShadow.lerp(a[i], b[i], t)!];
  }

  static AppShadowsExtension fromColors(AppColorsExtension colors) {
    final isLight = colors.background.computeLuminance() > 0.5;
    return AppShadowsExtension(
      card: [
        BoxShadow(
          color: isLight
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      goldGlow: [
        BoxShadow(
          color: colors.gold.withValues(alpha: isLight ? 0.15 : 0.25),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ],
      tealGlow: [
        BoxShadow(
          color: colors.teal.withValues(alpha: isLight ? 0.1 : 0.2),
          blurRadius: 16,
        ),
      ],
    );
  }
}

/// Semantic box decorations for cards, rows, and backgrounds.
@immutable
class AppDecorationsExtension extends ThemeExtension<AppDecorationsExtension> {
  final BoxDecoration card;
  final BoxDecoration goldCard;
  final BoxDecoration tealCard;
  final BoxDecoration successRow;
  final BoxDecoration dangerRow;
  final BoxDecoration appBackground;

  const AppDecorationsExtension({
    required this.card,
    required this.goldCard,
    required this.tealCard,
    required this.successRow,
    required this.dangerRow,
    required this.appBackground,
  });

  @override
  AppDecorationsExtension copyWith({
    BoxDecoration? card,
    BoxDecoration? goldCard,
    BoxDecoration? tealCard,
    BoxDecoration? successRow,
    BoxDecoration? dangerRow,
    BoxDecoration? appBackground,
  }) => AppDecorationsExtension(
    card: card ?? this.card,
    goldCard: goldCard ?? this.goldCard,
    tealCard: tealCard ?? this.tealCard,
    successRow: successRow ?? this.successRow,
    dangerRow: dangerRow ?? this.dangerRow,
    appBackground: appBackground ?? this.appBackground,
  );

  @override
  ThemeExtension<AppDecorationsExtension> lerp(
    ThemeExtension<AppDecorationsExtension>? other,
    double t,
  ) {
    if (other is! AppDecorationsExtension) return this;
    return AppDecorationsExtension(
      card: BoxDecoration.lerp(card, other.card, t)!,
      goldCard: BoxDecoration.lerp(goldCard, other.goldCard, t)!,
      tealCard: BoxDecoration.lerp(tealCard, other.tealCard, t)!,
      successRow: BoxDecoration.lerp(successRow, other.successRow, t)!,
      dangerRow: BoxDecoration.lerp(dangerRow, other.dangerRow, t)!,
      appBackground: BoxDecoration.lerp(appBackground, other.appBackground, t)!,
    );
  }

  static AppDecorationsExtension fromColors(
    AppColorsExtension colors,
    AppShadowsExtension shadows,
  ) {
    return AppDecorationsExtension(
      card: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: colors.border),
      ),
      goldCard: BoxDecoration(
        gradient: colors.cardGradient,
        borderRadius: AppRadius.card,
        border: Border.all(color: colors.gold.withValues(alpha: 0.2)),
        boxShadow: shadows.goldGlow,
      ),
      tealCard: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: colors.teal.withValues(alpha: 0.25)),
      ),
      successRow: BoxDecoration(
        color: colors.successDim,
        borderRadius: AppRadius.card,
        border: Border.all(color: colors.success.withValues(alpha: 0.25)),
      ),
      dangerRow: BoxDecoration(
        color: colors.dangerDim,
        borderRadius: AppRadius.card,
        border: Border.all(color: colors.danger.withValues(alpha: 0.2)),
      ),
      appBackground: BoxDecoration(gradient: colors.backgroundGradient),
    );
  }
}
