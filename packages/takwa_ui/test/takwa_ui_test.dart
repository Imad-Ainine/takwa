import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa_ui/takwa_ui.dart';

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Text-role colors that must stay legible on card surfaces.
Map<String, Color> textRoles(AppColorsExtension c) => {
      'goldText': c.goldText,
      'tealText': c.tealText,
      'successText': c.successText,
      'warningText': c.warningText,
      'dangerText': c.dangerText,
      'infoText': c.infoText,
      'textPrimary': c.textPrimary,
      'textSecondary': c.textSecondary,
    };

/// Foreground/background pairs for solid brand fills.
Map<String, ({Color foreground, Color fill})> onColorPairs(AppColorsExtension c) => {
      'onGold': (foreground: c.onGold, fill: c.gold),
      'onTeal': (foreground: c.onTeal, fill: c.teal),
      'onSuccess': (foreground: c.onSuccess, fill: c.success),
      'onDanger': (foreground: c.onDanger, fill: c.danger),
      'onWarning': (foreground: c.onWarning, fill: c.warning),
      'onInfo': (foreground: c.onInfo, fill: c.info),
    };

/// Roles added by the Polaris/Carbon-style semantic interaction layer.
Map<String, Color> interactionRoles(AppColorsExtension c) => {
      'info': c.info,
      'infoDim': c.infoDim,
      'infoText': c.infoText,
      'onGold': c.onGold,
      'onTeal': c.onTeal,
      'onSuccess': c.onSuccess,
      'onDanger': c.onDanger,
      'onWarning': c.onWarning,
      'onInfo': c.onInfo,
      'primaryHover': c.primaryHover,
      'primaryPressed': c.primaryPressed,
      'primaryDisabled': c.primaryDisabled,
      'onPrimaryDisabled': c.onPrimaryDisabled,
      'secondaryHover': c.secondaryHover,
      'secondaryPressed': c.secondaryPressed,
      'surfaceSubdued': c.surfaceSubdued,
      'surfaceHovered': c.surfaceHovered,
      'surfacePressed': c.surfacePressed,
      'surfaceInverse': c.surfaceInverse,
      'onSurfaceInverse': c.onSurfaceInverse,
      'borderSubdued': c.borderSubdued,
      'borderHover': c.borderHover,
      'borderStrong': c.borderStrong,
      'focusRing': c.focusRing,
      'overlay': c.overlay,
      'disabledBackground': c.disabledBackground,
      'disabledContent': c.disabledContent,
    };

void main() {
  group('Takwa Design System Tokens', () {
    test('AppSpacing scale conforms to 4dp/8dp grid', () {
      expect(AppSpacing.xxs, 2.0);
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 20.0);
      expect(AppSpacing.xxl, 24.0);
      expect(AppSpacing.xxxl, 32.0);
      expect(AppSpacing.huge, 48.0);
    });

    test('AppRadius tokens conform to curvature scale', () {
      expect(AppRadius.xs, 4.0);
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.full, 999.0);
    });

    test('Theme extensions lerp cleanly without null crashes', () {
      const dark = AppColorsExtension.dark;
      const light = AppColorsExtension.light;
      final mid = dark.lerp(light, 0.5) as AppColorsExtension;

      expect(mid.gold, isNotNull);
      expect(mid.goldText, isNotNull);
      expect(mid.tealText, isNotNull);
      expect(mid.background, isNotNull);
    });

    test('AppTheme generates valid light and dark ThemeData', () {
      final darkTheme = AppTheme.dark();
      final lightTheme = AppTheme.light();

      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.extension<AppColorsExtension>(), isNotNull);
      expect(darkTheme.extension<AppTypographyExtension>(), isNotNull);
      expect(darkTheme.extension<AppShadowsExtension>(), isNotNull);
      expect(darkTheme.extension<AppDecorationsExtension>(), isNotNull);
    });
  });

  group('Takwa Palette Primitives', () {
    const ramps = <String, List<Color>>{
      'neutral': AppPalette.neutral,
      'gold': AppPalette.gold,
      'teal': AppPalette.teal,
      'green': AppPalette.green,
      'red': AppPalette.red,
      'yellow': AppPalette.yellow,
      'blue': AppPalette.blue,
    };

    test('every ramp has ten steps ordered 50 to 900', () {
      for (final entry in ramps.entries) {
        expect(entry.value.length, 10, reason: '${entry.key} ramp length');
      }
    });

    test('ramps are tonally monotonic (lightening step index lowers luminance)', () {
      for (final entry in ramps.entries) {
        for (var i = 1; i < entry.value.length; i++) {
          expect(
            entry.value[i].computeLuminance(),
            lessThanOrEqualTo(entry.value[i - 1].computeLuminance() + 0.001),
            reason: '${entry.key}[$i] should not be lighter than [${i - 1}]',
          );
        }
      }
    });

    test('step 500 anchors each ramp to its brand color', () {
      expect(AppPalette.gold500, const Color(0xFFC8A96E));
      expect(AppPalette.teal500, const Color(0xFF3AAFA9));
      expect(AppPalette.green500, const Color(0xFF4CAF7D));
      expect(AppPalette.red500, const Color(0xFFE07070));
      expect(AppPalette.yellow500, const Color(0xFFE0A044));
    });
  });

  group('Semantic role contrast (WCAG)', () {
    final themes = <String, AppColorsExtension>{
      'dark': AppTheme.dark().extension<AppColorsExtension>()!,
      'light': AppTheme.light().extension<AppColorsExtension>()!,
      'ramadanDark': RamadanTheme.dark().extension<AppColorsExtension>()!,
      'ramadanLight': RamadanTheme.light().extension<AppColorsExtension>()!,
    };

    for (final theme in themes.entries) {
      test('${theme.key}: *Text roles clear 4.5:1 on card', () {
        for (final entry in textRoles(theme.value).entries) {
          expect(
            contrastRatio(entry.value, theme.value.card),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.key}.${entry.key} on card',
          );
        }
      });

      test('${theme.key}: on-colors clear 4.5:1 on their fills', () {
        for (final entry in onColorPairs(theme.value).entries) {
          expect(
            contrastRatio(entry.value.foreground, entry.value.fill),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.key}.${entry.key}',
          );
        }
      });

      test('${theme.key}: focus ring clears the WCAG 2.2 3:1 non-text minimum', () {
        expect(
          contrastRatio(theme.value.focusRing, theme.value.card),
          greaterThanOrEqualTo(3.0),
        );
      });
    }
  });

  group('Semantic interaction layer', () {
    test('copyWith carries every new role and applies overrides', () {
      const base = AppColorsExtension.dark;
      expect(interactionRoles(base.copyWith()), interactionRoles(base));

      final overridden = base.copyWith(focusRing: Colors.black, infoText: Colors.white);
      expect(overridden.focusRing, Colors.black);
      expect(overridden.infoText, Colors.white);
      expect(overridden.gold, base.gold);
    });

    test('lerp blends every new role without nulls', () {
      const dark = AppColorsExtension.dark;
      const light = AppColorsExtension.light;
      final mid = dark.lerp(light, 0.5) as AppColorsExtension;

      final fromDark = interactionRoles(dark);
      final fromLight = interactionRoles(light);
      final blended = interactionRoles(mid);

      expect(blended.keys, fromDark.keys);
      for (final entry in blended.entries) {
        final a = fromDark[entry.key]!;
        final b = fromLight[entry.key]!;
        if (a != b) {
          expect(
            entry.value == a || entry.value == b,
            isFalse,
            reason: '${entry.key} should be blended, not snapped to an endpoint',
          );
        }
      }
    });

    test('AppTheme wires hover/pressed/disabled states into button schemes', () {
      const dark = AppColorsExtension.dark;
      final style = AppTheme.dark().elevatedButtonTheme.style!;

      expect(style.backgroundColor?.resolve(const <WidgetState>{}), dark.gold);
      expect(style.backgroundColor?.resolve(const <WidgetState>{WidgetState.hovered}), dark.primaryHover);
      expect(style.backgroundColor?.resolve(const <WidgetState>{WidgetState.pressed}), dark.primaryPressed);
      expect(style.backgroundColor?.resolve(const <WidgetState>{WidgetState.disabled}), dark.primaryDisabled);
      expect(style.foregroundColor?.resolve(const <WidgetState>{}), dark.onGold);

      final outlined = AppTheme.dark().outlinedButtonTheme.style!;
      expect(
        outlined.side?.resolve(const <WidgetState>{WidgetState.hovered})?.color,
        dark.borderHover,
      );
    });

    test('AppTheme maps on-colors into the Material ColorScheme', () {
      final scheme = AppTheme.dark().colorScheme;
      const dark = AppColorsExtension.dark;

      expect(scheme.onPrimary, dark.onGold);
      expect(scheme.onSecondary, dark.onTeal);
      expect(scheme.onError, dark.onDanger);
      expect(scheme.scrim, dark.overlay);
      expect(scheme.inverseSurface, dark.surfaceInverse);
    });

    test('input theme uses the focus ring for its focused border', () {
      final scheme = AppTheme.dark().extension<AppColorsExtension>()!;
      final border =
          AppTheme.dark().inputDecorationTheme.focusedBorder! as OutlineInputBorder;
      expect(border.borderSide.color, scheme.focusRing);
      expect(border.borderSide.width, greaterThanOrEqualTo(2.0));
    });
  });

  group('Takwa UI Components', () {
    Widget buildTestHarness(Widget child, {bool isDark = true}) {
      return MaterialApp(
        theme: isDark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('TakwaButton renders and respects minimum 48dp height', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestHarness(
          TakwaButton(
            text: 'تسجيل الصلاة',
            onPressed: () => tapped = true,
          ),
        ),
      );

      final buttonFinder = find.byType(TakwaButton);
      expect(buttonFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(buttonFinder);
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('TakwaButton shows loader and ignores taps when isLoading', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestHarness(
          TakwaButton(
            text: 'تحميل',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(TakwaButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapped, isFalse);
    });

    testWidgets('TakwaIconButton satisfies minimum 48x48dp touch bounds', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          const TakwaIconButton(
            icon: Icon(Icons.bookmark),
            tooltip: 'Bookmark',
          ),
        ),
      );

      final iconButtonFinder = find.byType(TakwaIconButton);
      expect(iconButtonFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(iconButtonFinder);
      expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('TakwaCard and TakwaHighlightCard render children', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          const Column(
            children: [
              TakwaCard(child: Text('Standard Card')),
              TakwaHighlightCard(child: Text('Highlight Card')),
            ],
          ),
        ),
      );

      expect(find.text('Standard Card'), findsOneWidget);
      expect(find.text('Highlight Card'), findsOneWidget);
    });

    testWidgets('TakwaTextField displays label and error state', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          const TakwaTextField(
            label: 'البريد الإلكتروني',
            hint: 'name@example.com',
            errorText: 'الحقل مطلوب',
          ),
        ),
      );

      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('الحقل مطلوب'), findsOneWidget);
    });

    testWidgets('AyahText renders Arabic numerals and verse text in RTL', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          const AyahText(
            text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            ayahNumber: 1,
          ),
        ),
      );

      final ayahFinder = find.byType(AyahText);
      expect(ayahFinder, findsOneWidget);

      // Verify Arabic numeral conversion (1 -> ١)
      expect(find.textContaining('١'), findsOneWidget);

      final directionality = tester.widget<Directionality>(
        find.descendant(of: ayahFinder, matching: find.byType(Directionality)),
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('TakwaChip triggers onTap callback', (tester) async {
      bool chipSelected = false;

      await tester.pumpWidget(
        buildTestHarness(
          TakwaChip(
            label: 'الفجر',
            isSelected: false,
            onTap: () => chipSelected = true,
          ),
        ),
      );

      expect(find.text('الفجر'), findsOneWidget);
      await tester.tap(find.byType(TakwaChip));
      await tester.pumpAndSettle();
      expect(chipSelected, isTrue);
    });

    testWidgets('DesignSystemShowcase renders every token layer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark(), home: const DesignSystemShowcase()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Takwa Design System'), findsOneWidget);
      expect(find.text('Color palettes'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Components'), 300);
      expect(find.text('Components'), findsOneWidget);
    });

    testWidgets('DesignSystemShowcase reaches its last row on a phone viewport', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark(), home: const DesignSystemShowcase()),
      );
      await tester.pumpAndSettle();

      final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      expect(position.maxScrollExtent, greaterThan(0));

      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();

      final lastRow = tester.getRect(find.text('surfaceHovered + borderHover'));
      expect(lastRow.bottom, lessThanOrEqualTo(position.viewportDimension + position.minScrollExtent));
      expect(tester.takeException(), isNull);
    });
  });
}
