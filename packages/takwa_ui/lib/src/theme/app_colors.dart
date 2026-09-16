import 'package:flutter/material.dart';

/// Semantic color roles and gradients for the Takwa Design System.
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

  // ── On-surface accent ramp ──
  // `gold`/`teal`/`success`/`warning`/`danger` are fill colors sitting behind
  // content. Using them as foregrounds on light surfaces fails WCAG (gold on white is 2.24:1).
  // These `*Text` roles are tuned to clear AA (>=4.5:1) on light surfaces.
  final Color goldText;
  final Color tealText;
  final Color successText;
  final Color warningText;
  final Color dangerText;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDim;

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
    required this.goldText,
    required this.tealText,
    required this.successText,
    required this.warningText,
    required this.dangerText,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDim,
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
    Color? goldText,
    Color? tealText,
    Color? successText,
    Color? warningText,
    Color? dangerText,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDim,
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
    goldText: goldText ?? this.goldText,
    tealText: tealText ?? this.tealText,
    successText: successText ?? this.successText,
    warningText: warningText ?? this.warningText,
    dangerText: dangerText ?? this.dangerText,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textDim: textDim ?? this.textDim,
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
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      tealText: Color.lerp(tealText, other.tealText, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
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
    gold: Color(0xFFC8A96E),
    goldLight: Color(0xFFE4C98A),
    goldDark: Color(0xFFB8920E),
    goldDim: Color(0x26C8A96E), // 15% opacity
    teal: Color(0xFF3AAFA9),
    tealDim: Color(0x1F3AAFA9), // 12%
    success: Color(0xFF4CAF7D),
    successDim: Color(0x1F4CAF7D),
    danger: Color(0xFFE07070),
    dangerDim: Color(0x1FE07070),
    warning: Color(0xFFE0A044),
    goldText: Color(0xFFC8A96E),
    tealText: Color(0xFF3AAFA9),
    successText: Color(0xFF4CAF7D),
    warningText: Color(0xFFE0A044),
    dangerText: Color(0xFFE07070),
    textPrimary: Color(0xFFE8EDF3),
    textSecondary: Color(0xFF8FA3BB),
    textDim: Color(0xFF8299B2),
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
    gold: Color(0xFFC8A96E),
    goldLight: Color(0xFFE4C98A),
    goldDark: Color(0xFFB8920E),
    goldDim: Color(0x1FC8A96E), // 12% opacity
    teal: Color(0xFF3AAFA9),
    tealDim: Color(0x1F3AAFA9),
    success: Color(0xFF4CAF7D),
    successDim: Color(0x1F4CAF7D),
    danger: Color(0xFFE07070),
    dangerDim: Color(0x1FE07070),
    warning: Color(0xFFE0A044),
    goldText: Color(0xFF6B5320), // 7.28:1 on #FFFFFF
    tealText: Color(0xFF0F5C57), // 7.81:1
    successText: Color(0xFF197045), // 6.10:1
    warningText: Color(0xFF7A5210), // 6.90:1
    dangerText: Color(0xFFA81E17), // 7.33:1
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textDim: Color(0xFF6B7280),
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
