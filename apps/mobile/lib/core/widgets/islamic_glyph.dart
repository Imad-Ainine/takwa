import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

/// Renders an emoji used as interface chrome as a real icon glyph when
/// [FlutterIslamicIcons] has an unambiguous match, and as plain text otherwise.
///
/// The incoming string is often a persisted model field (`Dua.emoji`,
/// `AchievementDefinition.emoji`, …), so this stays a resolver rather than a
/// call-site rewrite: data keeps rendering, only the presentation upgrades.
class IslamicGlyph extends StatelessWidget {
  const IslamicGlyph(this.glyph, {super.key, this.size, this.color});

  final String glyph;
  final double? size;
  final Color? color;

  /// Emoji whose meaning is stable everywhere in the app. Time-of-day, flag and
  /// generic pictograms are deliberately absent — they have no correct match.
  static const Map<String, IconData> _icons = {
    '🕌': FlutterIslamicIcons.mosque,
    '🕋': FlutterIslamicIcons.kaaba,
    '📖': FlutterIslamicIcons.quran,
    '📿': FlutterIslamicIcons.tasbih,
    '🤲': FlutterIslamicIcons.prayingPerson,
    '🌙': FlutterIslamicIcons.crescentMoon,
    '🧭': FlutterIslamicIcons.qibla,
    '📅': FlutterIslamicIcons.calendar,
  };

  static IconData? resolve(String glyph) => _icons[glyph];

  @override
  Widget build(BuildContext context) {
    final icon = _icons[glyph];
    if (icon == null) {
      return Text(
        glyph,
        style: TextStyle(fontSize: size, color: color),
      );
    }
    // Unlike Text, Icon ignores the ambient text color and falls back to
    // ThemeData.iconTheme, so resolve it here to keep previous ink on screen.
    final effectiveColor =
        color ??
        DefaultTextStyle.of(context).style.color ??
        IconTheme.of(context).color;
    return Icon(icon, size: size, color: effectiveColor);
  }
}
