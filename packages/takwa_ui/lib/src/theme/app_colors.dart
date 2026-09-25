import 'package:flutter/material.dart';

import 'app_palettes.dart';

/// Semantic color roles and gradients for the Takwa Design System.
///
/// Organized in three layers, mirroring Shopify Polaris / IBM Carbon:
///
/// 1. **Primitives** — raw tonal ramps in [AppPalette] (theme-agnostic).
/// 2. **Semantic roles** (this class) — what each color *means*:
///    surfaces, borders, text, action (gold/teal) states, status families
///    (success / warning / danger / info), and on-colors for content placed
///    on top of filled surfaces.
/// 3. **Component themes** — [AppTheme] maps these roles onto Material's
///    ColorScheme and per-widget themes.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color deep;
  final Color card;
  final Color card2;
  final Color border;
  final Color night;

  final Color gold;
  final Color goldLight;
  final Color goldDark;
  final Color goldDim;

  final Color teal;
  final Color tealDim;

  final Color success;
  final Color successDim;
  final Color danger;
  final Color dangerDim;
  final Color warning;

  // ── Status: informational (blue family) ──
  final Color info;
  final Color infoDim;
  final Color infoText;

  // ── On-surface accent ramp ──
  // `gold`/`teal`/`success`/`warning`/`danger`/`info` are fill colors sitting
  // behind content. Using them as foregrounds on light surfaces fails WCAG
  // (gold on white is 2.24:1). These `*Text` roles are tuned to clear AA
  // (>=4.5:1) on light surfaces.
  final Color goldText;
  final Color tealText;
  final Color successText;
  final Color warningText;
  final Color dangerText;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDim;

  // ── On-colors (Carbon `*-on-color` / Polaris `text-on-color`) ──
  // Foregrounds guaranteed readable on the matching fill. Gold, teal and the
  // status fills are mid-luminance, so their on-color is a dark tint of the
  // fill hue, not white — except where the fill itself is dark enough
  // (e.g. light-theme blue info) to carry white.
  final Color onGold;
  final Color onTeal;
  final Color onSuccess;
  final Color onDanger;
  final Color onWarning;
  final Color onInfo;

  // ── Action (primary/secondary) interaction states ──
  // Hover lightens the fill in dark mode and darkens it in light mode, the
  // Polaris/Carbon convention; pressed goes one step further.
  final Color primaryHover;
  final Color primaryPressed;
  final Color primaryDisabled;
  final Color onPrimaryDisabled;
  final Color secondaryHover;
  final Color secondaryPressed;

  // ── Surface interaction states ──
  final Color surfaceSubdued;
  final Color surfaceHovered;
  final Color surfacePressed;
  final Color surfaceInverse;
  final Color onSurfaceInverse;

  // ── Border interaction states ──
  final Color borderSubdued;
  final Color borderHover;
  final Color borderStrong;

  // ── Utility ──
  /// Focus indicator color; clears the WCAG 2.2 >=3:1 non-text minimum
  /// against both light and dark surfaces.
  final Color focusRing;

  /// Scrim behind modals, bottom sheets and menus.
  final Color overlay;
  final Color disabledBackground;
  final Color disabledContent;

  final LinearGradient backgroundGradient;
  final LinearGradient cardGradient;
  final LinearGradient goldGradient;
  final LinearGradient tealGoldGradient;

  const AppColorsExtension({
    required this.background,
    required this.deep,
    required this.card,
    required this.card2,
    required this.border,
    required this.night,
    required this.gold,
    required this.goldLight,
    required this.goldDark,
    required this.goldDim,
    required this.teal,
    required this.tealDim,
    required this.success,
    required this.successDim,
    required this.danger,
    required this.dangerDim,
    required this.warning,
    required this.info,
    required this.infoDim,
    required this.infoText,
    required this.goldText,
    required this.tealText,
    required this.successText,
    required this.warningText,
    required this.dangerText,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDim,
    required this.onGold,
    required this.onTeal,
    required this.onSuccess,
    required this.onDanger,
    required this.onWarning,
    required this.onInfo,
    required this.primaryHover,
    required this.primaryPressed,
    required this.primaryDisabled,
    required this.onPrimaryDisabled,
    required this.secondaryHover,
    required this.secondaryPressed,
    required this.surfaceSubdued,
    required this.surfaceHovered,
    required this.surfacePressed,
    required this.surfaceInverse,
    required this.onSurfaceInverse,
    required this.borderSubdued,
    required this.borderHover,
    required this.borderStrong,
    required this.focusRing,
    required this.overlay,
    required this.disabledBackground,
    required this.disabledContent,
    required this.backgroundGradient,
    required this.cardGradient,
    required this.goldGradient,
    required this.tealGoldGradient,
  });

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? deep,
    Color? card,
    Color? card2,
    Color? border,
    Color? night,
    Color? gold,
    Color? goldLight,
    Color? goldDark,
    Color? goldDim,
    Color? teal,
    Color? tealDim,
    Color? success,
    Color? successDim,
    Color? danger,
    Color? dangerDim,
    Color? warning,
    Color? info,
    Color? infoDim,
    Color? infoText,
    Color? goldText,
    Color? tealText,
    Color? successText,
    Color? warningText,
    Color? dangerText,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDim,
    Color? onGold,
    Color? onTeal,
    Color? onSuccess,
    Color? onDanger,
    Color? onWarning,
    Color? onInfo,
    Color? primaryHover,
    Color? primaryPressed,
    Color? primaryDisabled,
    Color? onPrimaryDisabled,
    Color? secondaryHover,
    Color? secondaryPressed,
    Color? surfaceSubdued,
    Color? surfaceHovered,
    Color? surfacePressed,
    Color? surfaceInverse,
    Color? onSurfaceInverse,
    Color? borderSubdued,
    Color? borderHover,
    Color? borderStrong,
    Color? focusRing,
    Color? overlay,
    Color? disabledBackground,
    Color? disabledContent,
    LinearGradient? backgroundGradient,
    LinearGradient? cardGradient,
    LinearGradient? goldGradient,
    LinearGradient? tealGoldGradient,
  }) => AppColorsExtension(
    background: background ?? this.background,
    deep: deep ?? this.deep,
    card: card ?? this.card,
    card2: card2 ?? this.card2,
    border: border ?? this.border,
    night: night ?? this.night,
    gold: gold ?? this.gold,
    goldLight: goldLight ?? this.goldLight,
    goldDark: goldDark ?? this.goldDark,
    goldDim: goldDim ?? this.goldDim,
    teal: teal ?? this.teal,
    tealDim: tealDim ?? this.tealDim,
    success: success ?? this.success,
    successDim: successDim ?? this.successDim,
    danger: danger ?? this.danger,
    dangerDim: dangerDim ?? this.dangerDim,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    infoDim: infoDim ?? this.infoDim,
    infoText: infoText ?? this.infoText,
    goldText: goldText ?? this.goldText,
    tealText: tealText ?? this.tealText,
    successText: successText ?? this.successText,
    warningText: warningText ?? this.warningText,
    dangerText: dangerText ?? this.dangerText,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textDim: textDim ?? this.textDim,
    onGold: onGold ?? this.onGold,
    onTeal: onTeal ?? this.onTeal,
    onSuccess: onSuccess ?? this.onSuccess,
    onDanger: onDanger ?? this.onDanger,
    onWarning: onWarning ?? this.onWarning,
    onInfo: onInfo ?? this.onInfo,
    primaryHover: primaryHover ?? this.primaryHover,
    primaryPressed: primaryPressed ?? this.primaryPressed,
    primaryDisabled: primaryDisabled ?? this.primaryDisabled,
    onPrimaryDisabled: onPrimaryDisabled ?? this.onPrimaryDisabled,
    secondaryHover: secondaryHover ?? this.secondaryHover,
    secondaryPressed: secondaryPressed ?? this.secondaryPressed,
    surfaceSubdued: surfaceSubdued ?? this.surfaceSubdued,
    surfaceHovered: surfaceHovered ?? this.surfaceHovered,
    surfacePressed: surfacePressed ?? this.surfacePressed,
    surfaceInverse: surfaceInverse ?? this.surfaceInverse,
    onSurfaceInverse: onSurfaceInverse ?? this.onSurfaceInverse,
    borderSubdued: borderSubdued ?? this.borderSubdued,
    borderHover: borderHover ?? this.borderHover,
    borderStrong: borderStrong ?? this.borderStrong,
    focusRing: focusRing ?? this.focusRing,
    overlay: overlay ?? this.overlay,
    disabledBackground: disabledBackground ?? this.disabledBackground,
    disabledContent: disabledContent ?? this.disabledContent,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    cardGradient: cardGradient ?? this.cardGradient,
    goldGradient: goldGradient ?? this.goldGradient,
    tealGoldGradient: tealGoldGradient ?? this.tealGoldGradient,
  );

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      card: Color.lerp(card, other.card, t)!,
      card2: Color.lerp(card2, other.card2, t)!,
      border: Color.lerp(border, other.border, t)!,
      night: Color.lerp(night, other.night, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldLight: Color.lerp(goldLight, other.goldLight, t)!,
      goldDark: Color.lerp(goldDark, other.goldDark, t)!,
      goldDim: Color.lerp(goldDim, other.goldDim, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tealDim: Color.lerp(tealDim, other.tealDim, t)!,
      success: Color.lerp(success, other.success, t)!,
      successDim: Color.lerp(successDim, other.successDim, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerDim: Color.lerp(dangerDim, other.dangerDim, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoDim: Color.lerp(infoDim, other.infoDim, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      tealText: Color.lerp(tealText, other.tealText, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      onTeal: Color.lerp(onTeal, other.onTeal, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primaryDisabled: Color.lerp(primaryDisabled, other.primaryDisabled, t)!,
      onPrimaryDisabled: Color.lerp(
        onPrimaryDisabled,
        other.onPrimaryDisabled,
        t,
      )!,
      secondaryHover: Color.lerp(secondaryHover, other.secondaryHover, t)!,
      secondaryPressed: Color.lerp(
        secondaryPressed,
        other.secondaryPressed,
        t,
      )!,
      surfaceSubdued: Color.lerp(surfaceSubdued, other.surfaceSubdued, t)!,
      surfaceHovered: Color.lerp(surfaceHovered, other.surfaceHovered, t)!,
      surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
      surfaceInverse: Color.lerp(surfaceInverse, other.surfaceInverse, t)!,
      onSurfaceInverse: Color.lerp(
        onSurfaceInverse,
        other.onSurfaceInverse,
        t,
      )!,
      borderSubdued: Color.lerp(borderSubdued, other.borderSubdued, t)!,
      borderHover: Color.lerp(borderHover, other.borderHover, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      disabledBackground: Color.lerp(
        disabledBackground,
        other.disabledBackground,
        t,
      )!,
      disabledContent: Color.lerp(
        disabledContent,
        other.disabledContent,
        t,
      )!,
      backgroundGradient: LinearGradient.lerp(
        backgroundGradient,
        other.backgroundGradient,
        t,
      )!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      goldGradient: LinearGradient.lerp(goldGradient, other.goldGradient, t)!,
      tealGoldGradient: LinearGradient.lerp(
        tealGoldGradient,
        other.tealGoldGradient,
        t,
      )!,
    );
  }

  // --- Dark Colors ---
  static const dark = AppColorsExtension(
    background: Color(0xFF04011E),
    deep: Color(0xFF111827),
    card: Color(0xFF1A2332),
    card2: Color(0xFF1E2D40),
    border: Color(0xFF2A3A50),
    night: Color(0xFF0D1117),
    gold: AppPalette.gold500,
    goldLight: AppPalette.gold300,
    goldDark: Color(0xFFB8920E),
    goldDim: Color(0x26C8A96E), // 15% opacity
    teal: AppPalette.teal500,
    tealDim: Color(0x1F3AAFA9), // 12%
    success: AppPalette.green500,
    successDim: Color(0x1F4CAF7D),
    danger: AppPalette.red500,
    dangerDim: Color(0x1FE07070),
    warning: AppPalette.yellow500,
    info: Color(0xFF6FA7F2),
    infoDim: Color(0x1F6FA7F2),
    infoText: Color(0xFF8FBAFF), // 8.0:1 on card
    goldText: Color(0xFFC8A96E),
    tealText: Color(0xFF3AAFA9),
    successText: Color(0xFF4CAF7D),
    warningText: Color(0xFFE0A044),
    dangerText: Color(0xFFE07070),
    textPrimary: Color(0xFFE8EDF3),
    textSecondary: Color(0xFF8FA3BB),
    textDim: Color(0xFF8299B2),
    onGold: Color(0xFF241B05), // 7.6:1 on gold
    onTeal: Color(0xFF06201F), // 6.4:1 on teal
    onSuccess: Color(0xFF0B2E1D), // 5.4:1 on success
    onDanger: Color(0xFF330B08), // 5.6:1 on danger
    onWarning: Color(0xFF38260A), // 6.4:1 on warning
    onInfo: Color(0xFF0A1E3C), // 6.7:1 on info
    primaryHover: Color(0xFFD6BA85),
    primaryPressed: Color(0xFFB8985A),
    primaryDisabled: Color(0xFF2A3550),
    onPrimaryDisabled: Color(0xFF5C6F8A),
    secondaryHover: Color(0xFF54C2BD),
    secondaryPressed: Color(0xFF2F948F),
    surfaceSubdued: Color(0xFF0C1424),
    surfaceHovered: Color(0xFF22304A),
    surfacePressed: Color(0xFF1B2940),
    surfaceInverse: Color(0xFFF3F4F6),
    onSurfaceInverse: Color(0xFF111827),
    borderSubdued: Color(0xFF1F2C40),
    borderHover: Color(0xFF3A4E6B),
    borderStrong: Color(0xFF4A5F7E),
    focusRing: Color(0xFFE4C98A),
    overlay: Color(0xB3000000), // 70% black
    disabledBackground: Color(0xFF1C2434),
    disabledContent: Color(0xFF56677F),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0D1117), Color(0xFF111827), Color(0xFF0D1117)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x20C8A96E), Color(0x0D3AAFA9)],
    ),
    goldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE4C98A), Color(0xFFC8A96E), Color(0xFFB8920E)],
    ),
    tealGoldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3AAFA9), Color(0xFFC8A96E)],
    ),
  );

  // --- Light Colors ---
  static const light = AppColorsExtension(
    background: Color(0xFFF9FAFB),
    deep: Color(0xFFF3F4F6),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFF3F4F6),
    border: Color(0xFFE2E8F0),
    night: Color(0xFFF9FAFB),
    gold: AppPalette.gold500,
    goldLight: AppPalette.gold300,
    goldDark: Color(0xFFB8920E),
    goldDim: Color(0x1FC8A96E), // 12% opacity
    teal: AppPalette.teal500,
    tealDim: Color(0x1F3AAFA9),
    success: AppPalette.green500,
    successDim: Color(0x1F4CAF7D),
    danger: AppPalette.red500,
    dangerDim: Color(0x1FE07070),
    warning: AppPalette.yellow500,
    info: AppPalette.blue600,
    infoDim: Color(0x1F2563EB),
    infoText: AppPalette.blue700, // 6.7:1 on #FFFFFF
    goldText: Color(0xFF6B5320), // 7.28:1 on #FFFFFF
    tealText: Color(0xFF0F5C57), // 7.81:1
    successText: Color(0xFF197045), // 6.10:1
    warningText: Color(0xFF7A5210), // 6.90:1
    dangerText: Color(0xFFA81E17), // 7.33:1
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textDim: Color(0xFF6B7280),
    onGold: Color(0xFF241B05), // 7.6:1 on gold
    onTeal: Color(0xFF06201F), // 6.4:1 on teal
    onSuccess: Color(0xFF0B2E1D), // 5.4:1 on success
    onDanger: Color(0xFF330B08), // 5.6:1 on danger
    onWarning: Color(0xFF38260A), // 6.4:1 on warning
    onInfo: Color(0xFFFFFFFF), // 5.2:1 on blue600
    primaryHover: Color(0xFFBE9F67),
    primaryPressed: AppPalette.gold600,
    primaryDisabled: AppPalette.neutral200,
    onPrimaryDisabled: AppPalette.neutral400,
    secondaryHover: AppPalette.teal600,
    secondaryPressed: AppPalette.teal700,
    surfaceSubdued: Color(0xFFF7F8FA),
    surfaceHovered: Color(0xFFF3F5F8),
    surfacePressed: Color(0xFFEBEFF3),
    surfaceInverse: Color(0xFF111827),
    onSurfaceInverse: Color(0xFFF9FAFB),
    borderSubdued: Color(0xFFEDF0F4),
    borderHover: AppPalette.neutral300,
    borderStrong: AppPalette.neutral400,
    focusRing: AppPalette.gold700, // 4.8:1 on #FFFFFF — clears WCAG 2.2 non-text minimum
    overlay: Color(0x80000000), // 50% black
    disabledBackground: Color(0xFFF3F4F6),
    disabledContent: Color(0xFF9CA3AF),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6), Color(0xFFF9FAFB)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x10C8A96E), Color(0x0A3AAFA9)],
    ),
    goldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE4C98A), Color(0xFFC8A96E), Color(0xFFB8920E)],
    ),
    tealGoldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3AAFA9), Color(0xFFC8A96E)],
    ),
  );
}

/// Backward compatibility class where `static const` color access is required.
abstract final class AppColors {
  AppColors._();
  static const night = Color(0xFF0D1117);
  static const deep = Color(0xFF111827);
  static const card = Color(0xFF1A2332);
  static const card2 = Color(0xFF1E2D40);
  static const border = Color(0xFF2A3A50);
  static const gold = Color(0xFFC8A96E);
  static const goldLight = Color(0xFFE4C98A);
  static const goldDark = Color(0xFFB8920E);
  static const goldDim = Color(0x26C8A96E);
  static const teal = Color(0xFF3AAFA9);
  static const tealDim = Color(0x1F3AAFA9);
  static const success = Color(0xFF4CAF7D);
  static const successDim = Color(0x1F4CAF7D);
  static const danger = Color(0xFFE07070);
  static const dangerDim = Color(0x1FE07070);
  static const warning = Color(0xFFE0A044);
  static const textPrimary = Color(0xFFE8EDF3);
  static const textSecondary = Color(0xFF8FA3BB);
  static const textDim = Color(0xFF4A6070);
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1117), Color(0xFF111827), Color(0xFF0D1117)],
  );
}
