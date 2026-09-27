import 'package:flutter/material.dart';

/// Renders an emoji the way Muslim Pro does: as the platform's colour emoji,
/// optionally with a second smaller emoji stacked on top for composite icons
/// (mosque+pin, kaaba+compass, book+beads).
///
/// The incoming string is often a persisted model field (`Dua.emoji`,
/// `AchievementDefinition.emoji`, …), so this stays a resolver rather than
/// a call-site rewrite: data keeps rendering, only the presentation upgrades.
class IslamicGlyph extends StatelessWidget {
  const IslamicGlyph(this.glyph, {super.key, this.size, this.badge});

  final String glyph;
  final double? size;

  /// Smaller emoji stacked on [glyph] for composite icons, paired with the
  /// corner it sits in, e.g. `('📍', AlignmentDirectional.topStart)`.
  final (String, AlignmentGeometry)? badge;

  @override
  Widget build(BuildContext context) {
    final main = Text(glyph, style: TextStyle(fontSize: size));
    if (badge == null) return main;
    final box = (size ?? 24) * 1.35;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        children: [
          Center(child: main),
          Align(
            alignment: badge!.$2,
            child: Text(badge!.$1, style: TextStyle(fontSize: box * 0.42)),
          ),
        ],
      ),
    );
  }
}
