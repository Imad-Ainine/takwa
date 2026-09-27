// IslamicGlyph is the app's one icon widget: a string in, a picture out. The
// string is a *reference* — a catalogue key, an emoji, or an asset path — so
// that upgrading an icon is a catalogue edit rather than a rewrite of the ~77
// call sites that hold a persisted model field (`Dua.emoji`, `Book.emoji`,
// `AchievementDefinition.emoji`).
//
// Four behaviours matter:
//   * a registered string draws as a tintable font glyph / SVG / PNG / Lottie,
//   * anything unregistered still draws as the platform colour emoji it always
//     did — flags, time-of-day pictograms and all,
//   * a missing or unreadable asset degrades instead of blanking out or
//     throwing,
//   * every drawing carries the sizing, tint and semantics it should.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';

Widget _wrap(Widget child, {Color iconColor = const Color(0xFF123456)}) =>
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(color: iconColor),
          child: Center(child: child),
        ),
      ),
    );

/// One widget per distinct catalogue entry, keyed by the emoji it replaces.
List<IslamicGlyphEntry> get _entries =>
    islamicGlyphCatalog.values.toSet().toList();

/// The [Semantics] wrappers IslamicGlyph adds. The framework inserts its own
/// unlabelled ones, so only labelled ones count as ours.
Finder _labelsAddedBy([String? label]) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.label != null &&
      (label == null || w.properties.label == label),
);

void main() {
  group('resolution', () {
    test('a catalogue key and its emoji reach one entry', () {
      expect(
        resolveIslamicGlyph('mosque'),
        same(resolveIslamicGlyph('🕌')),
      );
      expect(
        resolveIslamicGlyph('crescent')!.source.asset,
        'assets/icons/crescent.svg',
      );
    });

    test('the catalogue maps every kind it claims to', () {
      final kinds = _entries.map((e) => e.source.kind).toSet();
      expect(kinds, containsAll(const [IslamicGlyphKind.svg, IslamicGlyphKind.icon]));
    });

    test('paths are classified by extension, multi-dot names included', () {
      expect(resolveIslamicGlyph('assets/a/b.svg')!.source.kind,
          IslamicGlyphKind.svg);
      expect(resolveIslamicGlyph('assets/a/b.anim.lottie')!.source.kind,
          IslamicGlyphKind.lottie);
      expect(resolveIslamicGlyph('assets/a/b.png')!.source.kind,
          IslamicGlyphKind.png);
    });

    test('anything else is an emoji', () {
      expect(resolveIslamicGlyph('🌿'), isNull);
      expect(resolveIslamicGlyph(''), isNull);
      expect(resolveIslamicGlyph('no/such/file.xyz'), isNull);
      expect(resolveIslamicGlyph('mosque.svg'), isNull); // a key, not a path
    });

    testWidgets('a registered emoji draws as its SVG, not as text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('🕌', size: 24)));

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.width, 24);
      expect(svg.height, 24);
    });

    testWidgets('icon-font entries draw as Icon', (tester) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('prayer', size: 18)));

      expect(tester.widget<Icon>(find.byType(Icon)).size, 18);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('unregistered strings keep rendering as colour emoji', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const Column(
          children: [
            IslamicGlyph('🌿', size: 18),
            IslamicGlyph('⭐', size: 18),
            IslamicGlyph('🇲', size: 18),
          ],
        )),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.map((t) => t.data), ['🌿', '⭐', '🇲']);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('sizing: a real icon defaults to defaultSize, emoji inherit text', (
      tester,
    ) async {
      expect(IslamicGlyph.defaultSize, 24);

      await tester.pumpWidget(
        _wrap(const DefaultTextStyle(
          style: TextStyle(fontSize: 13),
          child: Column(
            children: [IslamicGlyph('mosque'), IslamicGlyph('🌿')],
          ),
        )),
      );

      expect(
        tester.widget<SvgPicture>(find.byType(SvgPicture)).width,
        IslamicGlyph.defaultSize,
      );
      // Emoji paint with the label's size beside them rather than a box of
      // their own, which is what keeps them aligned in the rows that mix them
      // with text.
      expect(tester.widget<Text>(find.byType(Text)).style, isNull);
    });
  });

  group('colour', () {
    testWidgets('tintable sources follow the ambient icon colour', (
      tester,
    ) async {
      const ambient = Color(0xFFABCDEF);
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              IslamicGlyph('mosque', size: 20),
              IslamicGlyph('dua', size: 20),
            ],
          ),
          iconColor: ambient,
        ),
      );

      expect(
        tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter,
        const ColorFilter.mode(ambient, BlendMode.srcIn),
      );
      expect(tester.widget<Icon>(find.byType(Icon)).color, ambient);
    });

    testWidgets('an explicit colour wins over the theme', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const IslamicGlyph('mosque', size: 20, color: Color(0xFF00FF00)),
          iconColor: const Color(0xFF111111),
        ),
      );

      expect(
        tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter,
        const ColorFilter.mode(Color(0xFF00FF00), BlendMode.srcIn),
      );
    });

    testWidgets('full-colour PNG is left alone unless asked', (tester) async {
      await tester.pumpWidget(
        _wrap(const IslamicGlyph('assets/images/logo.png', size: 32)),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.color, isNull);
      expect(image.colorBlendMode, isNull);
      expect(image.width, 32);
    });

    testWidgets('a tint can be requested for a PNG', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const IslamicGlyph(
            'assets/images/logo.png',
            size: 32,
            color: Color(0xFF0000FF),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.color, const Color(0xFF0000FF));
      expect(image.colorBlendMode, BlendMode.srcIn);
    });

    testWidgets('emoji are never tinted', (tester) async {
      await tester.pumpWidget(
        _wrap(const IslamicGlyph('🌿', size: 20, color: Color(0xFF00FF00))),
      );

      expect(tester.widget<Text>(find.byType(Text)).style?.color, isNull);
    });
  });

  group('accessibility', () {
    testWidgets('a catalogue entry supplies a default label', (tester) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('kaaba', size: 24)));

      expect(
        find.descendant(
          of: _labelsAddedBy('Kaaba'),
          matching: find.byType(SvgPicture),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an explicit label wins — localised strings should be explicit', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const IslamicGlyph('kaaba', size: 24, semanticLabel: 'الكعبة')),
      );

      expect(_labelsAddedBy('الكعبة'), findsOneWidget);
      expect(_labelsAddedBy('Kaaba'), findsNothing);
    });

    testWidgets('an emoji label produces exactly one node', (tester) async {
      await tester.pumpWidget(
        _wrap(const IslamicGlyph('🌿', size: 20, semanticLabel: 'Plant')),
      );

      expect(tester.widget<Text>(find.byType(Text)).semanticsLabel, 'Plant');
      // One node, owned by the Text — not a second wrapper around it.
      expect(_labelsAddedBy(), findsOneWidget);
    });

    testWidgets('an unregistered, unlabelled emoji adds nothing to read', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('🌿', size: 20)));

      expect(_labelsAddedBy(), findsNothing);
    });

    testWidgets('a labelled composite is announced once', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const IslamicGlyph(
            'mosque',
            size: 28,
            badge: ('📍', AlignmentDirectional.topStart),
            semanticLabel: 'Masjid al-Haram',
          ),
        ),
      );

      expect(_labelsAddedBy(), findsOneWidget);
    });
  });

  group('badges', () {
    testWidgets('a badge stacks a smaller glyph in the given corner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const IslamicGlyph(
          '🌿',
          size: 28,
          badge: ('📍', AlignmentDirectional.topStart),
        )),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.map((t) => t.data), ['🌿', '📍']);
      expect(texts[0].style?.fontSize, 28);
      expect(texts[1].style?.fontSize, closeTo(28 * 1.35 * 0.42, 0.001));
      expect(
        tester.widget<Align>(find.byType(Align)).alignment,
        AlignmentDirectional.topStart,
      );
      expect(
        tester.getSize(find.byType(Stack).first).width,
        closeTo(28 * 1.35, 0.001),
      );
    });

    testWidgets('a badge may itself be a registered icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const IslamicGlyph(
          '🌿',
          size: 28,
          badge: ('🕌', AlignmentDirectional.bottomEnd),
        )),
      );

      final badge = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(badge.width, closeTo(28 * 1.35 * 0.42, 0.001));
    });
  });

  group('fallback', () {
    test('every asset-backed entry can name what it degrades to', () {
      final blind = _entries
          .where((e) => e.source.kind != IslamicGlyphKind.emoji)
          .where((e) => e.source.emoji.isEmpty)
          .map((e) => e.source.asset)
          .toList();
      expect(blind, isEmpty, reason: 'no way back if the asset is missing');
    });

    testWidgets('a registered asset paints from the bundle', (tester) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('🕌', size: 24)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The asset really resolved: an SVG that fails to decode would have been
      // replaced by its fallback emoji.
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('🕌'), findsNothing);
    });

    testWidgets('an unreadable asset draws the emoji it replaced', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const IslamicGlyph.source(
            IslamicGlyphSource.svg(
              'assets/icons/deleted-in-a-bad-checkout.svg',
              fallbackEmoji: '🕌',
            ),
            size: 24,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.byType(Text)).data, '🕌');
    });

    testWidgets('a source with nothing to fall back to draws a placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const IslamicGlyph('assets/icons/nope.svg', size: 24)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Icon>(find.byType(Icon)).icon,
        Icons.broken_image_outlined,
      );
    });

    testWidgets('Lottie is sized, unanimated on request, and never tinted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const IslamicGlyph.source(
            IslamicGlyphSource.lottie(
              'assets/lottie/lottie_ring_completion.lottie',
              fallbackEmoji: '✨',
              repeat: false,
            ),
            size: 64,
            animate: false,
            color: Color(0xFF00FF00),
          ),
        ),
      );

      final lottie = tester.widget<Lottie>(find.byType(Lottie));
      expect(lottie.width, 64);
      expect(lottie.animate, isFalse);
      expect(lottie.repeat, isFalse);
      expect(find.byType(SvgPicture), findsNothing);
    });
  });
}
