import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import 'islamic_glyph_catalog.dart';

export 'islamic_glyph_catalog.dart';

/// The one icon widget in the app.
///
/// [glyph] is a reference, not the picture. It is looked up in
/// [islamicGlyphCatalog] as a name (`'mosque'`) or as the emoji it replaces
/// (`'🕌'`), then as an asset path, then as a Noto 3D render under
/// `assets/emoji3d/`, and only then treated as a plain emoji. That indirection
/// exists because most call sites hold a string from a persisted model field —
/// `Dua.emoji`, `Book.emoji`, `AchievementDefinition.emoji` — so upgrading an
/// icon is a catalogue edit, not a rewrite of the ~87 call sites, and an
/// unresolvable string keeps drawing exactly as it always did.
///
/// The three layers differ in one important way. A catalogue entry is line art
/// or a font glyph, so it takes the app's icon colour. A 3D render is full
/// colour and cannot be tinted — it buys OS-to-OS consistency at that cost, and
/// sizes itself to the surrounding text the way the emoji it replaced did. That
/// is also why the order is fixed: where the two overlap, the hand-drawn icon
/// wins, because a tintable mark is what the gold line-art set exists to give.
///
/// ```dart
/// IslamicGlyph('mosque', size: 18)                                  // registered
/// IslamicGlyph('assets/icons/mosque.svg', size: 18)                  // by path
/// IslamicGlyph('assets/lottie/ring.lottie', size: 64, animate: false)
/// IslamicGlyph('✨')                                                 // 3D render
/// IslamicGlyph('🕌', size: 24, color: context.colors.gold,
///              semanticLabel: l10n.prayerTimes)
/// IslamicGlyph(book.emoji, size: 40, badge: ('📍', AlignmentDirectional.topStart))
/// ```
class IslamicGlyph extends StatelessWidget {
  const IslamicGlyph(
    this.glyph, {
    super.key,
    this.size,
    this.badge,
    this.color,
    this.semanticLabel,
    this.animate = true,
  }) : source = null;

  /// For an icon used in exactly one place, where the catalogue has no entry
  /// for it and a path alone cannot say what it needs — a Lottie that plays
  /// once, say, or a raster with the emoji to fall back on.
  const IslamicGlyph.source(
    this.source, {
    super.key,
    this.size,
    this.badge,
    this.color,
    this.semanticLabel,
    this.animate = true,
  }) : glyph = '';

  /// Used by [Text], [Icon], SVG and raster alike, and as the badge scale.
  static const double defaultSize = 24;

  /// A catalogue key, an asset path, or an emoji. Empty when [source] is given.
  final String glyph;

  /// Set by [IslamicGlyph.source] to skip the catalogue lookup entirely.
  final IslamicGlyphSource? source;

  /// Square box for a registered icon. Defaults to [defaultSize]; emoji fall
  /// back to the ambient text style so they still match adjacent labels.
  final double? size;

  /// Second icon stacked on [glyph] for composite marks (mosque+pin,
  /// kaaba+compass), paired with the corner it sits in. Resolved exactly like
  /// [glyph], so a badge may be an asset too.
  final (String, AlignmentGeometry)? badge;

  /// Tint for tintable sources. When omitted, a registered icon follows the
  /// ambient [IconTheme] colour the same way [Icon] does, and full-colour art
  /// is left alone. Has no effect on emoji or Lottie.
  final Color? color;

  /// Screen-reader text. Wins over the catalogue's own description; pass a
  /// localized string here where one exists.
  final String? semanticLabel;

  /// Freezes Lottie on its first frame. Ignored by every other kind.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final entry = source == null ? resolveIslamicGlyph(glyph) : null;
    final resolved =
        source ?? entry?.source ?? IslamicGlyphSource.emoji(glyph);
    final isEmoji = resolved.kind == IslamicGlyphKind.emoji;
    // Emoji keep inheriting the ambient text size so they match the label
    // beside them. An auto-mapped emoji render has to do the same or it would
    // change the row it sits in; every hand-registered icon takes a definite
    // square box so it stays consistent across screens.
    final box =
        size ??
        (isEmoji
            ? null
            : resolved.followsTextSize
            ? _ambientSize(context)
            : defaultSize);
    final label = semanticLabel ?? entry?.description;

    Widget icon = _paint(context, resolved, box, label);
    if (badge != null) {
      final outer = (box ?? defaultSize) * 1.35;
      icon = SizedBox(
        width: outer,
        height: outer,
        child: Stack(
          children: [
            Center(child: icon),
            Align(
              alignment: badge!.$2,
              child: IslamicGlyph(
                badge!.$1,
                size: outer * 0.42,
                color: color,
                animate: animate,
              ),
            ),
          ],
        ),
      );
    }
    if (label == null || resolved.kind == IslamicGlyphKind.emoji) return icon;
    return Semantics(label: label, child: icon);
  }

  Widget _paint(
    BuildContext context,
    IslamicGlyphSource src,
    double? box,
    String? label,
  ) {
    final tint = color ?? (src.tintable ? _ambientColor(context) : null);
    final onError = _fallbackFor(context, src, box);

    // Every painter below owns its own box so that an SVG, a font glyph and a
    // raster at `size: 18` occupy the same 18×18 square. None of them claims a
    // semantics node: [build] wraps the result when a label exists, which
    // keeps a labelled icon to exactly one node and an unlabelled one to none.
    return switch (src.kind) {
      IslamicGlyphKind.emoji => Text(
        src.emoji,
        semanticsLabel: label,
        style: box == null ? null : TextStyle(fontSize: box),
      ),
      IslamicGlyphKind.icon => Icon(src.icon, size: box, color: tint),
      IslamicGlyphKind.svg => SvgPicture.asset(
        src.asset,
        width: box,
        height: box,
        colorFilter: tint == null
            ? null
            : ColorFilter.mode(tint, BlendMode.srcIn),
        excludeFromSemantics: true,
        errorBuilder: onError,
      ),
      IslamicGlyphKind.png => Image.asset(
        (box != null && box >= kGlyphHiResFrom && src.hiResAsset.isNotEmpty)
            ? src.hiResAsset
            : src.asset,
        width: box,
        height: box,
        color: tint,
        colorBlendMode: tint == null ? null : BlendMode.srcIn,
        excludeFromSemantics: true,
        errorBuilder: onError,
      ),
      IslamicGlyphKind.lottie => Lottie.asset(
        src.asset,
        width: box,
        height: box,
        animate: animate,
        repeat: src.repeat,
        errorBuilder: onError,
      ),
    };
  }

  /// A missing or corrupt asset must not blank out a row, and must not throw
  /// the way the default `errorBuilder` does inside a release-mode widget test.
  /// Every registered source names the emoji it degrades to; a path-only source
  /// has nothing to go back to, so it draws a placeholder instead.
  Widget Function(BuildContext, Object, StackTrace?) _fallbackFor(
    BuildContext context,
    IslamicGlyphSource src,
    double? box,
  ) {
    return (context, error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'IslamicGlyph: could not load ${src.asset} ($error); '
          'fell back to ${src.emoji.isEmpty ? 'a placeholder' : src.emoji}.',
        );
      }
      if (src.emoji.isEmpty) {
        return Icon(
          Icons.broken_image_outlined,
          size: box,
          color: _ambientColor(context),
        );
      }
      return Text(
        src.emoji,
        style: box == null ? null : TextStyle(fontSize: box),
      );
    };
  }

  static Color _ambientColor(BuildContext context) =>
      IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;

  /// What an emoji would have been laid out at, which is the row's text size
  /// rather than the ambient [IconTheme] — that one merges in the theme's 24px
  /// and would inflate every label-sized glyph.
  static double _ambientSize(BuildContext context) =>
      DefaultTextStyle.of(context).style.fontSize ??
      IconTheme.of(context).size ??
      defaultSize;
}
