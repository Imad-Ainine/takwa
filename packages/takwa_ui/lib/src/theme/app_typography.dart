import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Semantic typography tokens supporting Latin and Arabic dual-script parity.
@immutable
class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle headingLarge;
  final TextStyle headingMedium;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle caption;
  final TextStyle quranicVerse;
  final TextStyle taqwaScore;

  const AppTypographyExtension({
    required this.displayLarge,
    required this.displayMedium,
    required this.headingLarge,
    required this.headingMedium,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.caption,
    required this.quranicVerse,
    required this.taqwaScore,
  });

  @override
  AppTypographyExtension copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? headingLarge,
    TextStyle? headingMedium,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? caption,
    TextStyle? quranicVerse,
    TextStyle? taqwaScore,
  }) => AppTypographyExtension(
    displayLarge: displayLarge ?? this.displayLarge,
    displayMedium: displayMedium ?? this.displayMedium,
    headingLarge: headingLarge ?? this.headingLarge,
    headingMedium: headingMedium ?? this.headingMedium,
    bodyLarge: bodyLarge ?? this.bodyLarge,
    bodyMedium: bodyMedium ?? this.bodyMedium,
    bodySmall: bodySmall ?? this.bodySmall,
    labelLarge: labelLarge ?? this.labelLarge,
    labelMedium: labelMedium ?? this.labelMedium,
    caption: caption ?? this.caption,
    quranicVerse: quranicVerse ?? this.quranicVerse,
    taqwaScore: taqwaScore ?? this.taqwaScore,
  );

  @override
  ThemeExtension<AppTypographyExtension> lerp(
    ThemeExtension<AppTypographyExtension>? other,
    double t,
  ) {
    if (other is! AppTypographyExtension) return this;
    return AppTypographyExtension(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      headingLarge: TextStyle.lerp(headingLarge, other.headingLarge, t)!,
      headingMedium: TextStyle.lerp(headingMedium, other.headingMedium, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t)!,
      labelMedium: TextStyle.lerp(labelMedium, other.labelMedium, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      quranicVerse: TextStyle.lerp(quranicVerse, other.quranicVerse, t)!,
      taqwaScore: TextStyle.lerp(taqwaScore, other.taqwaScore, t)!,
    );
  }

  /// Builds the typography scale tailored for [locale].
  /// Arabic uses Amiri / Tajawal; English uses Poppins with Tajawal fallback.
  static AppTypographyExtension fromColors(
    AppColorsExtension colors, [
    Locale locale = const Locale('ar'),
  ]) {
    final font = appFontFamily(locale);
    final fallback = appFontFamilyFallback(locale);
    return AppTypographyExtension(
      displayLarge: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colors.gold,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.3,
      ),
      headingLarge: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.3,
      ),
      headingMedium: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
        height: 1.4,
      ),
      caption: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textDim,
        height: 1.35,
      ),
      quranicVerse: TextStyle(
        fontFamily: 'Amiri',
        fontFamilyFallback: const ['Tajawal', 'NotoNaskhArabic'],
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: colors.goldLight,
        height: 2.0, // Safe line-height preventing diacritic overlap
      ),
      taqwaScore: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: colors.gold,
        height: 1.1,
      ),
    );
  }
}

/// The UI font for [locale]: Arabic renders in Amiri; other locales use Poppins.
String appFontFamily(Locale locale) =>
    locale.languageCode == 'ar' ? 'Amiri' : 'Poppins';

/// The UI body font for [locale]: Arabic keeps NotoNaskhArabic.
String appBodyFontFamily(Locale locale) =>
    locale.languageCode == 'ar' ? 'NotoNaskhArabic' : 'Poppins';

/// Fallback fonts for untranslated or mixed Arabic/Latin strings.
List<String> appFontFamilyFallback(Locale locale) =>
    const ['Tajawal', 'NotoNaskhArabic', 'Amiri'];
