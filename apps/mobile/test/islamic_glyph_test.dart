// IslamicGlyph is the single place an emoji used as interface chrome becomes a
// real icon glyph. Two behaviours matter: only the unambiguous emoji map to
// flutter_islamic_icons (everything else must keep rendering as text, because
// the strings arrive from persisted model fields — Dua.emoji, achievement
// definitions, book covers), and the colour must come from the ambient text
// style, which Icon does not do on its own.

import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';

Widget _wrap(Widget child, {Color? color}) => MaterialApp(
  home: Directionality(
    textDirection: TextDirection.ltr,
    child: DefaultTextStyle(
      style: TextStyle(color: color ?? const Color(0xFF112233)),
      child: child,
    ),
  ),
);

void main() {
  testWidgets('a matched emoji renders its Islamic icon', (tester) async {
    await tester.pumpWidget(_wrap(const IslamicGlyph('🕌', size: 24)));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, FlutterIslamicIcons.mosque);
    expect(icon.size, 24);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('unmatched emoji and emoji-only strings fall back to text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const Column(
        children: [IslamicGlyph('🌅'), IslamicGlyph('⭐'), IslamicGlyph('🇲🇦')],
      )),
    );
    expect(find.byType(Text), findsNWidgets(3));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('an explicit colour wins over the inherited one', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const IslamicGlyph('📖', size: 18),
        color: const Color(0xFFEEDDCC),
      ),
    );
    expect(tester.widget<Icon>(find.byType(Icon)).color, const Color(0xFFEEDDCC));
  });

  testWidgets('resolve() is usable without a context', (tester) async {
    expect(IslamicGlyph.resolve('🤲'), FlutterIslamicIcons.prayingPerson);
    expect(IslamicGlyph.resolve('💧'), isNull);
  });
}
