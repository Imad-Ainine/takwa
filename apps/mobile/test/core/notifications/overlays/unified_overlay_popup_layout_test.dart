// The adhkar/dua popup used to expose a 240 px scroll window inside a card
// that had no bottom bound, and the overlay window itself was draggable — on
// Android that swallowed every vertical gesture, so a long dhikr could not be
// read. One popup per test file: flutter_overlay_window's message stream is a
// single-subscription static, so a second mounted popup in the same process
// would fail to listen rather than tell us anything about the layout.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:takwa/core/notifications/overlays/unified_overlay_window.dart';
import 'package:takwa/l10n/app_localizations.dart';

const _logicalWidth = 400.0;
const _surfaceHeight = 800.0;

/// The popup's own scroll view is the outermost one in the tree.
ScrollPosition _popupPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

Future<void> _nextItem(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.refresh_rounded));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  testWidgets('a long adhkar fills the card, scrolls, and stays on screen', (
    tester,
  ) async {
    final closes = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('x-slayer/overlay_channel'),
      (call) async {
        closes.add(call);
        return null;
      },
    );
    // MediaQuery reads view.physicalSize / devicePixelRatio, so drive the view
    // itself; setSurfaceSize alone only moves the render surface.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(_logicalWidth, _surfaceHeight);
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(
      const Size(_logicalWidth, _surfaceHeight),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UnifiedOverlayWindow(),
      ),
    );
    // The glow pulse repeats forever, so pumpAndSettle would never return.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Cycle through the pool until something is too tall for the card. The
    // items are drawn at random, so the loop is bounded rather than seeded.
    var position = _popupPosition(tester);
    for (var attempt = 0; attempt < 40 && position.maxScrollExtent <= 0; attempt++) {
      await _nextItem(tester);
      position = _popupPosition(tester);
      expect(tester.takeException(), isNull);
      // The copy button is the last row of the card: if it is on screen, so
      // is everything above it.
      expect(
        tester.getRect(find.byIcon(Icons.copy_rounded)).bottom,
        lessThanOrEqualTo(_surfaceHeight),
      );
    }
    expect(
      position.maxScrollExtent,
      greaterThan(0),
      reason: 'no item in the pool was taller than the card',
    );

    // The text area now uses the height the screen offers, not a 240 px box.
    expect(position.viewportDimension, greaterThan(240));

    // Reading it is possible: a vertical drag scrolls.
    expect(position.pixels, 0);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -160));
    await tester.pump();
    expect(position.pixels, greaterThan(0));

    // Scrolling keeps a reader: the idle timeout alone would have closed the
    // popup by now.
    await tester.pump(const Duration(seconds: 20));
    expect(
      closes.where((call) => call.method == 'closeOverlay'),
      isEmpty,
      reason: 'the popup cut a reader off after the idle timeout',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
