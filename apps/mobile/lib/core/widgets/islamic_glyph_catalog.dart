import 'package:flutter/widgets.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

/// How an [IslamicGlyph] gets its pixels.
///
/// The app's icon slots are fed plain strings — persisted model fields such as
/// `Dua.emoji`, `Book.emoji`, `AchievementDefinition.emoji`, plus string
/// arguments on private row widgets — so the string is a *reference* to a
/// source rather than the source itself. [resolveIslamicGlyph] turns it into
/// one of these.
enum IslamicGlyphKind {
  /// The platform's colour emoji. Always available, never tintable, and the
  /// box it lays out is the font's line box rather than `size × size`.
  emoji,

  /// A glyph from an icon font (`flutter_islamic_icons`, Material). Scales,
  /// tints, costs no asset bytes.
  icon,

  /// A vector asset. Tinted by default: these ship as single-colour line art
  /// drawn on the same 24×24 grid and stroke weight as the icon fonts, so an
  /// SVG and a font glyph at the same `size` read as one family.
  svg,

  /// A raster asset (`.png`/`.jpg`/`.webp`). Full colour by default — pass an
  /// explicit `color:` at the call site to tint it.
  png,

  /// A Lottie animation (`.lottie`/`.json`). Carries its own colours, so it
  /// cannot be tinted.
  lottie,
}

/// One icon's paint recipe. Build one with a named constructor; every kind
/// except [IslamicGlyphSource.emoji] also carries the emoji it degrades to when
/// its asset is missing or fails to decode.
@immutable
class IslamicGlyphSource {
  const IslamicGlyphSource._({
    required this.kind,
    required this.emoji,
    required this.icon,
    required this.asset,
    required this.tintable,
    required this.repeat,
  });

  const IslamicGlyphSource.emoji(String char)
    : this._(
        kind: IslamicGlyphKind.emoji,
        emoji: char,
        icon: null,
        asset: '',
        tintable: false,
        repeat: true,
      );

  const IslamicGlyphSource.icon(
    IconData glyph, {
    String fallbackEmoji = '',
  }) : this._(
         kind: IslamicGlyphKind.icon,
         emoji: fallbackEmoji,
         icon: glyph,
         asset: '',
         tintable: true,
         repeat: true,
       );

  const IslamicGlyphSource.svg(
    String path, {
    String fallbackEmoji = '',
    bool tintable = true,
  }) : this._(
         kind: IslamicGlyphKind.svg,
         emoji: fallbackEmoji,
         icon: null,
         asset: path,
         tintable: tintable,
         repeat: true,
       );

  const IslamicGlyphSource.png(
    String path, {
    String fallbackEmoji = '',
    bool tintable = false,
  }) : this._(
         kind: IslamicGlyphKind.png,
         emoji: fallbackEmoji,
         icon: null,
         asset: path,
         tintable: tintable,
         repeat: true,
       );

  const IslamicGlyphSource.lottie(
    String path, {
    String fallbackEmoji = '',
    bool repeat = true,
  }) : this._(
         kind: IslamicGlyphKind.lottie,
         emoji: fallbackEmoji,
         icon: null,
         asset: path,
         tintable: false,
         repeat: repeat,
       );

  final IslamicGlyphKind kind;

  /// Rendered instead of this source when it cannot be painted. Empty means
  /// "there is nothing sensible to fall back to" and draws a placeholder.
  final String emoji;
  final IconData? icon;
  final String asset;

  /// Whether an absent `color:` at the call site still picks up the ambient
  /// icon colour. False for full-colour art, which would lose its meaning.
  final bool tintable;
  final bool repeat;
}

/// A registered icon: where it comes from, and what to call it out loud.
@immutable
class IslamicGlyphEntry {
  const IslamicGlyphEntry(this.source, {this.description});

  final IslamicGlyphSource source;

  /// Default screen-reader text. English, because the catalogue is a `const`
  /// map and cannot reach `AppLocalizations` — a call site that has a
  /// localized string should pass `semanticLabel:` and win.
  final String? description;
}

const _mosque = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/mosque.svg', fallbackEmoji: '🕌'),
  description: 'Mosque',
);
const _crescent = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/crescent.svg', fallbackEmoji: '🌙'),
  description: 'Crescent moon',
);
const _dawn = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/dawn.svg', fallbackEmoji: '🌅'),
  description: 'Dawn',
);
const _midday = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/midday.svg', fallbackEmoji: '☀️'),
  description: 'Midday',
);
const _afternoon = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/afternoon.svg', fallbackEmoji: '🌇'),
  description: 'Late afternoon',
);
const _sunset = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/sunset.svg', fallbackEmoji: '🌆'),
  description: 'Sunset',
);
const _night = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/night.svg', fallbackEmoji: '🌃'),
  description: 'Night',
);
const _prayer = IslamicGlyphEntry(
  IslamicGlyphSource.icon(FlutterIslamicIcons.prayer, fallbackEmoji: '🤲'),
  description: 'Prayer',
);
const _dua = IslamicGlyphEntry(
  IslamicGlyphSource.icon(FlutterIslamicIcons.takbir, fallbackEmoji: '🤲'),
  description: 'Raised hands in supplication',
);
const _beads = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/prayer-beads.svg', fallbackEmoji: '📿'),
  description: 'Prayer beads',
);
const _book = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/open-book.svg', fallbackEmoji: '📖'),
  description: 'Open book',
);
const _books = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/book-stack.svg', fallbackEmoji: '📚'),
  description: 'Bookshelf',
);
const _kaaba = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/kaaba.svg', fallbackEmoji: '🕋'),
  description: 'Kaaba',
);
const _compass = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/qibla-compass.svg', fallbackEmoji: '🧭'),
  description: 'Compass',
);
const _lantern = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/lantern.svg', fallbackEmoji: '🏮'),
  description: 'Ramadan lantern',
);
const _rubElHizb = IslamicGlyphEntry(
  IslamicGlyphSource.svg('assets/icons/rub-el-hizb.svg', fallbackEmoji: '۞'),
  description: 'Rub el Hizb',
);

/// The icon catalogue: a semantic key, the emoji it replaces, and sometimes a
/// prayer-time alias, all pointing at the same entry.
///
/// Deliberately narrow. Everything not listed here keeps rendering as the
/// emoji it always was, which matters where the emoji is content rather than
/// chrome — a grid of achievements tinted `✨🌿💎🥘` would look half-migrated
/// if only some of them resolved to line icons. Widen it by adding an entry
/// and its aliases; no call site changes.
const Map<String, IslamicGlyphEntry> islamicGlyphCatalog = {
  'mosque': _mosque,
  '🕌': _mosque,

  'crescent': _crescent,
  'moon': _crescent,
  '🌙': _crescent,

  'fajr': _dawn,
  'dawn': _dawn,
  'sunrise': _dawn,
  '🌅': _dawn,

  'dhuhr': _midday,
  'midday': _midday,
  '🌤': _midday,
  '☀️': _midday,

  'asr': _afternoon,
  'afternoon': _afternoon,
  '🌇': _afternoon,

  'maghrib': _sunset,
  'sunset': _sunset,
  '🌆': _sunset,

  'isha': _night,
  'night': _night,
  '🌃': _night,

  'prayer': _prayer,
  'praying': _prayer,

  'dua': _dua,
  'supplication': _dua,
  '🤲': _dua,

  'beads': _beads,
  'tasbih': _beads,
  '📿': _beads,

  'book': _book,
  'quran-open': _book,
  '📖': _book,

  'books': _books,
  'library': _books,
  '📚': _books,

  'kaaba': _kaaba,
  '🕋': _kaaba,

  'compass': _compass,
  'qibla': _compass,
  '🧭': _compass,

  'lantern': _lantern,
  'fanous': _lantern,
  '🏮': _lantern,

  'rub-el-hizb': _rubElHizb,
  '۞': _rubElHizb,
};

/// Kinds inferred from an asset path, for icons used in exactly one place
/// without an entry of their own: `IslamicGlyph('assets/lottie/x.lottie')`.
const Map<String, IslamicGlyphKind> _pathKinds = {
  '.svg': IslamicGlyphKind.svg,
  '.png': IslamicGlyphKind.png,
  '.jpg': IslamicGlyphKind.png,
  '.jpeg': IslamicGlyphKind.png,
  '.webp': IslamicGlyphKind.png,
  '.lottie': IslamicGlyphKind.lottie,
  '.json': IslamicGlyphKind.lottie,
};

/// Turns whatever a call site holds into a source, or `null` when the string
/// is an ordinary emoji (or any text at all) and should draw as one.
IslamicGlyphEntry? resolveIslamicGlyph(String glyph) {
  final known = islamicGlyphCatalog[glyph];
  if (known != null) return known;

  if (!glyph.contains('/')) return null;
  final dot = glyph.lastIndexOf('.');
  if (dot < 0) return null;
  final kind = _pathKinds[glyph.substring(dot).toLowerCase()];
  if (kind == null) return null;
  return IslamicGlyphEntry(
    IslamicGlyphSource._(
      kind: kind,
      emoji: '',
      icon: null,
      asset: glyph,
      tintable: kind == IslamicGlyphKind.svg,
      repeat: true,
    ),
  );
}
