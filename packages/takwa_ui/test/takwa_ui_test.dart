import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa_ui/takwa_ui.dart';

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
  });
}
