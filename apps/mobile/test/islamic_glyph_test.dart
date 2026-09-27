// IslamicGlyph is the app's one icon widget: a string in, a picture out. The
// string is a *reference* — a catalogue key, an emoji, or an asset path — so
// that upgrading an icon is a catalogue edit rather than a rewrite of the ~77
// call sites that hold a persisted model field (`Dua.emoji`, `Book.emoji`,
// `AchievementDefinition.emoji`).
//
// Four behaviours matter:
//   * a registered string draws as a tintable font glyph / SVG / PNG / Lottie,
//   * an unregistered emoji draws as its Noto 3D render when one ships, and as
//     the platform colour emoji it always was when one does not,
//   * a missing or unreadable asset degrades instead of blanking out or
//     throwing,
//   * every drawing carries the sizing, tint and semantics it should.
//
// Fixtures are built from codepoints rather than literals: some emoji do not
// survive an editor round-trip, and a silently-dropped glyph would turn these
// into tests of nothing.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';
import 'package:takwa/core/widgets/islamic_glyph_emoji3d.dart';

// No render ships for these, so they must stay colour emoji.
final _noRender = String.fromCharCodes([0x1f3af]); // direct hit
final _noRender2 = String.fromCharCodes([0x2757]); // exclamation mark
// These do have renders in assets/emoji3d/.
final _hasRender = String.fromCharCodes([0x1f33f]); // herb
final _hiRes = String.fromCharCodes([0x2728]); // sparkles, also shipped at 512

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
    test('a semantic catalogue key resolves to its line-art entry', () {
      expect(resolveIslamicGlyph('mosque')!.source.kind, IslamicGlyphKind.svg);
      expect(
        resolveIslamicGlyph('crescent')!.source.asset,
        'assets/icons/crescent.svg',
      );
      // A literal emoji no longer shares the catalogue entry — it upgrades
      // to the shipped 3D render instead. The fallback still names the same
      // emoji, so a missing PNG draws what it replaced.
      final viaEmoji = resolveIslamicGlyph('🕌');
      expect(viaEmoji!.source.kind, IslamicGlyphKind.png);
      expect(viaEmoji.source.emoji, '🕌');
    });

    test('the catalogue maps every kind it claims to', () {
      final kinds = _entries.map((e) => e.source.kind).toSet();
      expect(
        kinds,
        containsAll(const [IslamicGlyphKind.svg, IslamicGlyphKind.icon]),
      );
    });

    test('paths are classified by extension, multi-dot names included', () {
      expect(
        resolveIslamicGlyph('assets/a/b.svg')!.source.kind,
        IslamicGlyphKind.svg,
      );
      expect(
        resolveIslamicGlyph('assets/a/b.anim.lottie')!.source.kind,
        IslamicGlyphKind.lottie,
      );
      expect(
        resolveIslamicGlyph('assets/a/b.png')!.source.kind,
        IslamicGlyphKind.png,
      );
    });

    test('anything else is an emoji', () {
      expect(resolveIslamicGlyph(_noRender), isNull);
      expect(resolveIslamicGlyph(''), isNull);
      expect(resolveIslamicGlyph('no/such/file.xyz'), isNull);
      expect(resolveIslamicGlyph('mosque.svg'), isNull); // a key, not a path
    });

    testWidgets('a semantic key draws its registered SVG, not as text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('mosque', size: 24)));

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.width, 24);
      expect(svg.height, 24);
    });

    testWidgets('a literal emoji with a 3D render draws the PNG, not as text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('🕌', size: 24)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      final img = tester.widget<Image>(find.byType(Image));
      expect(img.width, 24);
      expect(img.height, 24);
    });

    testWidgets('icon-font entries draw as Icon', (tester) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('prayer', size: 18)));

      expect(tester.widget<Icon>(find.byType(Icon)).size, 18);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('an emoji with no render shipped stays a colour emoji', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              IslamicGlyph(_noRender, size: 18),
              IslamicGlyph(_noRender2, size: 18),
              const IslamicGlyph('🇲', size: 18),
            ],
          ),
        ),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.map((t) => t.data), [_noRender, _noRender2, '🇲']);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('an emoji with a render shipped draws it instead', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(IslamicGlyph(_hasRender, size: 18)));
      await tester.pumpAndSettle();

      // Proves the asset resolved, not that it decoded: an Image that cannot
      // load its asset swaps itself for the fallback Text via errorBuilder, so
      // finding no Text here means the bundle had the PNG. Pixels are covered
      // by the goldens, which need runAsync to let the codec finish.
      expect(tester.takeException(), isNull);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 18);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('a semantic catalogue key wins over a 3D render', (
      tester,
    ) async {
      // 'mosque' picks the tintable line art even though 🕌 has a PNG on disk,
      // because call sites that use the semantic name want chrome icons.
      await tester.pumpWidget(_wrap(const IslamicGlyph('mosque', size: 18)));

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    test(
      'the slug drops U+FE0F and keeps ZWJ, matching upstream filenames',
      () {
        expect(emoji3dSlug(String.fromCharCodes([0x2728])), '2728');
        expect(emoji3dSlug(String.fromCharCodes([0x2694, 0xfe0f])), '2694');
        expect(
          emoji3dSlug(
            String.fromCharCodes([0x1f468, 0x200d, 0x1f469, 0x200d, 0x1f467]),
          ),
          '1f468_200d_1f469_200d_1f467',
        );
        // Not a bare emoji at all.
        expect(emoji3dSlug('۞'), isNull);
        expect(emoji3dSlug('mosque'), isNull);
        // A real emoji whose render was never downloaded.
        expect(emoji3dSlug(_noRender), isNull);
      },
    );

    testWidgets(
      'sizing: a real icon defaults to defaultSize, emoji inherit text',
      (tester) async {
        expect(IslamicGlyph.defaultSize, 24);

        await tester.pumpWidget(
          _wrap(
            DefaultTextStyle(
              style: const TextStyle(fontSize: 13),
              child: Column(
                children: [
                  const IslamicGlyph('mosque'),
                  IslamicGlyph(_noRender),
                ],
              ),
            ),
          ),
        );

        expect(
          tester.widget<SvgPicture>(find.byType(SvgPicture)).width,
          IslamicGlyph.defaultSize,
        );
        // Emoji paint with the label's size beside them rather than a box of
        // their own, which is what keeps them aligned in the rows that mix them
        // with text.
        expect(tester.widget<Text>(find.byType(Text)).style, isNull);
      },
    );

    testWidgets('a 3D render with no size takes the ambient text size', (
      tester,
    ) async {
      // It replaced an emoji, so it has to land where the emoji landed or every
      // row it appears in shifts.
      await tester.pumpWidget(
        _wrap(
          DefaultTextStyle(
            style: const TextStyle(fontSize: 13),
            child: IslamicGlyph(_hasRender),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 13);
      expect(image.height, 13);
    });

    testWidgets('a 3D render swaps to its 512 source once the box is large', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(IslamicGlyph(_hiRes, size: 18)));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image.toString(), contains('emoji_u2728.png'));
      expect(image.image.toString(), isNot(contains('512')));

      await tester.pumpWidget(_wrap(IslamicGlyph(_hiRes, size: 64)));
      expect(
        tester.widget<Image>(find.byType(Image)).image.toString(),
        contains('512/emoji_u2728.png'),
      );
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
        _wrap(
          IslamicGlyph(_noRender, size: 20, color: const Color(0xFF00FF00)),
        ),
      );

      expect(tester.widget<Text>(find.byType(Text)).style?.color, isNull);
    });

    testWidgets('a 3D render does not pick up the ambient tint', (
      tester,
    ) async {
      // The trade the set is bought with: full-colour art cannot follow the
      // gold IconTheme, so nothing is applied to it unless asked for.
      await tester.pumpWidget(_wrap(IslamicGlyph(_hasRender, size: 20)));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.color, isNull);
      expect(image.colorBlendMode, isNull);
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

    testWidgets(
      'an explicit label wins — localised strings should be explicit',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const IslamicGlyph('kaaba', size: 24, semanticLabel: 'الكعبة')),
        );

        expect(_labelsAddedBy('الكعبة'), findsOneWidget);
        expect(_labelsAddedBy('Kaaba'), findsNothing);
      },
    );

    testWidgets('an emoji label produces exactly one node', (tester) async {
      await tester.pumpWidget(
        _wrap(IslamicGlyph(_noRender, size: 20, semanticLabel: 'Target')),
      );

      expect(tester.widget<Text>(find.byType(Text)).semanticsLabel, 'Target');
      // One node, owned by the Text — not a second wrapper around it.
      expect(_labelsAddedBy(), findsOneWidget);
    });

    testWidgets('an unregistered, unlabelled emoji adds nothing to read', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(IslamicGlyph(_noRender, size: 20)));

      expect(_labelsAddedBy(), findsNothing);
    });

    testWidgets('a 3D render is silent until given a label', (tester) async {
      // It has no catalogue entry, so there is no English description to fall
      // back on either — the picture is decorative until a call site names it.
      await tester.pumpWidget(_wrap(IslamicGlyph(_hasRender, size: 20)));

      expect(_labelsAddedBy(), findsNothing);
      expect(find.byType(Image), findsOneWidget);
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
        _wrap(
          IslamicGlyph(
            _noRender,
            size: 28,
            badge: (_noRender2, AlignmentDirectional.topStart),
          ),
        ),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.map((t) => t.data), [_noRender, _noRender2]);
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
        _wrap(
          IslamicGlyph(
            _noRender,
            size: 28,
            badge: ('mosque', AlignmentDirectional.bottomEnd),
          ),
        ),
      );

      final badge = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(badge.width, closeTo(28 * 1.35 * 0.42, 0.001));
    });

    testWidgets('a badge may be a 3D render too', (tester) async {
      await tester.pumpWidget(
        _wrap(
          IslamicGlyph(
            'mosque',
            size: 28,
            badge: (_hasRender, AlignmentDirectional.bottomEnd),
          ),
        ),
      );

      expect(
        tester.widget<Image>(find.byType(Image)).width,
        closeTo(28 * 1.35 * 0.42, 0.001),
      );
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

    test('every shipped 3D slug has the PNGs it advertises', () {
      // The generated lists are only as good as the directory they came from;
      // a 512 with no 128 counterpart would resolve to a missing asset.
      for (final slug in kEmoji3dShipped) {
        expect(
          File('assets/emoji3d/emoji_u$slug.png').existsSync(),
          isTrue,
          reason: '128 render missing for $slug',
        );
      }
      for (final slug in kEmoji3dHiRes) {
        expect(kEmoji3dShipped, contains(slug));
        expect(
          File('assets/emoji3d/512/emoji_u$slug.png').existsSync(),
          isTrue,
          reason: '512 render missing for $slug',
        );
      }
      expect(kEmoji3dShipped, isNotEmpty);
    });

    test('a 3D render names the emoji it degrades to', () {
      // Auto-mapped sources carry their own emoji as the fallback, so a PNG
      // that fails to decode draws exactly what it replaced.
      expect(resolveIslamicGlyph(_hasRender)!.source.emoji, _hasRender);
      expect(resolveIslamicGlyph(_hasRender)!.source.followsTextSize, isTrue);
      expect(resolveIslamicGlyph(_hasRender)!.source.tintable, isFalse);
    });

    testWidgets('a registered semantic asset paints from the bundle', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('mosque', size: 24)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The SVG really resolved: an SVG that fails to decode would have been
      // replaced by its fallback emoji.
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('🕌'), findsNothing);
    });

    testWidgets('a shipped 3D emoji PNG paints from the bundle', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const IslamicGlyph('🕌', size: 24)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The 3D PNG really resolved: a missing asset would have fallen back
      // to the plain colour emoji.
      expect(find.byType(Image), findsOneWidget);
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
