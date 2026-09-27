// IslamicGlyph renders emoji the way Muslim Pro does: as the platform colour
// emoji, with an optional smaller emoji stacked on top for composite icons.
// Two behaviours matter: every string keeps rendering (they arrive from
// persisted model fields — Dua.emoji, achievement definitions, book covers —
// including flags, time-of-day and other pictograms), and a badge stacks a
// proportionally smaller emoji in the requested corner.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  testWidgets('a plain emoji renders as colour emoji text', (tester) async {
    await tester.pumpWidget(_wrap(const IslamicGlyph('🕌', size: 24)));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, '🕌');
    expect(text.style?.fontSize, 24);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('unmatched and emoji-only strings keep rendering as text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const Column(
        children: [IslamicGlyph('🌅'), IslamicGlyph('⭐'), IslamicGlyph('🇲')],
      )),
    );
    expect(find.byType(Text), findsNWidgets(3));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('a badge stacks a smaller emoji in the given corner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const IslamicGlyph(
        '🕌',
        size: 28,
        badge: ('📍', AlignmentDirectional.topStart),
      )),
    );
    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(texts.map((t) => t.data), ['🕌', '📍']);
    expect(texts[0].style?.fontSize, 28);
    expect(texts[1].style?.fontSize, closeTo(28 * 1.35 * 0.42, 0.001));
    final align = tester.widget<Align>(find.byType(Align));
    expect(align.alignment, AlignmentDirectional.topStart);
  });
}
