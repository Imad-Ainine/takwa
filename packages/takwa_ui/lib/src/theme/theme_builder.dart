import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';
import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_typography.dart';

/// Central theme factory for the Takwa Design System.
abstract final class AppTheme {
  AppTheme._();

  /// Default Dark Theme.
  static ThemeData dark([Locale locale = const Locale('ar')]) {
    return fromColors(AppColorsExtension.dark, Brightness.dark, locale);
  }

  /// Default Light Theme.
  static ThemeData light([Locale locale = const Locale('ar')]) {
    return fromColors(AppColorsExtension.light, Brightness.light, locale);
  }

  /// Shared theme builder used for standard light/dark modes and custom seasonal variations.
  static ThemeData fromColors(
    AppColorsExtension colors,
    Brightness brightness, [
    Locale locale = const Locale('ar'),
    Color? appBarBackground,
  ]) {
    final typography = AppTypographyExtension.fromColors(colors, locale);
    final shadows = AppShadowsExtension.fromColors(colors);
    final decorations = AppDecorationsExtension.fromColors(colors, shadows);

    return _buildTheme(
      brightness,
      colors,
      typography,
      shadows,
      decorations,
      locale,
      appBarBackground,
    );
  }

  static ThemeData _buildTheme(
    Brightness brightness,
    AppColorsExtension colors,
    AppTypographyExtension typography,
    AppShadowsExtension shadows,
    AppDecorationsExtension decorations,
    Locale locale, [
    Color? appBarBackground,
  ]) {
    final mainFont = appFontFamily(locale);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: mainFont,
      textTheme: TextTheme(
        displayLarge: typography.displayLarge,
        displayMedium: typography.displayMedium,
        headlineLarge: typography.headingLarge,
        headlineMedium: typography.headingMedium,
        headlineSmall: typography.headingMedium.copyWith(fontSize: 18),
        titleLarge: typography.headingMedium.copyWith(fontSize: 16),
        titleMedium: typography.labelLarge,
        titleSmall: typography.labelMedium,
        bodyLarge: typography.bodyLarge,
        bodyMedium: typography.bodyMedium,
        bodySmall: typography.bodySmall,
        labelLarge: typography.labelLarge,
        labelMedium: typography.labelMedium,
        labelSmall: typography.caption,
      ),
      extensions: [colors, typography, shadows, decorations],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.gold,
        onPrimary: const Color(0xFF241B05),
        secondary: colors.teal,
        onSecondary: brightness == Brightness.dark
            ? colors.background
            : Colors.white,
        surface: colors.card,
        onSurface: colors.textPrimary,
        onSurfaceVariant: colors.textSecondary,
        error: brightness == Brightness.dark
            ? colors.danger
            : colors.dangerText,
        onError: Colors.white,
        outline: colors.border,
        primaryContainer: colors.goldDim,
        onPrimaryContainer: colors.goldText,
        secondaryContainer: colors.tealDim,
        onSecondaryContainer: colors.tealText,
        tertiary: colors.success,
        onTertiary: Colors.white,
        surfaceContainerLowest: colors.background,
        surfaceContainerLow: colors.deep,
        surfaceContainer: colors.card,
        surfaceContainerHigh: colors.card2,
        surfaceContainerHighest: colors.card2,
        outlineVariant: colors.border,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: colors.textPrimary,
        onInverseSurface: colors.background,
        surfaceTint: Colors.transparent,
        errorContainer: colors.dangerDim,
        onErrorContainer: colors.dangerText,
        tertiaryContainer: colors.successDim,
        onTertiaryContainer: colors.successText,
        inversePrimary: colors.goldDark,
        surfaceDim: colors.night,
        surfaceBright: colors.card2,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: appBarBackground ?? colors.deep,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: typography.headingMedium,
        iconTheme: IconThemeData(color: colors.goldText),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: brightness,
          systemNavigationBarColor: colors.background,
          systemNavigationBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: colors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.card,
        selectedItemColor: colors.goldText,
        unselectedItemColor: colors.textDim,
        elevation: 0,
        selectedLabelStyle: typography.caption.copyWith(color: colors.goldText),
        unselectedLabelStyle: typography.caption,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.card,
        indicatorColor: colors.goldDim,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.goldText, size: 24);
          }
          return IconThemeData(color: colors.textDim, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return typography.caption.copyWith(color: colors.goldText);
          }
          return typography.caption;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.gold,
          foregroundColor: const Color(0xFF241B05),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: typography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.goldText,
          side: BorderSide(color: colors.goldText, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: typography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.tealText,
          textStyle: typography.labelMedium.copyWith(color: colors.tealText),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.successText;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: colors.border, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return colors.textDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.successText;
          return colors.border;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colors.goldText, width: 1.5),
        ),
        hintStyle: typography.bodyMedium.copyWith(color: colors.textDim),
        labelStyle: typography.labelMedium,
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.card,
        side: BorderSide(color: colors.border),
        labelStyle: typography.labelMedium,
        padding: AppSpacing.chipPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chip),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.goldText,
        linearTrackColor: colors.border,
        circularTrackColor: colors.border,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.gold,
        inactiveTrackColor: colors.border,
        thumbColor: colors.gold,
        overlayColor: colors.goldDim,
      ),
      tabBarTheme: TabBarThemeData(
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelColor: colors.goldText,
        unselectedLabelColor: colors.textDim,
        indicatorColor: colors.goldText,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: typography.labelLarge,
        unselectedLabelStyle: typography.labelMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: colors.border),
        ),
        titleTextStyle: typography.headingMedium,
        contentTextStyle: typography.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.card2,
        contentTextStyle: typography.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
